import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// `npm run dev` forwards /api to a port-forwarded api-gateway on :8080,
// the same path Traefik will route in the cluster.
export default defineConfig({
  plugins: [react()],
  server: { proxy: { "/api": { target: "http://localhost:8080", rewrite: p => p.replace(/^\/api/, "") } } },
});