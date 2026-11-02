import { db, ejecutar } from './supabase'

const SELECT_CONVENIO = '*, empresa:empresas(id, razon_social, nombre_fantasia, datos_prueba), escuela:escuelas(id, nombre, localidad, datos_prueba), inscripciones(count)'

// Devuelve solo los convenios donde la organización del usuario es parte (RLS)
export function listarConvenios({ estado = '', ciclo = '' } = {}) {
  let consulta = db().from('convenios').select(SELECT_CONVENIO).order('creado_en', { ascending: false })
  if (estado) consulta = consulta.eq('estado', estado)
  if (ciclo) consulta = consulta.eq('ciclo_lectivo', ciclo)
  return ejecutar(consulta)
}

export function obtenerConvenio(id) {
  return ejecutar(db().from('convenios').select(SELECT_CONVENIO).eq('id', id).single())
}

// Empresa elige una escuela y se postula. Queda en estado 'postulado'.
export function postularse({ empresa_id, escuela_id, ciclo_lectivo, cupos, area, descripcion, fecha_inicio, fecha_fin }) {
  return ejecutar(db().from('convenios')
    .insert({ empresa_id, escuela_id, ciclo_lectivo, cupos, area, descripcion, fecha_inicio, fecha_fin })
    .select().single())
}

// Propuesta: solo la empresa, mientras el convenio está postulado o aceptado (trigger)
export function actualizarPropuesta(id, { area, descripcion, cupos, fecha_inicio, fecha_fin }) {
  return ejecutar(db().from('convenios').update({ area, descripcion, cupos, fecha_inicio, fecha_fin }).eq('id', id).select().single())
}

// Transiciones válidas (las controla la base):
// escuela: postulado → aceptado | rechazado
// empresa: postulado → cancelado
// ambas:   aceptado → activo, aceptado|activo → finalizado | cancelado
export function cambiarEstadoConvenio(id, estado) {
  return ejecutar(db().from('convenios').update({ estado }).eq('id', id).select().single())
}

export function retirarPostulacion(id) {
  return ejecutar(db().from('convenios').delete().eq('id', id))
}

// Requisitos: solo con el convenio en estado 'aceptado'
export function listarRequisitos(convenioId) {
  return ejecutar(db().from('requisitos').select('*').eq('convenio_id', convenioId).order('orden').order('creado_en'))
}

export function crearRequisito({ convenio_id, nombre, descripcion, tipo, obligatorio, orden }) {
  return ejecutar(db().from('requisitos').insert({ convenio_id, nombre, descripcion, tipo, obligatorio, orden }).select().single())
}

export function actualizarRequisito(id, { nombre, descripcion, tipo, obligatorio, orden }) {
  return ejecutar(db().from('requisitos').update({ nombre, descripcion, tipo, obligatorio, orden }).eq('id', id).select().single())
}

export function eliminarRequisito(id) {
  return ejecutar(db().from('requisitos').delete().eq('id', id))
}
