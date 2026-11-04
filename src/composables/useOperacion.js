import { ref } from 'vue'
import { traducirError } from '../utils/errores'

// Estado uniforme de carga, éxito y error para cualquier operación con la base.
export function useOperacion() {
  const cargando = ref(false)
  const error = ref('')
  const exito = ref('')

  async function ejecutar(fn, mensajeExito = '') {
    cargando.value = true
    error.value = ''
    exito.value = ''
    try {
      const resultado = await fn()
      exito.value = mensajeExito
      return resultado
    } catch (e) {
      error.value = traducirError(e)
      return undefined
    } finally {
      cargando.value = false
    }
  }

  function limpiar() {
    error.value = ''
    exito.value = ''
  }

  return { cargando, error, exito, ejecutar, limpiar }
}
