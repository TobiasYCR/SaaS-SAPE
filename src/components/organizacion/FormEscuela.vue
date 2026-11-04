<script setup>
import CampoFormulario from '../common/CampoFormulario.vue'
import { PROVINCIAS } from '../../utils/catalogos'

const datos = defineModel({ type: Object, required: true })
defineProps({ errores: { type: Object, default: () => ({}) } })
</script>

<template>
  <div class="form-grid">
    <CampoFormulario etiqueta="Nombre de la escuela" :error="errores.nombre" obligatorio ancho>
      <input v-model="datos.nombre" maxlength="150" autocomplete="organization" />
    </CampoFormulario>
    <CampoFormulario etiqueta="CUE" :error="errores.cue" ayuda="9 dígitos, sin guiones" obligatorio>
      <input v-model="datos.cue" inputmode="numeric" maxlength="9" placeholder="060000101" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Modalidad" :error="errores.modalidad">
      <select v-model="datos.modalidad">
        <option value="">Sin especificar</option>
        <option>Técnica</option><option>Orientada</option><option>Agrotécnica</option><option>Artística</option><option>Adultos</option>
      </select>
    </CampoFormulario>
    <CampoFormulario etiqueta="Especialidades" ayuda="Separadas por coma. Ej.: Programación, Electrónica" ancho>
      <input v-model="datos.especialidadesTexto" maxlength="300" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Dirección" :error="errores.direccion">
      <input v-model="datos.direccion" maxlength="150" autocomplete="street-address" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Localidad" :error="errores.localidad" obligatorio>
      <input v-model="datos.localidad" maxlength="100" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Provincia" :error="errores.provincia" obligatorio>
      <select v-model="datos.provincia"><option value="">Elegí una provincia</option><option v-for="p in PROVINCIAS" :key="p">{{ p }}</option></select>
    </CampoFormulario>
    <CampoFormulario etiqueta="Email de contacto" :error="errores.email">
      <input v-model="datos.email" type="email" maxlength="150" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Teléfono" :error="errores.telefono">
      <input v-model="datos.telefono" type="tel" maxlength="40" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Descripción" ancho>
      <textarea v-model="datos.descripcion" maxlength="600" rows="3"></textarea>
    </CampoFormulario>
  </div>
</template>
