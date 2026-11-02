<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { esEscuela } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { listarInscripciones } from '../services/inscripcionesService'
import { ESTADOS_INSCRIPCION, formatearFecha } from '../utils/catalogos'

const inscripciones = ref([])
const estado = ref('')
const busqueda = ref('')
const { cargando, error, ejecutar } = useOperacion()

// Búsqueda local por alumno, empresa o escuela sobre el resultado filtrado por estado
const visibles = computed(() => {
  const texto = busqueda.value.trim().toLowerCase()
  if (!texto) return inscripciones.value
  return inscripciones.value.filter((i) => [i.alumno?.apellido, i.alumno?.nombre, i.alumno?.dni, i.convenio?.area,
    i.convenio?.empresa?.razon_social, i.convenio?.empresa?.nombre_fantasia, i.convenio?.escuela?.nombre]
    .some((v) => v && String(v).toLowerCase().includes(texto)))
})

const PENDIENTE = computed(() => (esEscuela.value ? 'borrador' : 'enviada'))
const pendientes = computed(() => inscripciones.value.filter((i) => i.estado === PENDIENTE.value).length)

async function cargar() {
  const lista = await ejecutar(() => listarInscripciones({ estado: estado.value }))
  if (lista) inscripciones.value = lista
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div><p>{{ esEscuela ? 'Alumnos inscriptos en convenios activos' : 'Alumnos que las escuelas inscribieron en tus convenios' }}</p><h2>Inscripciones</h2></div>
  </section>

  <p v-if="pendientes && !estado" class="aviso aviso--info">
    {{ esEscuela ? `Hay ${pendientes} inscripción(es) en borrador sin enviar.` : `Hay ${pendientes} inscripción(es) enviadas esperando tu respuesta.` }}
  </p>

  <section class="panel table-panel">
    <div class="filtros">
      <label class="search-field">⌕<input v-model="busqueda" placeholder="Buscar por alumno, DNI, empresa o escuela" aria-label="Buscar inscripciones" /></label>
      <select v-model="estado" aria-label="Filtrar por estado" @change="cargar"><option value="">Todos los estados</option><option v-for="(etiqueta, valor) in ESTADOS_INSCRIPCION" :key="valor" :value="valor">{{ etiqueta }}</option></select>
    </div>
    <div style="padding:0 20px"><AvisoOperacion :cargando="cargando" texto-cargando="Cargando inscripciones..." :error="error" /></div>
    <p v-if="!cargando && !visibles.length && !error" class="vacio">No hay inscripciones que coincidan.</p>
    <div v-else-if="visibles.length" class="table-wrap">
      <table class="tabla">
        <thead><tr><th>ALUMNO</th><th>{{ esEscuela ? 'EMPRESA' : 'ESCUELA' }}</th><th>ÁREA</th><th>PERÍODO</th><th>ESTADO</th><th></th></tr></thead>
        <tbody>
          <tr v-for="i in visibles" :key="i.id">
            <td><strong>{{ i.alumno?.apellido }}, {{ i.alumno?.nombre }}</strong><small>DNI {{ i.alumno?.dni }}</small></td>
            <td>{{ esEscuela ? (i.convenio?.empresa?.nombre_fantasia || i.convenio?.empresa?.razon_social) : i.convenio?.escuela?.nombre }}</td>
            <td>{{ i.convenio?.area || '—' }}</td>
            <td>{{ formatearFecha(i.fecha_inicio) }} – {{ formatearFecha(i.fecha_fin) }}</td>
            <td><EstadoBadge :estado="i.estado" /></td>
            <td><RouterLink class="link-accion" :to="`/inscripciones/${i.id}`">Ver →</RouterLink></td>
          </tr>
        </tbody>
      </table>
      <p class="contador">{{ visibles.length }} inscripción(es)</p>
    </div>
  </section>
</template>
