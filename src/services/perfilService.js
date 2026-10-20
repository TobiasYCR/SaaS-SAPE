import { db, ejecutar } from './supabase'

const SELECT_PERFIL = '*, escuela:escuelas(id, nombre), empresa:empresas(id, razon_social, nombre_fantasia)'

export function obtenerMiPerfil(userId) {
  return ejecutar(db().from('perfiles').select(SELECT_PERFIL).eq('id', userId).maybeSingle())
}

export function actualizarMiPerfil(userId, { nombre_completo, telefono }) {
  return ejecutar(db().from('perfiles').update({ nombre_completo, telefono }).eq('id', userId).select().single())
}

export function listarMiembros() {
  return ejecutar(db().from('perfiles').select('id, nombre_completo, email, rol, activo').not('rol', 'is', null).order('nombre_completo'))
}

// tipo: 'escuela' | 'empresa'. datos: columnas de la tabla correspondiente.
export function registrarOrganizacion(tipo, datos) {
  return ejecutar(db().rpc('registrar_organizacion', { p_tipo: tipo, p_datos: datos }))
}

// rol: 'escuela_admin' | 'escuela_tutor' | 'empresa_admin' | 'empresa_tutor'
export function asignarMiembro(email, rol) {
  return ejecutar(db().rpc('asignar_miembro', { p_email: email, p_rol: rol }))
}
