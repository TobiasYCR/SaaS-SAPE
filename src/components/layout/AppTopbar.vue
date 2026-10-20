<script setup>
import { computed } from 'vue'

defineProps({ title: { type: String, required: true } })
const emit = defineEmits(['toggle-menu'])

const hoy = computed(() => {
  const texto = new Intl.DateTimeFormat('es-AR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }).format(new Date())
  return texto.charAt(0).toUpperCase() + texto.slice(1)
})
</script>

<template>
  <header class="topbar">
    <button class="menu-button" aria-label="Abrir menú" @click="emit('toggle-menu')">☰</button>
    <div><p class="eyebrow">SAPE / {{ title }}</p><h1>{{ title }}</h1></div>
    <div class="topbar-actions">
      <button class="icon-button" aria-label="Notificaciones">♧<span class="notification-dot"></span></button>
      <div class="topbar-date">{{ hoy }}</div>
    </div>
  </header>
</template>
