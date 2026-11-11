<script setup>
import CampoFormulario from '../common/CampoFormulario.vue'

// Mismo formulario (y mismas reglas: validarAlumno) para el alta y la modificación
const datos = defineModel({ type: Object, required: true })
defineProps({ errores: { type: Object, default: () => ({}) } })
</script>

<template>
  <div class="form-grid form-grid--3">
    <CampoFormulario etiqueta="Apellido" :error="errores.apellido" obligatorio><input v-model="datos.apellido" maxlength="80" autocomplete="off" /></CampoFormulario>
    <CampoFormulario etiqueta="Nombre" :error="errores.nombre" obligatorio><input v-model="datos.nombre" maxlength="80" autocomplete="off" /></CampoFormulario>
    <CampoFormulario etiqueta="DNI" :error="errores.dni" ayuda="Sin puntos" obligatorio><input v-model="datos.dni" inputmode="numeric" maxlength="8" /></CampoFormulario>
    <CampoFormulario etiqueta="Fecha de nacimiento" :error="errores.fecha_nacimiento"><input v-model="datos.fecha_nacimiento" type="date" /></CampoFormulario>
    <CampoFormulario etiqueta="Curso" :error="errores.curso">
      <select v-model="datos.curso"><option value="">—</option><option v-for="n in 7" :key="n" :value="n">{{ n }}°</option></select>
    </CampoFormulario>
    <CampoFormulario etiqueta="División" :error="errores.division"><input v-model="datos.division" maxlength="10" /></CampoFormulario>
    <CampoFormulario etiqueta="Especialidad" :error="errores.especialidad"><input v-model="datos.especialidad" maxlength="80" /></CampoFormulario>
    <CampoFormulario etiqueta="Email" :error="errores.email"><input v-model="datos.email" type="email" maxlength="150" /></CampoFormulario>
    <CampoFormulario etiqueta="Teléfono" :error="errores.telefono"><input v-model="datos.telefono" type="tel" maxlength="40" /></CampoFormulario>
    <CampoFormulario etiqueta="Responsable (madre, padre o tutor)" :error="errores.responsable_nombre"><input v-model="datos.responsable_nombre" maxlength="120" /></CampoFormulario>
    <CampoFormulario etiqueta="Teléfono del responsable" :error="errores.responsable_telefono"><input v-model="datos.responsable_telefono" type="tel" maxlength="40" /></CampoFormulario>
  </div>
</template>
