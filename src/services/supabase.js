import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

export const hasPlaceholderCredentials = /your-project-ref|placeholder/i.test(supabaseUrl || '')
  || /your_key_here|placeholder/i.test(supabaseKey || '')

export const supabase = supabaseUrl && supabaseKey && !hasPlaceholderCredentials
  ? createClient(supabaseUrl, supabaseKey)
  : null

// Cliente garantizado para los services
export function db() {
  if (!supabase) throw new Error('Supabase no está configurado. Revisá el archivo .env')
  return supabase
}

// Devuelve data o lanza el error de Supabase
export async function ejecutar(consulta) {
  const { data, error } = await consulta
  if (error) throw error
  return data
}
