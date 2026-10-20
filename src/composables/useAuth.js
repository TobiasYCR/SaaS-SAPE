import { computed, ref } from 'vue'
import { hasPlaceholderCredentials, supabase } from '../services/supabase'
import { obtenerMiPerfil } from '../services/perfilService'

export const currentUser = ref(null)
export const perfil = ref(null)
export const authError = ref('')

// Organización del usuario: { tipo: 'escuela' | 'empresa', id, nombre } o null
export const organizacion = computed(() => {
  if (perfil.value?.escuela) return { tipo: 'escuela', id: perfil.value.escuela.id, nombre: perfil.value.escuela.nombre }
  if (perfil.value?.empresa) {
    const { id, nombre_fantasia, razon_social } = perfil.value.empresa
    return { tipo: 'empresa', id, nombre: nombre_fantasia || razon_social }
  }
  return null
})

let initialized = false

async function cargarPerfil(user) {
  if (!user) {
    perfil.value = null
    return
  }
  try {
    perfil.value = await obtenerMiPerfil(user.id)
  } catch (error) {
    perfil.value = null
    authError.value = error.message || 'No se pudo cargar el perfil.'
  }
}

export async function recargarPerfil() {
  await cargarPerfil(currentUser.value)
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
    const cambioUsuario = user?.id !== currentUser.value?.id
    currentUser.value = user
    // Fuera del callback para no bloquear el cliente de auth
    if (cambioUsuario) setTimeout(() => cargarPerfil(user), 0)
  })

  try {
    const { data, error } = await supabase.auth.getSession()
    if (error) authError.value = error.message
    else {
      currentUser.value = data.session?.user ?? null
      await cargarPerfil(currentUser.value)
    }
  } catch (error) {
    authError.value = error.message || 'No se pudo verificar la sesión.'
  } finally {
    initialized = true
  }
}
