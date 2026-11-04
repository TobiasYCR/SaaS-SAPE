<script setup>
import CampoFormulario from '../common/CampoFormulario.vue'
import { PROVINCIAS } from '../../utils/catalogos'

const datos = defineModel({ type: Object, required: true })
defineProps({ errores: { type: Object, default: () => ({}) } })
</script>

<template>
  <div class="form-grid">
    <CampoFormulario etiqueta="Razón social" :error="errores.razon_social" obligatorio>
      <input v-model="datos.razon_social" maxlength="150" autocomplete="organization" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Nombre de fantasía" :error="errores.nombre_fantasia">
      <input v-model="datos.nombre_fantasia" maxlength="150" />
    </CampoFormulario>
    <CampoFormulario etiqueta="CUIT" :error="errores.cuit" ayuda="11 dígitos, sin guiones" obligatorio>
      <input v-model="datos.cuit" inputmode="numeric" maxlength="13" placeholder="30700000011" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Rubro" :error="errores.rubro">
      <input v-model="datos.rubro" maxlength="80" placeholder="Software, Contabilidad..." />
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
    <CampoFormulario etiqueta="Sitio web" :error="errores.sitio_web">
      <input v-model="datos.sitio_web" type="url" maxlength="200" placeholder="https://" />
    </CampoFormulario>
    <CampoFormulario etiqueta="Descripción" ancho>
      <textarea v-model="datos.descripcion" maxlength="600" rows="3"></textarea>
    </CampoFormulario>
  </div>
</template>
