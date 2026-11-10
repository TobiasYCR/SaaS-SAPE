import { db, ejecutar } from './supabase'
import { textoBusqueda } from '../utils/validaciones'

// Escuela: todos sus alumnos. Empresa: solo los inscriptos en sus convenios (RLS).
// activos: true | false | null (todos)
export function listarAlumnos({ busqueda = '', curso = '', activos = true } = {}) {
  let consulta = db().from('alumnos').select('*, inscripciones(count)').order('apellido').order('nombre')
  const texto = textoBusqueda(busqueda)
  if (texto) consulta = consulta.or(`apellido.ilike.%${texto}%,nombre.ilike.%${texto}%,dni.ilike.%${texto}%`)
  if (curso) consulta = consulta.eq('curso', curso)
  if (activos !== null) consulta = consulta.eq('activo', activos)
  return ejecutar(consulta)
}

export function obtenerAlumno(id) {
  return ejecutar(db().from('alumnos').select('*').eq('id', id).single())
}

export function crearAlumno(alumno) {
  return ejecutar(db().from('alumnos').insert(alumno).select().single())
}

export function actualizarAlumno(id, cambios) {
  return ejecutar(db().from('alumnos').update(cambios).eq('id', id).select().single())
}

// Baja lógica: conserva el historial de inscripciones y seguimientos
export function darDeBajaAlumno(id) {
  return actualizarAlumno(id, { activo: false })
}

export function reactivarAlumno(id) {
  return actualizarAlumno(id, { activo: true })
}

// Borrado físico: solo para alumnos sin inscripciones (cargados por error)
export function eliminarAlumno(id) {
  return ejecutar(db().from('alumnos').delete().eq('id', id))
}
