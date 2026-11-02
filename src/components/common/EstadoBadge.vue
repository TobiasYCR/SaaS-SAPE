<script setup>
import { computed } from 'vue'
import { ESTADOS_CONVENIO, ESTADOS_INSCRIPCION } from '../../utils/catalogos'

// Estados de convenios e inscripciones (enums de la base)
const COLOR = {
  postulado: 'azul', aceptado: 'violeta', activo: 'verde', rechazado: 'rojo', finalizado: 'gris', cancelado: 'gris',
  borrador: 'gris', enviada: 'azul', aceptada: 'violeta', en_curso: 'verde', rechazada: 'rojo', finalizada: 'gris', cancelada: 'gris',
  activo_alumno: 'verde', inactivo: 'gris',
}

const props = defineProps({ estado: { type: String, required: true }, etiqueta: { type: String, default: '' } })
const texto = computed(() => props.etiqueta || ESTADOS_CONVENIO[props.estado] || ESTADOS_INSCRIPCION[props.estado] || props.estado)
</script>

<template>
  <span class="estado" :class="`estado--${COLOR[estado] || 'gris'}`">{{ texto }}</span>
</template>
