from psycopg2.pool import SimpleConnectionPool

_SCHEMA = """
CREATE TABLE IF NOT EXISTS orders (
    order_id        TEXT PRIMARY KEY,
    customer_id     TEXT NOT NULL,
    item            TEXT NOT NULL,
    quantity        INTEGER NOT NULL,
    status          TEXT NOT NULL,
    failure_reason  TEXT,
    created_at      TIMESTAMPTZ NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
"""


class Database:
    def __init__(self, dsn: str):
        self.pool = SimpleConnectionPool(minconn=1, maxconn=10, dsn=dsn)

    def init_schema(self):
        with self.pool.getconn() as conn:
            with conn.cursor() as cur:
                cur.execute(_SCHEMA)
            conn.commit()
            self.pool.putconn(conn)

    def upsert_order(
        self,
        order_id: str,
        customer_id: str,
        item: str,
        quantity: int,
        status: str,
        created_at,
        failure_reason: str | None = None,
    ):
        conn = self.pool.getconn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO orders (order_id, customer_id, item, quantity, status, failure_reason, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, now())
                    ON CONFLICT (order_id) DO UPDATE SET
                        status = EXCLUDED.status,
                        failure_reason = EXCLUDED.failure_reason,
                        updated_at = now()
                    """,
                    (order_id, customer_id, item, quantity, status, failure_reason, created_at),
                )
            conn.commit()
        finally:
            self.pool.putconn(conn)

    
    def get_order(self, order_id: str):
        conn = self.pool.getconn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT order_id, customer_id, item, quantity,
                           status, failure_reason, created_at, updated_at
                    FROM orders
                    WHERE order_id = %s
                    """,
                    (order_id,),
                )
                row = cur.fetchone()

                if row is None:
                    return None

                columns = [desc[0] for desc in cur.description]
                return dict(zip(columns, row))
        finally:
            self.pool.putconn(conn)

    def list_orders(self):
        conn = self.pool.getconn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT order_id, customer_id, item, quantity,
                           status, failure_reason, created_at, updated_at
                    FROM orders
                    ORDER BY created_at DESC
                    """
                )
                rows = cur.fetchall()
                columns = [desc[0] for desc in cur.description]
                return [
                    dict(zip(columns, row))
                    for row in rows
                ]
        finally:
            self.pool.putconn(conn)

    def close(self):
        self.pool.closeall()