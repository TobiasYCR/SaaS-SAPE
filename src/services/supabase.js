import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

export const hasPlaceholderCredentials = /your-project-ref|placeholder/i.test(supabaseUrl || '')
  || /your_key_here|placeholder/i.test(supabaseKey || '')

function esUrlValida(url) {
  try {
    const parsed = new URL(url)
    return ['http:', 'https:'].includes(parsed.protocol) && Boolean(parsed.hostname)
  } catch {
    return false
  }
}

export const supabaseConfigError = !supabaseUrl || !supabaseKey
  ? 'Configura VITE_SUPABASE_URL y VITE_SUPABASE_PUBLISHABLE_KEY para habilitar la autenticación.'
  : hasPlaceholderCredentials
    ? 'Reemplaza los valores de ejemplo del archivo .env por la URL y la clave publicable de tu proyecto Supabase, y reinicia el servidor.'
    : !esUrlValida(supabaseUrl)
      ? 'VITE_SUPABASE_URL no es válida. Usa la Project URL de Supabase, que debe comenzar con https://.'
      : ''

export const supabase = !supabaseConfigError
  ? createClient(supabaseUrl, supabaseKey)
  : null

// Cliente garantizado para los services
export function db() {
  if (!supabase) throw new Error(supabaseConfigError || 'Supabase no está configurado. Revisá el archivo .env')
  return supabase
}

// Devuelve data o lanza el error de Supabase
export async function ejecutar(consulta) {
  const { data, error } = await consulta
  if (error) throw error
  return data
}
