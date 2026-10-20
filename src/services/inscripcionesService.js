import { db, ejecutar } from './supabase'

const SELECT_INSCRIPCION = '*, alumno:alumnos(id, nombre, apellido, dni, curso, division), convenio:convenios(id, area, empresa:empresas(razon_social), escuela:escuelas(nombre))'

export function listarInscripciones({ convenioId = '', estado = '' } = {}) {
  let consulta = db().from('inscripciones').select(SELECT_INSCRIPCION).order('creado_en', { ascending: false })
  if (convenioId) consulta = consulta.eq('convenio_id', convenioId)
  if (estado) consulta = consulta.eq('estado', estado)
  return ejecutar(consulta)
}

export function obtenerInscripcion(id) {
  return ejecutar(db().from('inscripciones')
    .select(`${SELECT_INSCRIPCION}, datos:datos_inscripcion(*), seguimientos(*)`)
    .eq('id', id).single())
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

export function actualizarInscripcion(id, { fecha_inicio, fecha_fin, horas_totales, tutor_escuela_id, tutor_empresa_id, observaciones }) {
  return ejecutar(db().from('inscripciones')
    .update({ fecha_inicio, fecha_fin, horas_totales, tutor_escuela_id, tutor_empresa_id, observaciones })
    .eq('id', id).select().single())
}

// Carga o reemplaza el valor de un requisito (solo en 'borrador')
export function guardarDato(inscripcionId, requisitoId, { valor = null, archivo_ruta = null }) {
  return ejecutar(db().from('datos_inscripcion')
    .upsert({ inscripcion_id: inscripcionId, requisito_id: requisitoId, valor, archivo_ruta },
      { onConflict: 'inscripcion_id,requisito_id' })
    .select().single())
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
