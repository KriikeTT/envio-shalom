// Ejecutar en https://pro.shalom.pe/registroindividual con la sesión iniciada.
// Devuelve un JSON con las agencias Shalom habilitadas como destino
// (mismo filtro que usa Shalom Pro: destino = 1 y ter_habilitado_OS = 1).
// Formato de cada fila: [departamento, provincia, distrito, nombre, dirección, horario]
(async () => {
  const r = await axios.post('/envia_ya/terminals');
  const limpio = s => String(s || '').replace(/\s+/g, ' ').trim();
  const filas = r.data.Map
    .filter(t => +t.destino === 1 && +t.ter_habilitado_OS === 1)
    .map(t => [
      limpio(t.departamento),
      limpio(t.provincia),
      limpio(t.zona),
      limpio(t.lugar_over).toUpperCase(),
      limpio(t.direccion),
      limpio(t.hora_atencion),
    ]);
  return JSON.stringify(filas);
})()
