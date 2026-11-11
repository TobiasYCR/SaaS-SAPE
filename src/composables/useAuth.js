import { computed, ref } from 'vue'
import { hasPlaceholderCredentials, supabase } from '../services/supabase'
import { obtenerMiPerfil } from '../services/perfilService'
import { traducirError } from '../utils/errores'

export const currentUser = ref(null)
export const perfil = ref(null)
export const authError = ref('')
// Error al leer el perfil (por ejemplo, sin conexión): no significa que el usuario no tenga organización
export const errorPerfil = ref('')
export const cargandoPerfil = ref(false)

// Organización del usuario: { tipo: 'escuela' | 'empresa', id, nombre, datosPrueba } o null
export const organizacion = computed(() => {
  const escuela = perfil.value?.escuela
  const empresa = perfil.value?.empresa
  if (escuela) return { tipo: 'escuela', id: escuela.id, nombre: escuela.nombre, datosPrueba: escuela.datos_prueba }
  if (empresa) return { tipo: 'empresa', id: empresa.id, nombre: empresa.nombre_fantasia || empresa.razon_social, datosPrueba: empresa.datos_prueba }
  return null
})

export const rol = computed(() => perfil.value?.rol ?? null)
export const esEscuela = computed(() => organizacion.value?.tipo === 'escuela')
export const esEmpresa = computed(() => organizacion.value?.tipo === 'empresa')
export const esAdmin = computed(() => ['escuela_admin', 'empresa_admin'].includes(rol.value))

export const ETIQUETA_ROL = {
  escuela_admin: 'Administrador de escuela',
  escuela_tutor: 'Tutor de escuela',
  empresa_admin: 'Administrador de empresa',
  empresa_tutor: 'Tutor de empresa',
}

let initialized = false
let cargaPendiente = null
let perfilCargadoPara = null

async function cargarPerfil(user) {
  if (!user) {
    perfil.value = null
    perfilCargadoPara = null
    errorPerfil.value = ''
    return
  }
  try {
    perfil.value = await obtenerMiPerfil(user.id)
    perfilCargadoPara = user.id
    errorPerfil.value = ''
  } catch (error) {
    perfil.value = null
    perfilCargadoPara = null
    errorPerfil.value = traducirError(error)
  }
}

// Garantiza que el perfil corresponda al usuario actual (usado por las guardas del router)
export async function asegurarPerfil() {
  const user = currentUser.value
  if (!user || perfilCargadoPara === user.id) return
  cargandoPerfil.value = true
  cargaPendiente ??= cargarPerfil(user).finally(() => {
    cargaPendiente = null
    cargandoPerfil.value = false
  })
  await cargaPendiente
}

export async function recargarPerfil() {
  perfilCargadoPara = null
  await asegurarPerfil()
}

export async function initializeAuth() {
  if (initialized) return

  if (!supabase) {
    authError.value = hasPlaceholderCredentials
      ? 'Reemplaza los valores de ejemplo del archivo .env por la URL y la clave publicable de tu proyecto Supabase, y reinicia el servidor.'
      : 'Configura VITE_SUPABASE_URL y VITE_SUPABASE_PUBLISHABLE_KEY para habilitar la autenticación.'
    initialized = true
    return
  }

  supabase.auth.onAuthStateChange((_event, session) => {
    authError.value = ''
    const user = session?.user ?? null
    if (user?.id !== currentUser.value?.id) {
      perfil.value = null
      perfilCargadoPara = null
    }
    currentUser.value = user
    // Fuera del callback para no bloquear el cliente de auth
    if (user) setTimeout(() => asegurarPerfil(), 0)
  })

  try {
    const { data, error } = await supabase.auth.getSession()
    if (error) authError.value = error.message
    else {
      currentUser.value = data.session?.user ?? null
      await asegurarPerfil()
    }
  } catch (error) {
    authError.value = error.message || 'No se pudo verificar la sesión.'
  } finally {
    initialized = true
  }
}
