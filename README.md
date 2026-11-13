# Formulario de envío Shalom – Luxury Skincars

Formulario que el cliente llena al confirmar el pago: DNI (el nombre se completa solo desde RENIEC),
celular, destino y agencia Shalom. Los datos llegan por WhatsApp al negocio.

- `formulario-envio-shalom.html` – el formulario publicado (generado, no editar a mano).
- `index.html` – redirige al formulario.
- `shalom-form/plantilla.html` – plantilla del formulario (aquí se hacen los cambios de diseño o textos).
- `shalom-form/agencias.json` – agencias Shalom habilitadas como destino (se actualiza a diario).
- `shalom-form/ubigeo.json` – departamentos, provincias y distritos del Perú.
- `shalom-form/actualizar.ps1` – regenera el formulario; con `-Publicar` hace commit y push.
- `shalom-form/extraer-agencias.js` – extrae la lista de agencias desde Shalom Pro (con sesión iniciada).
- `shalom-form/dni-proxy-worker.js` – intermediario en Cloudflare para consultar DNI (el token vive en Cloudflare, no aquí).

Link para clientes (opcional `?pedido=123`): https://envios.luxuryskincars.com

- `CNAME` – dominio propio de GitHub Pages (no borrar).
