<script setup>
import { computed, ref } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { currentUser, organizacion } from '../../composables/useAuth'
import { supabase } from '../../services/supabase'

defineProps({ open: { type: Boolean, default: false } })
const emit = defineEmits(['navigate'])

const router = useRouter()
const signOutError = ref('')

const navigation = [
  { label: 'Resumen general', to: '/dashboard', icon: '⌂' },
  { label: 'Ofertas', to: '/offers', icon: '▤' },
  { label: 'Postulaciones', to: '/applications', icon: '✓' },
  { label: 'Seguimientos', to: '/followups', icon: '◷' },
  { label: 'Empresas', to: '/empresas', icon: '▦' },
]

const userName = computed(() => currentUser.value?.user_metadata?.full_name || currentUser.value?.email || 'Usuario')
const initials = (texto) => texto.split(/\s+/).slice(0, 2).map((parte) => parte.charAt(0).toUpperCase()).join('')
const userInitials = computed(() => initials(userName.value))
const orgNombre = computed(() => organizacion.value?.nombre || 'Sin organización')
const orgTipo = computed(() => ({ escuela: 'Institución educativa', empresa: 'Empresa' })[organizacion.value?.tipo] || 'Completá el registro')

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
      <div><strong>{{ orgNombre }}</strong><span>{{ orgTipo }}</span></div>
      <span class="chevron">⌄</span>
    </div>

    <p class="nav-label">VIDA ESCOLAR</p>
    <nav class="main-nav" aria-label="Navegación principal">
      <RouterLink v-for="item in navigation" :key="item.to" :to="item.to" @click="emit('navigate')">
        <span class="nav-icon">{{ item.icon }}</span>{{ item.label }}
      </RouterLink>
    </nav>

    <div class="sidebar-bottom">
      <div class="help-card"><span class="help-icon">?</span><div><strong>¿Necesitas ayuda?</strong><span>Visita nuestro centro de soporte</span></div></div>
      <div class="user-row"><div class="avatar">{{ userInitials }}</div><div class="user-details"><strong>{{ userName }}</strong><span>{{ currentUser?.email }}</span></div></div>
      <p v-if="signOutError" class="sidebar-error" role="alert">{{ signOutError }}</p>
      <div class="account-actions">
        <RouterLink to="/change-password">Cambiar contraseña</RouterLink>
        <button type="button" @click="signOut">Cerrar sesión</button>
      </div>
    </div>
  </aside>
</template>
