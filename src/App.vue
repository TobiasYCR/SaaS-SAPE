<script setup>
import { computed, ref } from 'vue'
import { RouterLink, RouterView, useRoute } from 'vue-router'

const route = useRoute()
const isMenuOpen = ref(false)

const pageTitle = computed(() => {
  const titles = {
    '/dashboard': 'Resumen general',
    '/offers': 'Ofertas de pasantía',
    '/applications': 'Postulaciones',
    '/followups': 'Seguimientos',
  }
  return titles[route.path] || 'SAPE'
})

const navigation = [
  { label: 'Resumen general', to: '/dashboard', icon: '⌂' },
  { label: 'Ofertas', to: '/offers', icon: '▤' },
  { label: 'Postulaciones', to: '/applications', icon: '✓' },
  { label: 'Seguimientos', to: '/followups', icon: '◷' },
]
</script>

<template>
  <div class="app-shell">
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
        <div><strong>Santa Catalina</strong><span>Institución educativa</span></div>
        <span class="chevron">⌄</span>
      </div>

      <p class="nav-label">GESTIÓN</p>
      <nav class="main-nav" aria-label="Navegación principal">
        <RouterLink v-for="item in navigation" :key="item.to" :to="item.to" @click="isMenuOpen = false">
          <span class="nav-icon">{{ item.icon }}</span>{{ item.label }}
        </RouterLink>
      </nav>

      <div class="sidebar-bottom">
        <div class="help-card"><span class="help-icon">?</span><div><strong>¿Necesitas ayuda?</strong><span>Visita nuestro centro de soporte</span></div></div>
        <div class="user-row"><div class="avatar">AC</div><div><strong>Andrea Cubas</strong><span>Coordinadora</span></div><span class="dots">•••</span></div>
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
