// Valores fijos usados en formularios, filtros y etiquetas

export const PROVINCIAS = [
  'Buenos Aires', 'CABA', 'Catamarca', 'Chaco', 'Chubut', 'Córdoba', 'Corrientes', 'Entre Ríos', 'Formosa',
  'Jujuy', 'La Pampa', 'La Rioja', 'Mendoza', 'Misiones', 'Neuquén', 'Río Negro', 'Salta', 'San Juan',
  'San Luis', 'Santa Cruz', 'Santa Fe', 'Santiago del Estero', 'Tierra del Fuego', 'Tucumán',
]

export const ESTADOS_CONVENIO = {
  postulado: 'Postulado', aceptado: 'Aceptado', rechazado: 'Rechazado',
  activo: 'Activo', finalizado: 'Finalizado', cancelado: 'Cancelado',
}

export const ESTADOS_INSCRIPCION = {
  borrador: 'Borrador', enviada: 'Enviada', aceptada: 'Aceptada', rechazada: 'Rechazada',
  en_curso: 'En curso', finalizada: 'Finalizada', cancelada: 'Cancelada',
}

export const TIPOS_REQUISITO = {
  texto: 'Texto', numero: 'Número', fecha: 'Fecha', archivo: 'Archivo (PDF o imagen)', si_no: 'Sí / No',
}

export const ROLES_MIEMBRO = {
  escuela: { escuela_admin: 'Administrador', escuela_tutor: 'Tutor' },
  empresa: { empresa_admin: 'Administrador', empresa_tutor: 'Tutor' },
}

export const formatearFecha = (valor) => {
  if (!valor) return '—'
  const [a, m, d] = String(valor).slice(0, 10).split('-')
  return `${d}/${m}/${a}`
}

export const anioActual = () => new Date().getFullYear()
export const hoy = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}
