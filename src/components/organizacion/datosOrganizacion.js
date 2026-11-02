// Conversión entre el formulario y las columnas de escuelas / empresas
import { limpiarVacios } from '../../utils/validaciones'

const CAMPOS_ESCUELA = ['nombre', 'cue', 'modalidad', 'descripcion', 'direccion', 'localidad', 'provincia', 'email', 'telefono']
const CAMPOS_EMPRESA = ['razon_social', 'nombre_fantasia', 'cuit', 'rubro', 'descripcion', 'direccion', 'localidad', 'provincia', 'email', 'telefono', 'sitio_web']

export function formularioVacio(tipo) {
  const campos = tipo === 'escuela' ? CAMPOS_ESCUELA : CAMPOS_EMPRESA
  const datos = Object.fromEntries(campos.map((c) => [c, '']))
  if (tipo === 'escuela') datos.especialidadesTexto = ''
  return datos
}

export function aFormulario(tipo, registro) {
  const datos = formularioVacio(tipo)
  for (const campo of Object.keys(datos)) datos[campo] = registro?.[campo] ?? ''
  if (tipo === 'escuela') datos.especialidadesTexto = (registro?.especialidades || []).join(', ')
  return datos
}

export function aRegistro(tipo, datos) {
  const { especialidadesTexto, ...resto } = datos
  const registro = limpiarVacios(resto)
  if (tipo === 'escuela') {
    registro.especialidades = (especialidadesTexto || '').split(',').map((e) => e.trim()).filter(Boolean)
  } else if (registro.cuit) {
    registro.cuit = registro.cuit.replace(/-/g, '')
  }
  return registro
}
