<script setup>
import { onMounted, ref } from 'vue'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import DatosPruebaBadge from '../components/common/DatosPruebaBadge.vue'
import { useOperacion } from '../composables/useOperacion'
import { listarEmpresas } from '../services/empresasService'
import { PROVINCIAS } from '../utils/catalogos'

// Directorio de empresas. Cada empresa edita sus datos desde Mi organización.
const empresas = ref([])
const busqueda = ref('')
const provincia = ref('')
const { cargando, error, ejecutar } = useOperacion()

async function cargar() {
  const lista = await ejecutar(() => listarEmpresas({ busqueda: busqueda.value, provincia: provincia.value }))
  if (lista) empresas.value = lista
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro"><div><p>Organizaciones registradas que ofrecen pasantías</p><h2>Directorio de empresas</h2></div></section>
  <section class="panel table-panel">
    <form class="filtros" role="search" @submit.prevent="cargar">
      <label class="search-field">⌕<input v-model="busqueda" placeholder="Buscar por nombre, rubro o localidad" aria-label="Buscar empresas" /></label>
      <select v-model="provincia" aria-label="Filtrar por provincia" @change="cargar"><option value="">Todas las provincias</option><option v-for="p in PROVINCIAS" :key="p">{{ p }}</option></select>
      <button class="filter-button" type="submit" :disabled="cargando">Buscar</button>
    </form>
    <div style="padding:0 20px"><AvisoOperacion :cargando="cargando" texto-cargando="Cargando empresas..." :error="error" /></div>
    <p v-if="!cargando && !empresas.length && !error" class="vacio">No hay empresas que coincidan con la búsqueda.</p>
    <div v-else-if="empresas.length" class="table-wrap">
      <table class="tabla">
        <thead><tr><th>EMPRESA</th><th>RUBRO</th><th>UBICACIÓN</th><th>CONTACTO</th></tr></thead>
        <tbody>
          <tr v-for="e in empresas" :key="e.id">
            <td><strong>{{ e.nombre_fantasia || e.razon_social }}</strong> <DatosPruebaBadge v-if="e.datos_prueba" /><small>{{ e.descripcion || e.razon_social }}</small></td>
            <td>{{ e.rubro || '—' }}</td>
            <td>{{ e.localidad }}, {{ e.provincia }}</td>
            <td>{{ e.email || e.telefono || '—' }}<small v-if="e.sitio_web"><a :href="e.sitio_web" target="_blank" rel="noopener">{{ e.sitio_web }}</a></small></td>
          </tr>
        </tbody>
      </table>
      <p class="contador">{{ empresas.length }} empresa(s)</p>
    </div>
  </section>
</template>
