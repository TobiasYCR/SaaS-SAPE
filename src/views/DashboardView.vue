<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { esEscuela, perfil, rol } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { listarAlumnos } from '../services/alumnosService'
import { listarConvenios } from '../services/conveniosService'
import { listarInscripciones } from '../services/inscripcionesService'
import { listarPasantiasConSeguimientos } from '../services/seguimientosService'
import { formatearFecha } from '../utils/catalogos'

const convenios = ref([])
const inscripciones = ref([])
const pasantias = ref([])
const alumnos = ref(0)
const { cargando, error, ejecutar } = useOperacion()

const contar = (lista, estados) => lista.filter((x) => estados.includes(x.estado)).length
const nombre = computed(() => (perfil.value?.nombre_completo || '').split(' ')[0])

const tarjetas = computed(() => {
  const base = [
    { label: 'Convenios activos', value: contar(convenios.value, ['activo']), icon: '▤', tone: 'violet', to: '/convenios' },
    { label: 'Pasantías en curso', value: contar(inscripciones.value, ['en_curso']), icon: '◷', tone: 'green', to: '/seguimientos' },
  ]
  return esEscuela.value
    ? [{ label: 'Alumnos activos', value: alumnos.value, icon: '♙', tone: 'blue', to: '/alumnos' }, ...base,
      { label: 'Postulaciones por responder', value: contar(convenios.value, ['postulado']), icon: '✓', tone: 'orange', to: '/convenios' }]
    : [{ label: 'Postulaciones enviadas', value: contar(convenios.value, ['postulado']), icon: '✓', tone: 'blue', to: '/convenios' }, ...base,
      { label: 'Inscripciones por responder', value: contar(inscripciones.value, ['enviada']), icon: '!', tone: 'orange', to: '/inscripciones' }]
})

// Tareas pendientes según el rol
const pendientes = computed(() => {
  const lista = []
  const admin = rol.value?.endsWith('_admin')
  if (admin && esEscuela.value) {
    convenios.value.filter((c) => c.estado === 'postulado').forEach((c) => lista.push({ texto: `${c.empresa?.nombre_fantasia || c.empresa?.razon_social} se postuló (${c.area})`, to: `/convenios/${c.id}`, estado: c.estado }))
    inscripciones.value.filter((i) => i.estado === 'borrador').forEach((i) => lista.push({ texto: `Completar y enviar la inscripción de ${i.alumno?.apellido}, ${i.alumno?.nombre}`, to: `/inscripciones/${i.id}`, estado: i.estado }))
  }
  if (admin && !esEscuela.value) {
    inscripciones.value.filter((i) => i.estado === 'enviada').forEach((i) => lista.push({ texto: `Responder la inscripción de ${i.alumno?.apellido}, ${i.alumno?.nombre}`, to: `/inscripciones/${i.id}`, estado: i.estado }))
  }
  if (admin) {
    convenios.value.filter((c) => c.estado === 'aceptado').forEach((c) => lista.push({ texto: `Configurar requisitos y activar: ${c.area}`, to: `/convenios/${c.id}`, estado: c.estado }))
  }
  return lista
})

const proximos = computed(() => pasantias.value
  .map((p) => ({ ...p, proxima: [...(p.seguimientos || [])].sort((a, b) => b.fecha.localeCompare(a.fecha))[0]?.proxima_fecha }))
  .filter((p) => p.proxima)
  .sort((a, b) => a.proxima.localeCompare(b.proxima))
  .slice(0, 5))

async function cargar() {
  const res = await ejecutar(() => Promise.all([
    listarConvenios(), listarInscripciones(), listarPasantiasConSeguimientos(['en_curso']),
    esEscuela.value ? listarAlumnos({ activos: true }) : Promise.resolve([]),
  ]))
  if (!res) return
  ;[convenios.value, inscripciones.value, pasantias.value] = res
  alumnos.value = res[3].length
}

onMounted(cargar)
</script>

<template>
  <section class="welcome-row">
    <div><h2>Hola{{ nombre ? `, ${nombre}` : '' }}</h2><p>Este es el estado de tu {{ esEscuela ? 'escuela' : 'empresa' }} hoy.</p></div>
    <RouterLink v-if="rol === 'empresa_admin'" class="primary-button" to="/escuelas">+ Postularse a una escuela</RouterLink>
    <RouterLink v-else-if="rol === 'escuela_admin'" class="primary-button" to="/alumnos">Gestionar alumnos</RouterLink>
  </section>

  <AvisoOperacion :cargando="cargando" texto-cargando="Cargando resumen..." :error="error" />

  <section class="stats-grid">
    <RouterLink v-for="t in tarjetas" :key="t.label" :to="t.to" class="stat-card" style="text-decoration:none;color:inherit">
      <div class="stat-head"><span>{{ t.label }}</span><span class="stat-icon" :class="`tone-${t.tone}`">{{ t.icon }}</span></div>
      <div class="stat-value">{{ t.value }}</div>
    </RouterLink>
  </section>

  <section class="dashboard-grid">
    <article class="panel">
      <div class="panel-heading"><div><p class="eyebrow">PENDIENTES</p><h3>Qué hay que hacer</h3></div></div>
      <p v-if="!pendientes.length" class="vacio">No hay tareas pendientes.</p>
      <ul v-else class="lista-seguimientos" style="margin-top:16px">
        <li v-for="p in pendientes" :key="p.to + p.texto"><RouterLink class="cabecera" :to="p.to" style="text-decoration:none;margin:0"><span>{{ p.texto }}</span><EstadoBadge :estado="p.estado" /></RouterLink></li>
      </ul>
    </article>
    <article class="panel">
      <div class="panel-heading"><div><p class="eyebrow">AGENDA</p><h3>Próximos seguimientos</h3></div></div>
      <p v-if="!proximos.length" class="vacio">No hay seguimientos programados.</p>
      <ul v-else class="lista-seguimientos" style="margin-top:16px">
        <li v-for="p in proximos" :key="p.id"><RouterLink class="cabecera" :to="`/inscripciones/${p.id}`" style="text-decoration:none;margin:0"><span>{{ p.alumno?.apellido }}, {{ p.alumno?.nombre }}</span><span>{{ formatearFecha(p.proxima) }}</span></RouterLink></li>
      </ul>
      <RouterLink class="secondary-button" to="/seguimientos" style="display:inline-block;margin-top:14px">Ver seguimientos</RouterLink>
    </article>
  </section>
</template>
