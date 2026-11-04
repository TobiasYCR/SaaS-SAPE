import { db, ejecutar } from './supabase'

const SELECT_INSCRIPCION = '*, alumno:alumnos(id, nombre, apellido, dni, curso, division, especialidad), convenio:convenios(id, area, estado, cupos, empresa:empresas(id, razon_social, nombre_fantasia, datos_prueba), escuela:escuelas(id, nombre, datos_prueba))'

export function listarInscripciones({ convenioId = '', estado = '' } = {}) {
  let consulta = db().from('inscripciones').select(SELECT_INSCRIPCION).order('actualizado_en', { ascending: false })
  if (convenioId) consulta = consulta.eq('convenio_id', convenioId)
  if (estado) consulta = Array.isArray(estado) ? consulta.in('estado', estado) : consulta.eq('estado', estado)
  return ejecutar(consulta)
}

export function obtenerInscripcion(id) {
  return ejecutar(db().from('inscripciones').select(SELECT_INSCRIPCION).eq('id', id).single())
}

// Escuela inscribe un alumno en un convenio activo. Queda en 'borrador'.
export function inscribirAlumno(convenioId, alumnoId) {
  return ejecutar(db().from('inscripciones').insert({ convenio_id: convenioId, alumno_id: alumnoId }).select().single())
}

// Transiciones válidas (las controla la base):
// escuela: borrador → enviada (requisitos obligatorios completos), → cancelada
// empresa: enviada → aceptada (con cupo) | rechazada
// ambas:   aceptada → en_curso → finalizada
export function cambiarEstadoInscripcion(id, estado) {
  return ejecutar(db().from('inscripciones').update({ estado }).eq('id', id).select().single())
}

export function actualizarInscripcion(id, { fecha_inicio, fecha_fin, horas_totales, observaciones }) {
  return ejecutar(db().from('inscripciones')
    .update({ fecha_inicio, fecha_fin, horas_totales, observaciones })
    .eq('id', id).select().single())
}

// Borrado físico: solo borradores (RLS). Para el resto se usa el estado 'cancelada'.
export function eliminarInscripcion(id) {
  return ejecutar(db().from('inscripciones').delete().eq('id', id))
}

export function listarDatos(inscripcionId) {
  return ejecutar(db().from('datos_inscripcion').select('*').eq('inscripcion_id', inscripcionId))
}

// Carga o reemplaza el valor de un requisito (solo en 'borrador')
export function guardarDato(inscripcionId, requisitoId, { valor = null, archivo_ruta = null }) {
  return ejecutar(db().from('datos_inscripcion')
    .upsert({ inscripcion_id: inscripcionId, requisito_id: requisitoId, valor, archivo_ruta },
      { onConflict: 'inscripcion_id,requisito_id' })
    .select().single())
}

export function borrarDato(inscripcionId, requisitoId) {
  return ejecutar(db().from('datos_inscripcion').delete().eq('inscripcion_id', inscripcionId).eq('requisito_id', requisitoId))
}

// Archivo de un requisito: documentos/{convenio}/{inscripcion}/{uuid}.ext
export async function subirDocumento(convenioId, inscripcionId, archivo) {
  const extension = archivo.name.split('.').pop().toLowerCase()
  const ruta = `${convenioId}/${inscripcionId}/${crypto.randomUUID()}.${extension}`
  await ejecutar(db().storage.from('documentos').upload(ruta, archivo, { upsert: false }))
  return ruta
}

export async function urlDocumento(ruta, segundos = 300) {
  const data = await ejecutar(db().storage.from('documentos').createSignedUrl(ruta, segundos))
  return data.signedUrl
}
