<script setup>
import { computed, ref } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { currentUser, supabase } from './auth'

const route = useRoute()
const router = useRouter()
const isMenuOpen = ref(false)
const signOutError = ref('')

const pageTitle = computed(() => {
  const titles = {
    '/dashboard': 'Resumen general',
    '/offers': 'Ofertas de pasantía',
    '/applications': 'Postulaciones',
    '/followups': 'Seguimientos',
    '/change-password': 'Cambiar contraseña',
  }
  return titles[route.path] || 'SAPE'
})

const userName = computed(() => currentUser.value?.user_metadata?.full_name || currentUser.value?.email || 'Usuario')
const userInitials = computed(() => userName.value
  .split(/\s+/)
  .slice(0, 2)
  .map((part) => part.charAt(0).toUpperCase())
  .join(''))

const navigation = [
  { label: 'Resumen general', to: '/dashboard', icon: '⌂' },
  { label: 'Ofertas', to: '/offers', icon: '▤' },
  { label: 'Postulaciones', to: '/applications', icon: '✓' },
  { label: 'Seguimientos', to: '/followups', icon: '◷' },
]

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
  <RouterView v-if="route.meta.publicAuth" />
  <div v-else class="app-shell">
    <aside class="sidebar" :class="{ 'sidebar--open': isMenuOpen }">
      <div class="brand">
        <div class="brand-mark">S</div>
        <div>
          <strong>SAPE</strong>
          <span>Pasantías escolares</span>
        </div>
      </div>

      <div class="workspace-switcher">
        <div class="avatar avatar--small">SC</div>
        <div><strong>Tecnica 67</strong><span>Institución educativa</span></div>
        <span class="chevron">⌄</span>
      </div>

      <p class="nav-label">VIDA ESCOLAR</p>
      <nav class="main-nav" aria-label="Navegación principal">
        <RouterLink v-for="item in navigation" :key="item.to" :to="item.to" @click="isMenuOpen = false">
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

    <main class="main-content">
      <header class="topbar">
        <button class="menu-button" aria-label="Abrir menú" @click="isMenuOpen = !isMenuOpen">☰</button>
        <div><p class="eyebrow">SAPE / {{ pageTitle }}</p><h1>{{ pageTitle }}</h1></div>
        <div class="topbar-actions"><button class="icon-button" aria-label="Notificaciones">♧<span class="notification-dot"></span></button><div class="topbar-date">Miércoles, 7 de octubre de 2026</div></div>
      </header>
      <div class="page-content"><RouterView /></div>
    </main>
  </div>
</template>
