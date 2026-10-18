import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { addProduct } from "../api.js";

export default function AddProduct() {
  const nav = useNavigate();
  const [f, setF] = useState({ name: "", category: "", price: "" });
  const [err, setErr] = useState("");
  const set = k => e => setF({ ...f, [k]: e.target.value });

  async function submit(e) {
    e.preventDefault();
    if (!f.name.trim() || !f.category.trim() || !(Number(f.price) > 0)) { setErr("Enter a name, a category and a price above zero."); return; }
    const ref = f.name.trim().slice(0, 2).toUpperCase() + "-" + String(Date.now()).slice(-4);
    await addProduct({ name: f.name.trim(), category: f.category.trim(), price: Number(f.price), ref });
    nav("/");
  }

  return (
    <>
      <h1>Add product</h1>
      <section className="card narrow"><div className="body">
        <form onSubmit={submit}>
          <label htmlFor="n">Product name</label><input id="n" value={f.name} onChange={set("name")} />
          <div className="row">
            <div><label htmlFor="c">Category</label><input id="c" value={f.category} onChange={set("category")} /></div>
            <div><label htmlFor="p">Price per unit (USD)</label><input id="p" type="number" min="0" step="0.01" value={f.price} onChange={set("price")} /></div>
          </div>
          <p className="err" role="alert">{err}</p>
          <div className="actions"><button className="btn">Add product</button></div>
        </form>
      </div></section>
    </>
  );
}