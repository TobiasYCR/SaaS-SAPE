<script setup>
import { computed, ref } from 'vue'
import { RouterView, useRoute } from 'vue-router'
import AppSidebar from './components/layout/AppSidebar.vue'
import AppTopbar from './components/layout/AppTopbar.vue'

const route = useRoute()
const isMenuOpen = ref(false)

const titles = {
  '/dashboard': 'Resumen general',
  '/offers': 'Ofertas de pasantía',
  '/applications': 'Postulaciones',
  '/followups': 'Seguimientos',
  '/change-password': 'Cambiar contraseña',
  '/empresas': 'Empresas',
}
const pageTitle = computed(() => titles[route.path] || 'SAPE')
</script>

<template>
  <RouterView v-if="route.meta.publicAuth" />
  <div v-else class="app-shell">
    <AppSidebar :open="isMenuOpen" @navigate="isMenuOpen = false" />
    <main class="main-content">
      <AppTopbar :title="pageTitle" @toggle-menu="isMenuOpen = !isMenuOpen" />
      <div class="page-content"><RouterView /></div>
    </main>
  </div>
</template>
