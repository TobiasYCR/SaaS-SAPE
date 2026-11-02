<script setup>
// Mensajes de carga, confirmación y error de una operación (ver useOperacion)
defineProps({
  cargando: { type: Boolean, default: false },
  textoCargando: { type: String, default: 'Cargando...' },
  error: { type: String, default: '' },
  exito: { type: String, default: '' },
})
</script>

<template>
  <p v-if="cargando" class="cargando" role="status">{{ textoCargando }}</p>
  <p v-if="error" class="aviso aviso--error" role="alert">{{ error }}</p>
  <p v-if="exito" class="aviso aviso--exito" role="status">{{ exito }}</p>
</template>
