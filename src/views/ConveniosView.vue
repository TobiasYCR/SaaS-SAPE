<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import DatosPruebaBadge from '../components/common/DatosPruebaBadge.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { esEscuela, rol } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { listarConvenios } from '../services/conveniosService'
import { ESTADOS_CONVENIO, formatearFecha } from '../utils/catalogos'

const convenios = ref([])
const estado = ref('')
const ciclo = ref('')
const { cargando, error, ejecutar } = useOperacion()

const ciclos = computed(() => [...new Set(convenios.value.map((c) => c.ciclo_lectivo))].sort((a, b) => b - a))
const pendientes = computed(() => convenios.value.filter((c) => c.estado === 'postulado').length)
const contraparte = (c) => (esEscuela.value ? c.empresa?.nombre_fantasia || c.empresa?.razon_social : c.escuela?.nombre)
const contraparteDePrueba = (c) => (esEscuela.value ? c.empresa?.datos_prueba : c.escuela?.datos_prueba)

async function cargar() {
  const lista = await ejecutar(() => listarConvenios({ estado: estado.value, ciclo: ciclo.value }))
  if (lista) convenios.value = lista
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div>
      <p>{{ esEscuela ? 'Empresas que eligieron tu escuela' : 'Escuelas a las que te postulaste' }}</p>
      <h2>Convenios</h2>
    </div>
    <RouterLink v-if="rol === 'empresa_admin'" class="primary-button" to="/escuelas">+ Postularse a una escuela</RouterLink>
  </section>

  <p v-if="esEscuela && pendientes && !estado" class="aviso aviso--info">Tenés {{ pendientes }} postulación(es) esperando tu respuesta.</p>

  <section class="panel table-panel">
    <div class="filtros">
      <select v-model="estado" aria-label="Filtrar por estado" @change="cargar"><option value="">Todos los estados</option><option v-for="(etiqueta, valor) in ESTADOS_CONVENIO" :key="valor" :value="valor">{{ etiqueta }}</option></select>
      <select v-model="ciclo" aria-label="Filtrar por ciclo lectivo" @change="cargar"><option value="">Todos los ciclos</option><option v-for="c in ciclos" :key="c" :value="c">{{ c }}</option></select>
    </div>
    <div style="padding:0 20px"><AvisoOperacion :cargando="cargando" texto-cargando="Cargando convenios..." :error="error" /></div>
    <p v-if="!cargando && !convenios.length && !error" class="vacio">No hay convenios {{ estado ? 'con ese estado' : 'todavía' }}.</p>
    <div v-else-if="convenios.length" class="table-wrap">
      <table class="tabla">
        <thead><tr><th>{{ esEscuela ? 'EMPRESA' : 'ESCUELA' }}</th><th>ÁREA</th><th>CICLO</th><th>CUPOS</th><th>INSCRIPCIONES</th><th>ESTADO</th><th></th></tr></thead>
        <tbody>
          <tr v-for="c in convenios" :key="c.id">
            <td><strong>{{ contraparte(c) }}</strong> <DatosPruebaBadge v-if="contraparteDePrueba(c)" /><small>Postulado el {{ formatearFecha(c.creado_en) }}</small></td>
            <td>{{ c.area || '—' }}</td>
            <td>{{ c.ciclo_lectivo }}</td>
            <td>{{ c.cupos }}</td>
            <td>{{ c.inscripciones?.[0]?.count ?? 0 }}</td>
            <td><EstadoBadge :estado="c.estado" /></td>
            <td><RouterLink class="link-accion" :to="`/convenios/${c.id}`">Ver →</RouterLink></td>
          </tr>
        </tbody>
      </table>
      <p class="contador">{{ convenios.length }} convenio(s)</p>
    </div>
  </section>
</template>
