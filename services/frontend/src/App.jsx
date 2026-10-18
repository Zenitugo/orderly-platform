import { Link, NavLink, Route, Routes } from "react-router-dom";
import Catalog from "./pages/Catalog.jsx";
import AddProduct from "./pages/AddProduct.jsx";
import OrderStatus from "./pages/OrderStatus.jsx";

export default function App() {
  return (
    <>
      <header>
        <Link className="brand" to="/">Orderly</Link>
        <nav><NavLink to="/" end>Catalog</NavLink><NavLink to="/products/new">Add product</NavLink></nav>
      </header>
      <main>
        <Routes>
          <Route path="/" element={<Catalog />} />
          <Route path="/products/new" element={<AddProduct />} />
          <Route path="/orders/:id" element={<OrderStatus />} />
          <Route path="*" element={<p className="empty">Page not found. <Link to="/">Back to the catalog</Link></p>} />
        </Routes>
      </main>
    </>
  );
}