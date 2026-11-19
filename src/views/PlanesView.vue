<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { esEscuela, rol } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { abrirDocumentoPlan, listarConvenios, listarDocumentosPlan, subirDocumentoPlan } from '../services/conveniosService'
import { formatearFecha } from '../utils/catalogos'

const convenios = ref([])
const documentos = ref({})
const pestaña = ref('actuales')
const busqueda = ref('')
const porPagina = ref(5)
const pagina = ref(1)
const cargandoDocumentos = ref('')
const descripcionAnexo = ref('')
const carga = useOperacion()

const HISTORICO = ['rechazado', 'cancelado', 'finalizado']

const visibles = computed(() => {
  const texto = busqueda.value.trim().toLowerCase()
  return convenios.value.filter((c) => {
    const historico = HISTORICO.includes(c.estado)
    if (pestaña.value === 'historico' ? !historico : historico) return false
    if (!texto) return true
    return [c.numero_plan, c.tipo_plan, c.area, c.empresa?.nombre_fantasia, c.empresa?.razon_social, c.escuela?.nombre]
      .some((valor) => valor && String(valor).toLowerCase().includes(texto))
  })
})

const contraparte = (c) => esEscuela.value
  ? c.empresa?.nombre_fantasia || c.empresa?.razon_social
  : c.escuela?.nombre

const totalPaginas = computed(() => Math.max(1, Math.ceil(visibles.value.length / porPagina.value)))
const paginaActual = computed(() => Math.min(pagina.value, totalPaginas.value))
const paginados = computed(() => {
  const inicio = (paginaActual.value - 1) * porPagina.value
  return visibles.value.slice(inicio, inicio + porPagina.value)
})
const rangoMostrado = computed(() => {
  if (!visibles.value.length) return { desde: 0, hasta: 0 }
  const desde = (paginaActual.value - 1) * porPagina.value + 1
  const hasta = Math.min(desde + porPagina.value - 1, visibles.value.length)
  return { desde, hasta }
})

function cambiarPestaña(nueva) {
  pestaña.value = nueva
  pagina.value = 1
}

async function cargar() {
  const lista = await carga.ejecutar(() => listarConvenios())
  if (!lista) return
  convenios.value = lista
  await Promise.all(lista.map(async (c) => {
    documentos.value[c.id] = await listarDocumentosPlan(c.id)
  }))
}

async function cargarAnexo(c, event) {
  const archivo = event.target.files?.[0]
  if (!archivo) return
  cargandoDocumentos.value = c.id
  try {
    await subirDocumentoPlan(c.id, archivo, descripcionAnexo.value)
    descripcionAnexo.value = ''
    documentos.value[c.id] = await listarDocumentosPlan(c.id)
  } catch (error) {
    carga.error.value = error.message || 'No se pudo cargar el anexo.'
  } finally {
    cargandoDocumentos.value = ''
    event.target.value = ''
  }
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div><p>Planes, ofertas vinculadas y disposiciones</p><h2>Planes {{ new Date().getFullYear() }}</h2></div>
    <RouterLink v-if="rol === 'empresa_admin'" class="primary-button" to="/escuelas">+ Nuevo plan</RouterLink>
  </section>

  <AvisoOperacion :cargando="carga.cargando.value" texto-cargando="Cargando planes..." :error="carga.error.value" />

  <section class="panel table-panel">
    <div class="pestañas" role="tablist" aria-label="Planes">
      <button type="button" :class="{ activa: pestaña === 'actuales' }" @click="cambiarPestaña('actuales')">Planes del periodo actual</button>
      <button type="button" :class="{ activa: pestaña === 'historico' }" @click="cambiarPestaña('historico')">Planes históricos</button>
    </div>
    <div class="filtros">
      <select v-model.number="porPagina" aria-label="Mostrar cantidad de planes" @change="pagina = 1">
        <option :value="5">Mostrar 5 planes</option>
        <option :value="10">Mostrar 10 planes</option>
        <option :value="25">Mostrar 25 planes</option>
        <option :value="50">Mostrar 50 planes</option>
      </select>
      <label class="search-field">⌕<input v-model="busqueda" placeholder="Buscar por número, institución u oferta" aria-label="Buscar planes" @input="pagina = 1" /></label>
      <button class="filter-button" type="button" @click="cargar" :disabled="carga.cargando.value">Actualizar</button>
    </div>

    <p v-if="!carga.cargando.value && !visibles.length" class="vacio">No hay planes para mostrar.</p>
    <div v-else-if="visibles.length" class="table-wrap">
      <table class="tabla">
        <thead>
          <tr><th>PLAN / OFERTA</th><th>INSTITUCIÓN</th><th v-if="pestaña === 'historico'">ADJUNTO</th><th>FECHA CARGA</th><th>PERIODO</th><th>TIPO</th><th>VISADO</th><th>ESTADO</th><th>OPERACIONES</th></tr>
        </thead>
        <tbody>
          <tr v-for="c in paginados" :key="c.id">
            <td><strong>{{ c.numero_plan || 'Sin número' }}</strong><small>{{ c.area || 'Sin oferta definida' }}</small></td>
            <td>{{ contraparte(c) }}</td>
            <td v-if="pestaña === 'historico'">
              <button v-if="(documentos[c.id] || []).length" class="product-action" type="button" @click="carga.ejecutar(() => abrirDocumentoPlan((documentos[c.id] || [])[0]?.ruta))">Ver adjunto</button>
              <span v-else class="campo-ayuda">Sin adjunto</span>
            </td>
            <td>{{ formatearFecha(c.fecha_carga || c.creado_en) }}</td>
            <td>{{ c.ciclo_lectivo }}</td>
            <td>{{ c.tipo_plan || 'PPE' }}</td>
            <td>{{ c.visto ? 'Sí' : 'No' }}</td>
            <td><EstadoBadge :estado="c.estado" /></td>
            <td>
              <div class="acciones">
                <RouterLink class="product-action" :to="`/convenios/${c.id}`">Detalles del plan</RouterLink>
                <button class="product-action" type="button" @click="carga.ejecutar(() => abrirDocumentoPlan((documentos[c.id] || [])[0]?.ruta).catch((e) => Promise.reject(e)))" :disabled="!(documentos[c.id] || []).length">Ver disposiciones</button>
                <label class="product-action" :class="{ 'is-disabled': cargandoDocumentos === c.id }">
                  {{ cargandoDocumentos === c.id ? 'Cargando...' : 'Cargar anexo' }}
                  <input type="file" accept=".pdf,image/jpeg,image/png" :disabled="cargandoDocumentos === c.id" @change="cargarAnexo(c, $event)" style="display:none" />
                </label>
              </div>
              <small v-for="d in documentos[c.id] || []" :key="d.id">
                <button class="link-accion" type="button" @click="abrirDocumentoPlan(d.ruta)">{{ d.nombre }}</button>
              </small>
            </td>
          </tr>
        </tbody>
      </table>
      <div class="paginacion">
        <p class="contador">Mostrando planes del {{ rangoMostrado.desde }} al {{ rangoMostrado.hasta }} de un total de {{ visibles.length }} planes</p>
        <div v-if="totalPaginas > 1" class="acciones">
          <button class="filter-button" type="button" :disabled="paginaActual <= 1" @click="pagina = paginaActual - 1">Anterior</button>
          <span class="contador">Página {{ paginaActual }} / {{ totalPaginas }}</span>
          <button class="filter-button" type="button" :disabled="paginaActual >= totalPaginas" @click="pagina = paginaActual + 1">Siguiente</button>
        </div>
      </div>
    </div>
  </section>
</template>
