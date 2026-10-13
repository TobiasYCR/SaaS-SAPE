import { ref } from 'vue'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

const hasPlaceholderCredentials = /your-project-ref|placeholder/i.test(supabaseUrl || '')
  || /your_key_here|placeholder/i.test(supabaseKey || '')

export const supabase = supabaseUrl && supabaseKey && !hasPlaceholderCredentials
  ? createClient(supabaseUrl, supabaseKey)
  : null

export const currentUser = ref(null)
export const authError = ref('')
let initialized = false

export async function initializeAuth() {
  if (initialized) return

  if (!supabase) {
    if (hasPlaceholderCredentials) {
      authError.value = 'Reemplaza los valores de ejemplo del archivo .env por la URL y la clave publicable de tu proyecto Supabase, y reinicia el servidor.'
    } else {
      authError.value = 'Configura VITE_SUPABASE_URL y VITE_SUPABASE_PUBLISHABLE_KEY para habilitar la autenticación.'
    }
    initialized = true
    return
  }

  supabase.auth.onAuthStateChange((_event, session) => {
    currentUser.value = session?.user ?? null
    authError.value = ''
  })

  try {
    const { data, error } = await supabase.auth.getSession()
    if (error) {
      authError.value = error.message
      initialized = true
      return
    }

    currentUser.value = data.session?.user ?? null
    initialized = true
  } catch (error) {
    authError.value = error.message || 'No se pudo verificar la sesión.'
    initialized = true
  }
}
