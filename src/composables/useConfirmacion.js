import { reactive } from 'vue'

export const estadoConfirmacion = reactive({
  abierta: false,
  titulo: 'Confirmar acción',
  mensaje: '',
  textoConfirmar: 'Aceptar',
  textoCancelar: 'Cancelar',
  peligro: false,
})

let resolverActual = null

/**
 * Muestra un diálogo de confirmación dentro del sistema y devuelve una promesa
 * que resuelve en true (aceptar) o false (cancelar).
 */
export function confirmar(opciones) {
  if (resolverActual) {
    resolverActual(false)
    resolverActual = null
  }

  const config = typeof opciones === 'string' ? { mensaje: opciones } : opciones
  estadoConfirmacion.titulo = config.titulo || 'Confirmar acción'
  estadoConfirmacion.mensaje = config.mensaje || ''
  estadoConfirmacion.textoConfirmar = config.textoConfirmar || 'Aceptar'
  estadoConfirmacion.textoCancelar = config.textoCancelar || 'Cancelar'
  estadoConfirmacion.peligro = Boolean(config.peligro)
  estadoConfirmacion.abierta = true

  return new Promise((resolve) => {
    resolverActual = resolve
  })
}

export function responderConfirmacion(confirmado) {
  estadoConfirmacion.abierta = false
  if (resolverActual) {
    const resolve = resolverActual
    resolverActual = null
    resolve(Boolean(confirmado))
  }
}
