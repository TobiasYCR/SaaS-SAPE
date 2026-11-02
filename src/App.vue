<script setup>
import { computed, ref } from 'vue'
import { RouterView, useRoute } from 'vue-router'
import AppSidebar from './components/layout/AppSidebar.vue'
import AppTopbar from './components/layout/AppTopbar.vue'
import AvisoDatosPrueba from './components/common/AvisoDatosPrueba.vue'

const route = useRoute()
const isMenuOpen = ref(false)
const pageTitle = computed(() => route.meta.titulo || 'SAPE')
</script>

<template>
  <RouterView v-if="route.meta.publicAuth" />
  <div v-else class="app-shell">
    <AppSidebar :open="isMenuOpen" @navigate="isMenuOpen = false" />
    <div v-if="isMenuOpen" class="sidebar-backdrop" aria-hidden="true" @click="isMenuOpen = false"></div>
    <main class="main-content">
      <AppTopbar :title="pageTitle" @toggle-menu="isMenuOpen = !isMenuOpen" />
      <div class="page-content"><AvisoDatosPrueba /><RouterView :key="route.fullPath" /></div>
    </main>
  </div>
</template>
