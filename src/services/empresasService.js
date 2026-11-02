import { db, ejecutar } from './supabase'
import { textoBusqueda } from '../utils/validaciones'

// Directorio: visible para todos los usuarios autenticados
export function listarEmpresas({ busqueda = '', provincia = '', rubro = '' } = {}) {
  let consulta = db().from('empresas').select('*').eq('activa', true).order('razon_social')
  const texto = textoBusqueda(busqueda)
  if (texto) consulta = consulta.or(`razon_social.ilike.%${texto}%,nombre_fantasia.ilike.%${texto}%,localidad.ilike.%${texto}%,rubro.ilike.%${texto}%`)
  if (provincia) consulta = consulta.eq('provincia', provincia)
  if (rubro) consulta = consulta.eq('rubro', rubro)
  return ejecutar(consulta)
}

export function obtenerEmpresa(id) {
  return ejecutar(db().from('empresas').select('*').eq('id', id).single())
}

// Solo el empresa_admin de esa empresa (RLS)
export function actualizarEmpresa(id, { razon_social, nombre_fantasia, cuit, rubro, descripcion, direccion, localidad, provincia, email, telefono, sitio_web }) {
  return ejecutar(db().from('empresas')
    .update({ razon_social, nombre_fantasia, cuit, rubro, descripcion, direccion, localidad, provincia, email, telefono, sitio_web })
    .eq('id', id).select().single())
}
