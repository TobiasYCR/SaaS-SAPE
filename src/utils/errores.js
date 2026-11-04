// Convierte errores de Supabase/PostgreSQL en mensajes legibles.
// Los triggers de la base ya devuelven mensajes en español: se muestran tal cual.
const POR_CODIGO = {
  23505: 'Ya existe un registro con esos datos.',
  23503: 'El registro está relacionado con otros datos y no se puede completar la operación.',
  23514: 'Algún valor no cumple las reglas permitidas.',
  42501: 'No tenés permiso para realizar esta operación.',
  PGRST116: 'No se encontró el registro o no tenés acceso a él.',
}

const POR_TEXTO = [
  [/row-level security/i, 'No tenés permiso para realizar esta operación.'],
  [/permission denied/i, 'No tenés permiso para realizar esta operación.'],
  [/duplicate key.*cue/i, 'Ya existe una escuela con ese CUE.'],
  [/duplicate key.*cuit/i, 'Ya existe una empresa con ese CUIT.'],
  [/duplicate key.*escuela_id_dni/i, 'Ya hay un alumno con ese DNI en la escuela.'],
  [/duplicate key.*ciclo_lectivo/i, 'Ya te postulaste a esa escuela para ese ciclo lectivo.'],
  [/duplicate key.*convenio_id_alumno_id/i, 'El alumno ya está inscripto en ese convenio.'],
  [/duplicate key.*convenio_id_nombre/i, 'Ya existe un requisito con ese nombre.'],
  [/failed to fetch|network/i, 'No hay conexión con el servidor. Revisá tu conexión e intentá de nuevo.'],
  [/could not find the table|schema cache/i, 'La base de datos no está configurada. Ejecutá supabase/schema.sql.'],
  [/invalid login credentials/i, 'Email o contraseña incorrectos.'],
  [/email not confirmed/i, 'Confirmá tu email antes de iniciar sesión.'],
]

export function traducirError(error) {
  const mensaje = error?.message || String(error || '')
  for (const [patron, texto] of POR_TEXTO) if (patron.test(mensaje)) return texto
  if (error?.code === 'P0001') return mensaje // raise exception de los triggers
  return POR_CODIGO[error?.code] || mensaje || 'Ocurrió un error inesperado.'
}
