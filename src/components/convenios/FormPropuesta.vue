<script setup>
import CampoFormulario from '../common/CampoFormulario.vue'

// Propuesta de la empresa: área, descripción, cupos, ciclo y fechas
const datos = defineModel({ type: Object, required: true })
defineProps({
  errores: { type: Object, default: () => ({}) },
  conCiclo: { type: Boolean, default: true },
})
</script>

<template>
  <div class="form-grid">
    <CampoFormulario etiqueta="Área o puesto" :error="errores.area" obligatorio>
      <input v-model="datos.area" maxlength="120" placeholder="Desarrollo web" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Cupos" :error="errores.cupos" ayuda="Máximo de alumnos que se aceptan" obligatorio>
      <input v-model.number="datos.cupos" type="number" min="1" max="100" step="1" />
    </CampoFormulario>
    <CampoFormulario v-if="conCiclo" etiqueta="Ciclo lectivo" :error="errores.ciclo_lectivo" obligatorio>
      <input v-model.number="datos.ciclo_lectivo" type="number" min="2020" max="2100" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Fecha de inicio" :error="errores.fecha_inicio">
      <input v-model="datos.fecha_inicio" type="date" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Fecha de fin" :error="errores.fecha_fin">
      <input v-model="datos.fecha_fin" type="date" :min="datos.fecha_inicio || undefined" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Descripción de la propuesta" ancho>
      <textarea v-model="datos.descripcion" maxlength="800" rows="3" placeholder="Tareas, horario, lugar..."></textarea>
    </CampoFormulario>
  </div>
</template>
