<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { esEscuela } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { listarPasantiasConSeguimientos } from '../services/seguimientosService'
import { formatearFecha, hoy } from '../utils/catalogos'

const pasantias = ref([])
const estado = ref('en_curso')
const busqueda = ref('')
const { cargando, error, ejecutar } = useOperacion()

// Resumen por pasantía: último progreso y próxima fecha
const filas = computed(() => {
  const texto = busqueda.value.trim().toLowerCase()
  return pasantias.value
    .map((p) => {
      const ordenados = [...(p.seguimientos || [])].sort((a, b) => b.fecha.localeCompare(a.fecha))
      const ultimo = ordenados[0]
      return { ...p, ultimo, cantidad: ordenados.length, vencido: ultimo?.proxima_fecha && ultimo.proxima_fecha < hoy() }
    })
    .filter((p) => !texto || `${p.alumno?.apellido} ${p.alumno?.nombre} ${p.convenio?.area} ${p.convenio?.empresa?.razon_social} ${p.convenio?.escuela?.nombre}`.toLowerCase().includes(texto))
    .sort((a, b) => (a.ultimo?.proxima_fecha || '9999').localeCompare(b.ultimo?.proxima_fecha || '9999'))
})

async function cargar() {
  const estados = estado.value === 'todas' ? ['en_curso', 'finalizada'] : [estado.value]
  const lista = await ejecutar(() => listarPasantiasConSeguimientos(estados))
  if (lista) pasantias.value = lista
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div><p>Progreso de las pasantías y próximos controles</p><h2>Seguimientos</h2></div>
  </section>

  <section class="panel table-panel">
    <div class="filtros">
      <label class="search-field">⌕<input v-model="busqueda" placeholder="Buscar por alumno, área u organización" aria-label="Buscar pasantías" /></label>
      <select v-model="estado" aria-label="Filtrar por estado" @change="cargar"><option value="en_curso">En curso</option><option value="finalizada">Finalizadas</option><option value="todas">Todas</option></select>
    </div>
    <div style="padding:0 20px"><AvisoOperacion :cargando="cargando" texto-cargando="Cargando pasantías..." :error="error" /></div>
    <p v-if="!cargando && !filas.length && !error" class="vacio">No hay pasantías {{ estado === 'en_curso' ? 'en curso' : '' }} para mostrar.</p>
    <div v-else-if="filas.length" class="followup-list" style="padding:0 20px 10px">
      <div v-for="p in filas" :key="p.id" class="followup-row">
        <div class="avatar avatar--blue">{{ (p.alumno?.nombre?.[0] || '') + (p.alumno?.apellido?.[0] || '') }}</div>
        <div class="followup-person">
          <strong>{{ p.alumno?.apellido }}, {{ p.alumno?.nombre }}</strong>
          <span>{{ p.convenio?.area }} · {{ esEscuela ? (p.convenio?.empresa?.nombre_fantasia || p.convenio?.empresa?.razon_social) : p.convenio?.escuela?.nombre }}</span>
        </div>
        <div class="progress-block">
          <div class="progress-label"><span>Progreso ({{ p.cantidad }} seguimientos)</span><strong>{{ p.ultimo?.progreso ?? 0 }}%</strong></div>
          <div class="progress-bar"><span :style="{ width: `${p.ultimo?.progreso ?? 0}%` }"></span></div>
        </div>
        <div class="next-date">
          <span>Próximo seguimiento</span>
          <strong :style="p.vencido ? 'color:#b04444' : ''">{{ p.estado === 'finalizada' ? 'Finalizada' : formatearFecha(p.ultimo?.proxima_fecha) }}{{ p.vencido && p.estado === 'en_curso' ? ' (vencido)' : '' }}</strong>
        </div>
        <EstadoBadge :estado="p.estado" />
        <RouterLink class="secondary-button button-small" :to="`/inscripciones/${p.id}`">Ver detalle</RouterLink>
      </div>
    </div>
  </section>
</template>
