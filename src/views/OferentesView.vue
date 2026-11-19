<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import DatosPruebaBadge from '../components/common/DatosPruebaBadge.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { useOperacion } from '../composables/useOperacion'
import { listarConvenios } from '../services/conveniosService'

const convenios = ref([])
const empresaIdSeleccionada = ref('')
const convenioIdSeleccionado = ref('')
const seleccionado = ref(null)
const carga = useOperacion()

const vinculados = computed(() => convenios.value
  .filter((c) => ['aceptado', 'activo', 'finalizado'].includes(c.estado))
  .sort((a, b) => (a.empresa?.nombre_fantasia || a.empresa?.razon_social || '')
    .localeCompare(b.empresa?.nombre_fantasia || b.empresa?.razon_social || '')))

const empresas = computed(() => {
  const mapa = new Map()
  for (const c of vinculados.value) {
    if (c.empresa && !mapa.has(c.empresa.id)) mapa.set(c.empresa.id, c.empresa)
  }
  return Array.from(mapa.values())
})

const lugaresDeEmpresa = computed(() =>
  vinculados.value.filter((c) => c.empresa?.id === empresaIdSeleccionada.value),
)

watch(empresaIdSeleccionada, () => {
  convenioIdSeleccionado.value = lugaresDeEmpresa.value[0]?.id || ''
})

function verDatos() {
  seleccionado.value = vinculados.value.find((c) => c.id === convenioIdSeleccionado.value) || null
}

async function cargar() {
  const lista = await carga.ejecutar(() => listarConvenios())
  if (!lista) return
  convenios.value = lista
  if (empresas.value.length) {
    empresaIdSeleccionada.value = empresas.value[0].id
    convenioIdSeleccionado.value = vinculados.value.find((c) => c.empresa?.id === empresaIdSeleccionada.value)?.id || ''
    verDatos()
  }
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div><p>Empresas vinculadas y lugar de práctica</p><h2>Instituciones oferentes vinculadas</h2></div>
  </section>

  <AvisoOperacion :cargando="carga.cargando.value" texto-cargando="Cargando oferentes..." :error="carga.error.value" />

  <section v-if="vinculados.length" class="panel seccion">
    <form class="filtros" @submit.prevent="verDatos">
      <label class="campo-inline">
        <span>Institución oferente</span>
        <select v-model="empresaIdSeleccionada" aria-label="Institución oferente">
          <option v-for="e in empresas" :key="e.id" :value="e.id">
            {{ e.nombre_fantasia || e.razon_social }}
          </option>
        </select>
      </label>
      <label class="campo-inline">
        <span>Lugar de práctica</span>
        <select v-model="convenioIdSeleccionado" aria-label="Lugar de práctica">
          <option v-for="c in lugaresDeEmpresa" :key="c.id" :value="c.id">
            {{ c.area || c.empresa?.nombre_fantasia || c.empresa?.razon_social }} ({{ c.ciclo_lectivo }})
          </option>
        </select>
      </label>
      <button class="primary-button" type="submit">Ver datos</button>
    </form>
  </section>

  <p v-if="!carga.cargando.value && !vinculados.length && !carga.error.value" class="vacio">No hay oferentes con convenios aceptados o activos.</p>

  <div v-if="seleccionado" class="dos-columnas">
    <section class="panel seccion">
      <div class="seccion-titulo">
        <h3>Institución oferente</h3>
        <DatosPruebaBadge v-if="seleccionado.empresa?.datos_prueba" />
      </div>
      <dl class="detalle">
        <div><dt>Estado de adhesión</dt><dd><EstadoBadge :estado="seleccionado.estado" /></dd></div>
        <div><dt>Institución oferente</dt><dd><strong>{{ seleccionado.empresa?.razon_social || seleccionado.empresa?.nombre_fantasia || '—' }}</strong></dd></div>
        <div><dt>CUIT</dt><dd>{{ seleccionado.empresa?.cuit || '—' }}</dd></div>
        <div><dt>Domicilio</dt><dd>{{ seleccionado.empresa?.direccion || '—' }}</dd></div>
        <div><dt>Distrito / Localidad</dt><dd>{{ [seleccionado.empresa?.localidad, seleccionado.empresa?.provincia].filter(Boolean).join(', ') || '—' }}</dd></div>
        <div><dt>Rubro</dt><dd>{{ seleccionado.empresa?.rubro || '—' }}</dd></div>
        <div><dt>Teléfono</dt><dd>{{ seleccionado.empresa?.telefono || '—' }}</dd></div>
        <div><dt>Correo electrónico</dt><dd>{{ seleccionado.empresa?.email || '—' }}</dd></div>
        <div><dt>Web</dt><dd><a v-if="seleccionado.empresa?.sitio_web" :href="seleccionado.empresa.sitio_web" target="_blank" rel="noopener">{{ seleccionado.empresa.sitio_web }}</a><span v-else>—</span></dd></div>
        <div><dt>Responsable</dt><dd>{{ seleccionado.empresa?.referente_nombre || '—' }}</dd></div>
      </dl>
    </section>

    <section class="panel seccion">
      <div class="seccion-titulo">
        <h3>Lugar de práctica</h3>
        <RouterLink class="link-accion" :to="`/convenios/${seleccionado.id}`">Ver convenio →</RouterLink>
      </div>
      <dl class="detalle">
        <div><dt>Lugar práctica</dt><dd><strong>{{ seleccionado.area || seleccionado.empresa?.nombre_fantasia || '—' }}</strong></dd></div>
        <div><dt>Domicilio</dt><dd>{{ seleccionado.empresa?.direccion || '—' }}</dd></div>
        <div><dt>Distrito / Localidad</dt><dd>{{ [seleccionado.empresa?.localidad, seleccionado.empresa?.provincia].filter(Boolean).join(', ') || '—' }}</dd></div>
        <div><dt>Teléfono</dt><dd>{{ seleccionado.empresa?.referente_telefono || seleccionado.empresa?.telefono || '—' }}</dd></div>
        <div><dt>Correo electrónico</dt><dd>{{ seleccionado.empresa?.referente_email || seleccionado.empresa?.email || '—' }}</dd></div>
        <div><dt>Resp. práctica</dt><dd>{{ seleccionado.empresa?.referente_nombre || '—' }}{{ seleccionado.empresa?.referente_cargo ? ` (${seleccionado.empresa.referente_cargo})` : '' }}</dd></div>
        <div><dt>Cupos</dt><dd>{{ seleccionado.cupos }}</dd></div>
        <div class="campo--ancho"><dt>Período</dt><dd>{{ seleccionado.ciclo_lectivo }} · {{ seleccionado.fecha_inicio || 'Sin fecha' }} a {{ seleccionado.fecha_fin || 'Sin fecha' }}</dd></div>
      </dl>
    </section>
  </div>
</template>
