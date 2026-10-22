import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { findOrder, getStatus, money } from "../api.js";

export default function OrderStatus() {
  const { id } = useParams();
  const [o] = useState(() => findOrder(id));
  const [s, setS] = useState(null);

  useEffect(() => {
    let stop = false, t;
    const tick = async () => {
      const r = await getStatus(o);
      if (stop) return;
      setS(r);
      if (r.status === "completed" || r.status === "failed") clearInterval(t);
    };
    tick(); t = setInterval(tick, 2000);
    return () => { stop = true; clearInterval(t); };
  }, [o]);

  const st = s?.status || "pending", final = st === "completed" || st === "failed";
  const steps = [
    ["Order received", "The gateway accepted the order and queued it.", true],
    ["Processing", "The worker is checking and saving the order.", st !== "pending"],
    [st === "failed" ? "Order failed" : "Order completed", st === "failed" ? s?.reason || "Processing failed." : "The order was saved.", final],
    ["Customer notified", "The completion event reached the notifier.", final],
  ];
  const now = steps.findIndex(x => !x[2]);

  return (
    <>
      <p><Link className="back" to="/">Back to catalog</Link></p>
      <div className="grid">
        <section className="card"><h2>Order {id.slice(0, 8)}</h2><div className="body">
          <strong>{o.item}</strong>
          <div className="sum"><span>Units</span><b>{o.qty || "–"}</b></div>
          {o.price != null && <div className="sum"><span>Unit price</span><b>{money(o.price)}</b></div>}
          {o.total != null && <div className="sum"><span>Total</span><b>{money(o.total)}</b></div>}
          <div className="sum"><span>Customer</span><b>{o.customer || "–"}</b></div>
        </div></section>
        <section className="card"><h2>Status</h2>
          {s?.sim && <span className="tag">Simulated status until the order read endpoint exists</span>}
          <div className="body"><ol className="tl">
            {steps.map((x, i) => {
              const c = x[2] ? (st === "failed" && i === 2 ? "fail" : "done") : i === now ? "now" : "";
              return <li key={i} className={c}><span className="dot">{x[2] ? (c === "fail" ? "!" : "✓") : ""}</span><strong>{x[0]}</strong><span>{x[1]}</span></li>;
            })}
          </ol></div>
        </section>
      </div>
    </>
  );
}