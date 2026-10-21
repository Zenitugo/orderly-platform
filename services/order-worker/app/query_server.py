
import json
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse


def start_query_server(db, port=8080):
    class QueryHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            path = urlparse(self.path).path.strip("/")
            parts = path.split("/")

            try:
                if path == "orders":
                    # Retrieve all orders
                    orders = db.list_orders()
                    result = [self.serialize_order(order) for order in orders]

                elif len(parts) == 2 and parts[0] == "orders" and parts[1]:
                    # Retrieve one order by ID
                    order = db.get_order(parts[1])

                    if order is None:
                        self.send_json(404, {"message": "Order not found"})
                        return

                    result = self.serialize_order(order)

                else:
                    self.send_json(404, {"message": "Not found"})
                    return

                self.send_json(200, result)

            except Exception:
                self.send_json(500, {"message": "Failed to retrieve orders"})

        def serialize_order(self, order):
            return {
                key: value.isoformat() if isinstance(value, datetime) else value
                for key, value in order.items()
            }

        def send_json(self, status, data):
            body = json.dumps(data).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, format, *args):
            return

    server = ThreadingHTTPServer(("0.0.0.0", port), QueryHandler)
    server.serve_forever()
