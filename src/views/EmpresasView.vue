<script setup>
import { onMounted, ref } from 'vue'
import { listarEmpresas } from '../services/empresasService'

// Directorio de empresas. Cada empresa carga y edita sus propios datos
// desde su cuenta; acá solo se consultan.
const empresas = ref([])
const busqueda = ref('')
const cargando = ref(false)
const errorMensaje = ref('')

async function cargarEmpresas() {
  cargando.value = true
  errorMensaje.value = ''
  try {
    empresas.value = await listarEmpresas({ busqueda: busqueda.value.trim() })
  } catch (error) {
    errorMensaje.value = error.message?.toLowerCase().includes('could not find the table')
      ? 'No existe la tabla empresas en Supabase. Ejecutá supabase/schema.sql'
      : error.message
  } finally {
    cargando.value = false
  }
}

onMounted(cargarEmpresas)
</script>

<template>
  <section class="page-intro"><div><p>Organizaciones registradas que ofrecen pasantías</p><h2>Directorio de empresas</h2></div></section>
  <section class="panel products-list-panel">
    <div class="products-list-header">
      <div><p class="eyebrow">ORGANIZACIONES</p><h2>Empresas registradas</h2></div>
      <form class="toolbar" @submit.prevent="cargarEmpresas">
        <label class="search-field">⌕<input v-model="busqueda" placeholder="Buscar por nombre o localidad..." /></label>
        <button class="filter-button" type="submit" :disabled="cargando">Buscar</button>
      </form>
    </div>
    <p v-if="errorMensaje" class="product-message product-message--error" role="alert">{{ errorMensaje }}</p>
    <p v-else-if="cargando && !empresas.length" class="products-empty">Cargando empresas...</p>
    <p v-else-if="!empresas.length" class="products-empty">No hay empresas que coincidan</p>
    <div v-else class="product-table-wrap">
      <table class="product-table">
        <thead><tr><th>LOGO</th><th>EMPRESA</th><th>RUBRO</th><th>UBICACIÓN</th><th>CONTACTO</th></tr></thead>
        <tbody>
          <tr v-for="empresa in empresas" :key="empresa.id">
            <td><img v-if="empresa.logo_url" class="product-thumbnail" :src="empresa.logo_url" :alt="empresa.razon_social"><span v-else class="product-no-image">Sin logo</span></td>
            <td class="product-cell"><strong>{{ empresa.nombre_fantasia || empresa.razon_social }}</strong><small>{{ empresa.descripcion || empresa.razon_social }}</small></td>
            <td>{{ empresa.rubro || 'Sin rubro' }}</td>
            <td>{{ empresa.localidad }}, {{ empresa.provincia }}</td>
            <td>{{ empresa.email || empresa.telefono || '—' }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>
