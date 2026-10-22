// All network and storage access lives here, so pages never call fetch directly.
// Each call uses the real API when it exists and falls back to this browser otherwise.
export const SEED = [
  ["Standard widget", "Components", "WG-0001", 12], ["Steel bracket", "Hardware", "BR-0042", 8],
  ["Control board", "Electronics", "CB-0310", 45], ["Cable bundle", "Electronics", "CA-0107", 15],
  ["Aluminium panel", "Hardware", "AP-0220", 30], ["Rubber gasket", "Components", "RG-0033", 3],
  ["Sensor module", "Electronics", "SM-0504", 22], ["Mounting kit", "Hardware", "MK-0071", 18],
  ["LED strip", "Electronics", "LS-0612", 14], ["Power adapter", "Electronics", "PA-0150", 20],
].map(([name, category, ref, price]) => ({ id: ref.toLowerCase(), name, category, ref, price }));

const read = (k, d) => { try { return JSON.parse(localStorage.getItem(k)) ?? d; } catch { return d; } };
const write = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch { /* storage unavailable */ } };
const json = { "Content-Type": "application/json" };

export const money = n => "$" + Number(n).toFixed(2);
export async function getProducts() {
  try { const r = await fetch("/api/products"); if (r.ok) return { items: await r.json(), live: true }; } catch { /* use fallback */ }
  return { items: [...SEED, ...read("products", [])], live: false };
}

export async function addProduct(p) {
  try { const r = await fetch("/api/products", { method: "POST", headers: json, body: JSON.stringify(p) }); if (r.ok) return { live: true }; } catch { /* use fallback */ }
  write("products", [...read("products", []), { ...p, id: Date.now().toString(36) }]);
  return { live: false };
}

export async function createOrder(body) {
  const r = await fetch("/api/orders", { method: "POST", headers: json, body: JSON.stringify(body) });
  const d = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(d.error || "The order could not be placed. Try again.");
  return d.order_id;
}

export const recentOrders = () => read("orders", []);
export const saveOrder = o => write("orders", [o, ...recentOrders()].slice(0, 15));
export const findOrder = id => recentOrders().find(o => o.id === id) || { id, item: "Order", qty: "", customer: "", at: Date.now() };

// Real status when GET /api/orders/{id} returns 200; otherwise a labelled simulation.
export async function getStatus(o) {
  try {
    const r = await fetch("/api/orders/" + encodeURIComponent(o.id));
    if (r.ok) { const d = await r.json(); return { status: d.status, reason: d.failure_reason, sim: false }; }
  } catch { /* use simulation */ }
  const s = (Date.now() - o.at) / 1000, fails = o.id.charCodeAt(0) % 10 === 0;
  return { status: s < 2 ? "pending" : s < 5 ? "processing" : fails ? "failed" : "completed", reason: "Simulated downstream failure", sim: true };
}