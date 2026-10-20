import { db, ejecutar } from './supabase'

export function listarSeguimientos(inscripcionId) {
  return ejecutar(db().from('seguimientos')
    .select('*, autor:perfiles(nombre_completo)')
    .eq('inscripcion_id', inscripcionId)
    .order('fecha', { ascending: false }))
}

// Solo sobre inscripciones 'en_curso'. autor_id se completa con el usuario logueado.
export function crearSeguimiento({ inscripcion_id, fecha, progreso, observaciones, proxima_fecha }) {
  return ejecutar(db().from('seguimientos')
    .insert({ inscripcion_id, fecha, progreso, observaciones, proxima_fecha })
    .select().single())
}

export function actualizarSeguimiento(id, cambios) {
  return ejecutar(db().from('seguimientos').update(cambios).eq('id', id).select().single())
}

export function eliminarSeguimiento(id) {
  return ejecutar(db().from('seguimientos').delete().eq('id', id))
}
