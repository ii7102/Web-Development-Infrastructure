import { useEffect, useState } from "react";

// Minimal skeleton page, styled with plain Tailwind. It proves the full
// single-origin path works:
//   - the gateway serves this SPA at "/"
//   - window.__ENV__ comes from the runtime-injected /config.js
//   - the gateway forwards "/api/" to the backend
// Build your real app on top of this (e.g. port in your Stitch design). Delete
// what you don't need.
export default function App() {
  const env = window.__ENV__ ?? {};
  const [ping, setPing] = useState<string>("checking...");

  useEffect(() => {
    fetch("/api/ping")
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((data) => setPing(JSON.stringify(data)))
      .catch((err) => setPing(`unreachable (${err})`));
  }, []);

  return (
    <main className="mx-auto max-w-2xl px-4 py-12">
      <h1 className="text-3xl font-bold tracking-tight">
        Starter template is running
      </h1>
      <p className="mt-2 text-gray-500">
        This is the placeholder SPA (Tailwind v4 is set up). Replace it with your
        application.
      </p>

      <section className="mt-8">
        <h2 className="text-lg font-semibold">Runtime config (window.__ENV__)</h2>
        <pre className="mt-2 overflow-x-auto rounded-lg bg-gray-100 p-4 text-sm">
          {JSON.stringify(env, null, 2)}
        </pre>
      </section>

      <section className="mt-8">
        <h2 className="text-lg font-semibold">Backend (/api/ping)</h2>
        <pre className="mt-2 overflow-x-auto rounded-lg bg-gray-100 p-4 text-sm">
          {ping}
        </pre>
      </section>
    </main>
  );
}
