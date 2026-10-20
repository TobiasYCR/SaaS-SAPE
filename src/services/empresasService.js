import { db, ejecutar } from './supabase'

// Directorio: visible para todos los usuarios autenticados
export function listarEmpresas({ busqueda = '', rubro = '' } = {}) {
  let consulta = db().from('empresas').select('*').eq('activa', true).order('razon_social')
  if (busqueda) consulta = consulta.or(`razon_social.ilike.%${busqueda}%,nombre_fantasia.ilike.%${busqueda}%,localidad.ilike.%${busqueda}%`)
  if (rubro) consulta = consulta.eq('rubro', rubro)
  return ejecutar(consulta)
}

export function obtenerEmpresa(id) {
  return ejecutar(db().from('empresas').select('*').eq('id', id).single())
}

// Solo el empresa_admin de esa empresa (RLS)
export function actualizarEmpresa(id, cambios) {
  return ejecutar(db().from('empresas').update(cambios).eq('id', id).select().single())
}
