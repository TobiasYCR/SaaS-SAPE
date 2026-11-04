<script setup>
// Etiqueta + control (slot) + ayuda + mensaje de validación
defineProps({
  etiqueta: { type: String, required: true },
  error: { type: String, default: '' },
  ayuda: { type: String, default: '' },
  obligatorio: { type: Boolean, default: false },
  ancho: { type: Boolean, default: false },
})
</script>

<template>
  <label class="campo" :class="{ 'campo--invalido': error, 'campo--ancho': ancho }">
    <span>{{ etiqueta }}<span v-if="obligatorio" class="obligatorio" aria-hidden="true">*</span></span>
    <slot />
    <small v-if="ayuda && !error" class="campo-ayuda">{{ ayuda }}</small>
    <small v-if="error" class="campo-error" role="alert">{{ error }}</small>
  </label>
</template>
