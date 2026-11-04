<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import DatosPruebaBadge from '../components/common/DatosPruebaBadge.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import FormPropuesta from '../components/convenios/FormPropuesta.vue'
import { organizacion, rol } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { listarConvenios, postularse } from '../services/conveniosService'
import { listarEscuelas } from '../services/escuelasService'
import { anioActual, PROVINCIAS } from '../utils/catalogos'
import { hayErrores, limpiarVacios, validarConvenio } from '../utils/validaciones'

const escuelas = ref([])
const misConvenios = ref([])
const busqueda = ref('')
const provincia = ref('')
const seleccionada = ref(null)
const propuesta = ref(null)
const errores = ref({})

const puedePostularse = computed(() => rol.value === 'empresa_admin')
const listado = useOperacion()
const postulacion = useOperacion()

// Último convenio de esta empresa con cada escuela, para mostrar su estado
const convenioPorEscuela = computed(() => Object.fromEntries([...misConvenios.value].reverse().map((c) => [c.escuela_id, c])))
const CERRADOS = ['rechazado', 'cancelado', 'finalizado']

async function cargar() {
  const [lista, convenios] = await listado.ejecutar(() => Promise.all([
    listarEscuelas({ busqueda: busqueda.value, provincia: provincia.value }),
    organizacion.value?.tipo === 'empresa' ? listarConvenios() : Promise.resolve([]),
  ])) || []
  if (lista) escuelas.value = lista
  if (convenios) misConvenios.value = convenios
}

function abrirPostulacion(escuela) {
  seleccionada.value = escuela
  propuesta.value = { area: '', descripcion: '', cupos: 1, ciclo_lectivo: anioActual(), fecha_inicio: '', fecha_fin: '' }
  errores.value = {}
  postulacion.limpiar()
}

async function enviarPostulacion() {
  errores.value = validarConvenio(propuesta.value)
  if (hayErrores(errores.value)) return
  const ok = await postulacion.ejecutar(
    () => postularse({ ...limpiarVacios(propuesta.value), empresa_id: organizacion.value.id, escuela_id: seleccionada.value.id }),
    `Te postulaste a ${seleccionada.value.nombre}. La escuela tiene que aceptar la postulación.`,
  )
  if (ok) {
    seleccionada.value = null
    await cargar()
  }
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div><p>{{ puedePostularse ? 'Elegí las escuelas con las que querés trabajar y postulate' : 'Instituciones registradas en la plataforma' }}</p><h2>Directorio de escuelas</h2></div>
  </section>

  <AvisoOperacion :exito="postulacion.exito.value" />

  <form v-if="seleccionada" class="panel formulario seccion" novalidate @submit.prevent="enviarPostulacion">
    <div class="seccion-titulo"><h3>Postularse a {{ seleccionada.nombre }}</h3></div>
    <FormPropuesta v-model="propuesta" :errores="errores" />
    <AvisoOperacion :error="postulacion.error.value" />
    <div class="acciones acciones--fin">
      <button class="filter-button" type="button" @click="seleccionada = null">Cancelar</button>
      <button class="primary-button" type="submit" :disabled="postulacion.cargando.value">{{ postulacion.cargando.value ? 'Enviando...' : 'Enviar postulación' }}</button>
    </div>
  </form>

  <section class="panel table-panel">
    <form class="filtros" role="search" @submit.prevent="cargar">
      <label class="search-field">⌕<input v-model="busqueda" placeholder="Buscar por nombre, localidad o modalidad" aria-label="Buscar escuelas" /></label>
      <select v-model="provincia" aria-label="Filtrar por provincia" @change="cargar"><option value="">Todas las provincias</option><option v-for="p in PROVINCIAS" :key="p">{{ p }}</option></select>
      <button class="filter-button" type="submit" :disabled="listado.cargando.value">Buscar</button>
    </form>
    <div style="padding:0 20px"><AvisoOperacion :cargando="listado.cargando.value" texto-cargando="Cargando escuelas..." :error="listado.error.value" /></div>
    <p v-if="!listado.cargando.value && !escuelas.length && !listado.error.value" class="vacio">No hay escuelas que coincidan con la búsqueda.</p>
    <div v-else-if="escuelas.length" class="table-wrap">
      <table class="tabla">
        <thead><tr><th>ESCUELA</th><th>MODALIDAD</th><th>UBICACIÓN</th><th>CONTACTO</th><th v-if="organizacion?.tipo === 'empresa'">CONVENIO</th></tr></thead>
        <tbody>
          <tr v-for="e in escuelas" :key="e.id">
            <td><strong>{{ e.nombre }}</strong> <DatosPruebaBadge v-if="e.datos_prueba" /><small>{{ (e.especialidades || []).join(' · ') || 'Sin especialidades cargadas' }}</small></td>
            <td>{{ e.modalidad || '—' }}</td>
            <td>{{ e.localidad }}, {{ e.provincia }}</td>
            <td>{{ e.email || e.telefono || '—' }}</td>
            <td v-if="organizacion?.tipo === 'empresa'">
              <div class="acciones">
                <RouterLink v-if="convenioPorEscuela[e.id]" :to="`/convenios/${convenioPorEscuela[e.id].id}`"><EstadoBadge :estado="convenioPorEscuela[e.id].estado" /></RouterLink>
                <button v-if="puedePostularse && (!convenioPorEscuela[e.id] || CERRADOS.includes(convenioPorEscuela[e.id].estado))" class="secondary-button boton-chico" type="button" @click="abrirPostulacion(e)">Postularse</button>
                <span v-if="!convenioPorEscuela[e.id] && !puedePostularse">—</span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <p class="contador">{{ escuelas.length }} escuela(s)</p>
    </div>
  </section>
</template>
