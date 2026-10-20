import { db, ejecutar } from './supabase'

// Escuela: todos sus alumnos. Empresa: solo los inscriptos en sus convenios (RLS).
export function listarAlumnos({ busqueda = '', curso = null } = {}) {
  let consulta = db().from('alumnos').select('*').order('apellido').order('nombre')
  if (busqueda) consulta = consulta.or(`apellido.ilike.%${busqueda}%,nombre.ilike.%${busqueda}%,dni.ilike.%${busqueda}%`)
  if (curso) consulta = consulta.eq('curso', curso)
  return ejecutar(consulta)
}

export function crearAlumno(alumno) {
  return ejecutar(db().from('alumnos').insert(alumno).select().single())
}

export function actualizarAlumno(id, cambios) {
  return ejecutar(db().from('alumnos').update(cambios).eq('id', id).select().single())
}

export function eliminarAlumno(id) {
  return ejecutar(db().from('alumnos').delete().eq('id', id))
}
