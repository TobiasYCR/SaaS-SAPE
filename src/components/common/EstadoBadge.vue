<script setup>
import { computed } from 'vue'

// Estados de convenios e inscripciones (enums de la base)
const ETIQUETAS = {
  postulado: 'Postulado', aceptado: 'Aceptado', rechazado: 'Rechazado', activo: 'Activo',
  finalizado: 'Finalizado', cancelado: 'Cancelado', borrador: 'Borrador', enviada: 'Enviada',
  aceptada: 'Aceptada', rechazada: 'Rechazada', en_curso: 'En curso', finalizada: 'Finalizada', cancelada: 'Cancelada',
}
const POSITIVOS = ['aceptado', 'activo', 'aceptada', 'en_curso', 'finalizado', 'finalizada']

const props = defineProps({ estado: { type: String, required: true } })
const etiqueta = computed(() => ETIQUETAS[props.estado] || props.estado)
const clase = computed(() => POSITIVOS.includes(props.estado) ? 'product-status--active' : 'product-status--inactive')
</script>

<template>
  <span class="product-status" :class="clase">{{ etiqueta }}</span>
</template>
