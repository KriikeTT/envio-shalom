// Intermediario para consultar DNI en Decolecta sin exponer el token.
// Se publica como Cloudflare Worker (plan gratis).
//
// Configuración en Cloudflare (Worker > Settings > Variables and Secrets):
//   DECOLECTA_TOKEN  (tipo Secret)  -> tu token de Decolecta (sk_...)
//   ORIGENES         (tipo Text)    -> dominios que pueden usarlo, separados por coma.
//                                     Ej: https://luxury-shalom.netlify.app
//                                     Déjalo vacío solo mientras pruebas (acepta cualquiera).
//
// Uso desde el formulario:  GET https://<tu-worker>.workers.dev/?dni=12345678
// Respuesta: { "ok": true, "nombre": "JUAN CARLOS PEREZ GARCIA" }  o  { "ok": false, "error": "..." }

export default {
  async fetch(request, env) {
    const origin = request.headers.get("Origin") || "";
    const permitidos = (env.ORIGENES || "").split(",").map(s => s.trim()).filter(Boolean);
    const origenOk = permitidos.length === 0 || permitidos.includes(origin);

    const cors = {
      "Access-Control-Allow-Origin": origenOk ? (origin || "*") : "null",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
      "Vary": "Origin",
    };
    const json = (body, status = 200) =>
      new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json; charset=utf-8" } });

    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
    if (request.method !== "GET") return json({ ok: false, error: "metodo" }, 405);
    if (!origenOk) return json({ ok: false, error: "origen no permitido" }, 403);

    const dni = new URL(request.url).searchParams.get("dni") || "";
    if (!/^\d{8}$/.test(dni)) return json({ ok: false, error: "dni invalido" }, 400);
    if (!env.DECOLECTA_TOKEN) return json({ ok: false, error: "falta token" }, 500);

    const r = await fetch("https://api.decolecta.com/v1/reniec/dni?numero=" + dni, {
      headers: { Authorization: "Bearer " + env.DECOLECTA_TOKEN, Accept: "application/json" },
    });
    if (r.status === 400 || r.status === 404 || r.status === 422) return json({ ok: false, error: "no encontrado" }, 404);
    if (!r.ok) return json({ ok: false, error: "servicio " + r.status }, 502);

    const d = await r.json();
    const nombre = [d.first_name, d.first_last_name, d.second_last_name].filter(Boolean).join(" ").trim()
      || d.full_name || "";
    if (!nombre) return json({ ok: false, error: "no encontrado" }, 404);
    // Solo se devuelve el nombre (no otros datos personales)
    return json({ ok: true, nombre });
  },
};
