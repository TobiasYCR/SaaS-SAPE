import { hoy } from './catalogos'

// Validaciones de formularios. Cada validador devuelve un objeto { campo: mensaje }.
// Las mismas reglas están en la base (CHECK y triggers); acá se anticipan para avisar antes de enviar.

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/
const vacio = (v) => v === null || v === undefined || String(v).trim() === ''

export function requeridos(datos, campos) {
  const errores = {}
  for (const [campo, etiqueta] of Object.entries(campos)) {
    if (vacio(datos[campo])) errores[campo] = `${etiqueta} es obligatorio.`
  }
  return errores
}

function email(errores, valor, campo = 'email') {
  if (!vacio(valor) && !EMAIL.test(valor)) errores[campo] = 'El email no tiene un formato válido.'
}

function rangoFechas(errores, inicio, fin, campo = 'fecha_fin') {
  if (!vacio(inicio) && !vacio(fin) && fin < inicio) errores[campo] = 'La fecha de fin no puede ser anterior a la de inicio.'
}

export function validarEscuela(d) {
  const e = requeridos(d, { nombre: 'El nombre', cue: 'El CUE', localidad: 'La localidad', provincia: 'La provincia' })
  if (!e.cue && !/^\d{9}$/.test(d.cue)) e.cue = 'El CUE debe tener 9 dígitos.'
  email(e, d.email)
  return e
}

export function validarEmpresa(d) {
  const e = requeridos(d, { razon_social: 'La razón social', cuit: 'El CUIT', localidad: 'La localidad', provincia: 'La provincia' })
  if (!e.cuit && !/^\d{11}$/.test(String(d.cuit).replace(/-/g, ''))) e.cuit = 'El CUIT debe tener 11 dígitos.'
  email(e, d.email)
  if (!vacio(d.sitio_web) && !/^https?:\/\/\S+$/.test(d.sitio_web)) e.sitio_web = 'El sitio debe empezar con http:// o https://'
  return e
}

export function validarAlumno(d) {
  const e = requeridos(d, { nombre: 'El nombre', apellido: 'El apellido', dni: 'El DNI' })
  if (!e.dni && !/^\d{7,8}$/.test(d.dni)) e.dni = 'El DNI debe tener 7 u 8 dígitos, sin puntos.'
  if (!vacio(d.curso) && !(Number(d.curso) >= 1 && Number(d.curso) <= 7)) e.curso = 'El curso debe estar entre 1 y 7.'
  if (!vacio(d.fecha_nacimiento) && d.fecha_nacimiento > hoy()) {
    e.fecha_nacimiento = 'La fecha de nacimiento no puede ser futura.'
  }
  email(e, d.email)
  return e
}

export function validarConvenio(d) {
  const e = requeridos(d, { ciclo_lectivo: 'El ciclo lectivo', cupos: 'Los cupos', area: 'El área' })
  if (!e.ciclo_lectivo && !(Number(d.ciclo_lectivo) >= 2020 && Number(d.ciclo_lectivo) <= 2100)) e.ciclo_lectivo = 'Ciclo lectivo inválido.'
  if (!e.cupos && !(Number.isInteger(Number(d.cupos)) && Number(d.cupos) > 0)) e.cupos = 'Los cupos deben ser un número entero mayor a 0.'
  rangoFechas(e, d.fecha_inicio, d.fecha_fin)
  return e
}

export function validarRequisito(d) {
  return requeridos(d, { nombre: 'El nombre', tipo: 'El tipo' })
}

// Valor de un requisito según su tipo (mismo criterio que el trigger validar_dato_inscripcion)
export function validarValorRequisito(tipo, valor) {
  if (vacio(valor)) return ''
  if (tipo === 'numero' && !/^-?\d+([.,]\d+)?$/.test(valor)) return 'Debe ser un número.'
  if (tipo === 'si_no' && !['si', 'no'].includes(valor)) return 'Elegí sí o no.'
  if (tipo === 'fecha' && Number.isNaN(Date.parse(valor))) return 'Fecha inválida.'
  return ''
}

export function validarSeguimiento(d) {
  const e = requeridos(d, { fecha: 'La fecha', progreso: 'El progreso', observaciones: 'Las observaciones' })
  if (!e.progreso && !(Number(d.progreso) >= 0 && Number(d.progreso) <= 100)) e.progreso = 'El progreso debe estar entre 0 y 100.'
  if (!vacio(d.proxima_fecha) && !vacio(d.fecha) && d.proxima_fecha < d.fecha) e.proxima_fecha = 'La próxima fecha no puede ser anterior a la del seguimiento.'
  return e
}

export function validarInscripcion(d) {
  const e = {}
  rangoFechas(e, d.fecha_inicio, d.fecha_fin)
  if (!vacio(d.horas_totales) && !(Number.isInteger(Number(d.horas_totales)) && Number(d.horas_totales) > 0)) {
    e.horas_totales = 'Las horas deben ser un número entero mayor a 0.'
  }
  return e
}

export const hayErrores = (errores) => Object.keys(errores).length > 0

// Convierte '' en null antes de enviar a la base
export function limpiarVacios(datos) {
  return Object.fromEntries(Object.entries(datos).map(([k, v]) => [k, typeof v === 'string' && v.trim() === '' ? null : typeof v === 'string' ? v.trim() : v]))
}

// Evita que el texto de búsqueda rompa la sintaxis de filtros de PostgREST
export function textoBusqueda(texto) {
  return String(texto || '').replace(/[,()*%\\]/g, ' ').trim()
}
