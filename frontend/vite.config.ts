import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      // Convenience alias so imports can use "@/..." for src/
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  server: {
    // Local `npm run dev` outside Docker: proxy API calls to the gateway so the
    // single-origin model still holds during development.
    proxy: {
      "/api": "http://localhost:8080",
      "/auth": "http://localhost:8080",
    },
  },
});
