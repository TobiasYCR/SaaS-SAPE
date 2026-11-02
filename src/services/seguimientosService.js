import { db, ejecutar } from './supabase'

// Seguimientos de una pasantía, del más reciente al más antiguo
export function listarSeguimientos(inscripcionId) {
  return ejecutar(db().from('seguimientos')
    .select('*, autor:perfiles(nombre_completo)')
    .eq('inscripcion_id', inscripcionId)
    .order('fecha', { ascending: false })
    .order('creado_en', { ascending: false }))
}

// Todas las pasantías visibles con sus seguimientos (para el panel de seguimiento)
export function listarPasantiasConSeguimientos(estados = ['en_curso', 'finalizada']) {
  return ejecutar(db().from('inscripciones')
    .select('id, estado, fecha_inicio, fecha_fin, alumno:alumnos(nombre, apellido), convenio:convenios(area, empresa:empresas(razon_social, nombre_fantasia), escuela:escuelas(nombre)), seguimientos(id, fecha, progreso, proxima_fecha)')
    .in('estado', estados)
    .order('actualizado_en', { ascending: false }))
}

// Solo sobre inscripciones 'en_curso'. autor_id se completa con el usuario logueado.
export function crearSeguimiento({ inscripcion_id, fecha, progreso, observaciones, proxima_fecha }) {
  return ejecutar(db().from('seguimientos')
    .insert({ inscripcion_id, fecha, progreso, observaciones, proxima_fecha })
    .select().single())
}

export function actualizarSeguimiento(id, { fecha, progreso, observaciones, proxima_fecha }) {
  return ejecutar(db().from('seguimientos').update({ fecha, progreso, observaciones, proxima_fecha }).eq('id', id).select().single())
}

export function eliminarSeguimiento(id) {
  return ejecutar(db().from('seguimientos').delete().eq('id', id))
}
