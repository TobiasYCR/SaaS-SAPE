<script setup>
import { computed, ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { currentUser, ETIQUETA_ROL, organizacion, perfil, rol } from '../../composables/useAuth'
import { supabase } from '../../services/supabase'
import DatosPruebaBadge from '../common/DatosPruebaBadge.vue'

defineProps({ open: { type: Boolean, default: false } })
const emit = defineEmits(['navigate'])

const router = useRouter()
const signOutError = ref('')

// tipo: limita el ítem a un tipo de organización
const ITEMS = [
  { label: 'Resumen general', to: '/dashboard', icon: '⌂' },
  { label: 'Escuelas', to: '/escuelas', icon: '▦' },
  { label: 'Empresas', to: '/empresas', icon: '▦' },
  { label: 'Alumnos', to: '/alumnos', icon: '♙', tipo: 'escuela' },
  { label: 'Convenios', to: '/convenios', icon: '▤' },
  { label: 'Inscripciones', to: '/inscripciones', icon: '✓' },
  { label: 'Seguimientos', to: '/seguimientos', icon: '◷' },
  { label: 'Mi organización', to: '/organizacion', icon: '⚙' },
]

const navigation = computed(() => {
  if (!organizacion.value) return [{ label: 'Registrar organización', to: '/registro-organizacion', icon: '+' }]
  return ITEMS.filter((item) => !item.tipo || item.tipo === organizacion.value.tipo)
})

const userName = computed(() => perfil.value?.nombre_completo || currentUser.value?.user_metadata?.full_name || currentUser.value?.email || 'Usuario')
const initials = (texto) => texto.split(/\s+/).slice(0, 2).map((parte) => parte.charAt(0).toUpperCase()).join('')
const orgNombre = computed(() => organizacion.value?.nombre || 'Sin organización')
const orgTipo = computed(() => ETIQUETA_ROL[rol.value] || 'Completá el registro')

async function signOut() {
  signOutError.value = ''
  if (!supabase) {
    signOutError.value = 'La autenticación no está configurada.'
    return
  }
  try {
    const { error } = await supabase.auth.signOut()
    if (error) {
      signOutError.value = error.message
      return
    }
    await router.replace('/login')
  } catch (error) {
    signOutError.value = error.message || 'No se pudo cerrar la sesión.'
  }
}
</script>

<template>
  <aside class="sidebar" :class="{ 'sidebar--open': open }">
    <div class="brand">
      <div class="brand-mark">S</div>
      <div>
        <strong>SAPE</strong>
        <span>Pasantías escolares</span>
      </div>
    </div>

    <div class="workspace-switcher">
      <div class="avatar avatar--small">{{ initials(orgNombre) }}</div>
      <div>
        <strong>{{ orgNombre }}</strong>
        <span>{{ orgTipo }}</span>
        <DatosPruebaBadge v-if="organizacion?.datosPrueba" />
      </div>
    </div>

    <p class="nav-label">{{ organizacion?.tipo === 'empresa' ? 'EMPRESA' : 'VIDA ESCOLAR' }}</p>
    <nav class="main-nav" aria-label="Navegación principal">
      <RouterLink v-for="item in navigation" :key="item.to" :to="item.to" @click="emit('navigate')">
        <span class="nav-icon" aria-hidden="true">{{ item.icon }}</span>{{ item.label }}
      </RouterLink>
    </nav>

    <div class="sidebar-bottom">
      <div class="user-row"><div class="avatar">{{ initials(userName) }}</div><div class="user-details"><strong>{{ userName }}</strong><span>{{ currentUser?.email }}</span></div></div>
      <p v-if="signOutError" class="sidebar-error" role="alert">{{ signOutError }}</p>
      <div class="account-actions">
        <RouterLink to="/change-password" @click="emit('navigate')">Cambiar contraseña</RouterLink>
        <button type="button" @click="signOut">Cerrar sesión</button>
      </div>
    </div>
  </aside>
</template>
