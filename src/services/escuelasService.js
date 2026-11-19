import { db, ejecutar } from './supabase'
import { textoBusqueda } from '../utils/validaciones'

// Directorio: visible para todos los usuarios autenticados
export function listarEscuelas({ busqueda = '', provincia = '' } = {}) {
  let consulta = db().from('escuelas').select('*').eq('activa', true).order('nombre')
  const texto = textoBusqueda(busqueda)
  if (texto) consulta = consulta.or(`nombre.ilike.%${texto}%,localidad.ilike.%${texto}%,modalidad.ilike.%${texto}%`)
  if (provincia) consulta = consulta.eq('provincia', provincia)
  return ejecutar(consulta)
}

export function obtenerEscuela(id) {
  return ejecutar(db().from('escuelas').select('*').eq('id', id).single())
}

// Solo el escuela_admin de esa escuela (RLS)
export function actualizarEscuela(id, datos) {
  return ejecutar(db().from('escuelas')
    .update(datos)
    .eq('id', id).select().single())
}
