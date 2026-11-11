import { db, ejecutar } from './supabase'
import { textoBusqueda } from '../utils/validaciones'

// Opciones de orden del listado: [columna, ascendente], con apellido/nombre como desempate
export const ORDEN_ALUMNOS = {
  apellido: { etiqueta: 'Apellido (A-Z)', columnas: [['apellido', true], ['nombre', true]] },
  apellido_desc: { etiqueta: 'Apellido (Z-A)', columnas: [['apellido', false], ['nombre', false]] },
  dni: { etiqueta: 'DNI', columnas: [['dni', true]] },
  curso: { etiqueta: 'Curso y división', columnas: [['curso', true], ['division', true], ['apellido', true]] },
  recientes: { etiqueta: 'Últimos cargados', columnas: [['creado_en', false]] },
}

// Escuela: todos sus alumnos. Empresa: solo los que tienen una inscripción enviada en sus convenios (RLS).
// activos: true | false | null (todos)
export function listarAlumnos({ busqueda = '', curso = '', activos = true, orden = 'apellido' } = {}) {
  let consulta = db().from('alumnos').select('*, inscripciones(count)')
  for (const [columna, ascending] of (ORDEN_ALUMNOS[orden] || ORDEN_ALUMNOS.apellido).columnas) {
    consulta = consulta.order(columna, { ascending, nullsFirst: false })
  }
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
