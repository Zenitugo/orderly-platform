import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { createOrder, getProducts, money, recentOrders, saveOrder } from "../api.js";

export default function Catalog() {
  const nav = useNavigate();
  const [{ items, live }, setData] = useState({ items: [], live: true });
  const [qty, setQty] = useState({});
  const [customer, setCustomer] = useState(() => localStorage.getItem("customer") || "cust-001");
  const [busy, setBusy] = useState("");
  const [err, setErr] = useState("");
  useEffect(() => { getProducts().then(setData); }, []);

  async function order(p) {
    //const n = Number(qty[p.id] || 1);
    const n = Math.max(1, Math.floor(Number(qty[p.id]) || 1));
    setErr(""); setBusy(p.id);
    try {
      const id = await createOrder({ customer_id: customer.trim(), item: p.name, quantity: n });
      saveOrder({ id, item: p.name, qty: n, price: p.price, total: p.price * n, customer: customer.trim(), at: Date.now() });
      //saveOrder({ id, item: p.name, qty: n, customer: customer.trim(), at: Date.now() });
      nav("/orders/" + id);
    } catch (e) { setErr(e.message); setBusy(""); }
  }

  return (
    <>
      <h1>New order</h1>
      <div className="grid">
        <section className="card">
          <h2>Select product</h2>
          <div className="body">
            <label htmlFor="cust">Customer ID</label>
            <input id="cust" value={customer} onChange={e => { setCustomer(e.target.value); localStorage.setItem("customer", e.target.value); }} />
            <p className="err" role="alert">{err}</p>
            <div className="products">
              {items.map(p => (
                <article className="product" key={p.id}>
                  <strong>{p.name}</strong>
                  <small>{p.category}, {p.ref}</small>
                  <span className="price">${Number(p.price).toFixed(2)}</span>
                  <span className="price">Total {money(p.price * (Number(qty[p.id]) || 1))}</span>
                  <div className="buy">
                    <input type="number" min="1" aria-label={"Units of " + p.name} value={qty[p.id] || 1} onChange={e => setQty({ ...qty, [p.id]: e.target.value })} />
                    <button className="btn" disabled={busy === p.id} onClick={() => order(p)}>Place order</button>
                  </div>
                </article>
              ))}
            </div>
            {!live && <p className="note">Showing the built-in catalog plus products saved in this browser. Shared products need a products API.</p>}
          </div>
        </section>
        <section className="card">
          <h2>Recent orders</h2>
          <div className="list">
            {recentOrders().length === 0 && <p className="empty">No orders yet. Place one and it will appear here.</p>}
            {recentOrders().map(o => <Link key={o.id} to={"/orders/" + o.id}>{o.item} × {o.qty}{o.total != null && `, ${money(o.total)}`}<small>{o.id.slice(0, 8)}, {o.customer}</small></Link>)}
          </div>
        </section>
      </div>
    </>
  );
}