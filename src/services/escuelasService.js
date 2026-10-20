import { db, ejecutar } from './supabase'

// Directorio: visible para todos los usuarios autenticados
export function listarEscuelas({ busqueda = '', provincia = '' } = {}) {
  let consulta = db().from('escuelas').select('*').eq('activa', true).order('nombre')
  if (busqueda) consulta = consulta.or(`nombre.ilike.%${busqueda}%,localidad.ilike.%${busqueda}%`)
  if (provincia) consulta = consulta.eq('provincia', provincia)
  return ejecutar(consulta)
}

export function obtenerEscuela(id) {
  return ejecutar(db().from('escuelas').select('*').eq('id', id).single())
}

// Solo el escuela_admin de esa escuela (RLS)
export function actualizarEscuela(id, cambios) {
  return ejecutar(db().from('escuelas').update(cambios).eq('id', id).select().single())
}
