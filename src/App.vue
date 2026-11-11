<script setup>
import { computed, ref, watch } from 'vue'
import { RouterView, useRoute, useRouter } from 'vue-router'
import AppSidebar from './components/layout/AppSidebar.vue'
import AppTopbar from './components/layout/AppTopbar.vue'
import AvisoDatosPrueba from './components/common/AvisoDatosPrueba.vue'
import { cargandoPerfil, cuentaDesactivada, currentUser, errorPerfil, recargarPerfil } from './composables/useAuth'

const route = useRoute()
const router = useRouter()

// Sesión cerrada (en esta u otra pestaña) o vencida sin poder renovarse:
// se sale de la pantalla privada aunque el usuario no navegue.
watch(currentUser, (usuario, anterior) => {
  if (!usuario && anterior && route.meta.requiresAuth) {
    router.replace({ path: '/login', query: { redirect: route.fullPath, motivo: 'sesion' } })
  }
})
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
      <div class="page-content">
        <p v-if="cargandoPerfil" class="cargando" role="status">Conectando con el servidor...</p>
        <div v-if="errorPerfil && !cargandoPerfil" class="aviso aviso--error" role="alert">
          No se pudieron cargar los datos de tu cuenta: {{ errorPerfil }}
          <button class="link-accion" type="button" style="margin-left:8px" @click="recargarPerfil">Reintentar</button>
        </div>
        <p v-if="cuentaDesactivada" class="aviso aviso--error" role="alert">
          Tu cuenta está desactivada. Pedile al administrador de tu organización que la vuelva a habilitar.
        </p>
        <template v-else><AvisoDatosPrueba /><RouterView :key="route.fullPath" /></template>
      </div>
    </main>
  </div>
</template>
