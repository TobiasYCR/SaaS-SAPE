<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import FormAlumno from '../components/alumnos/FormAlumno.vue'
import { aFormulario, cantidadInscripciones, cantidadPlanes, formularioVacio, guardarAlumno, nombreCompleto, quitarAlumno, reactivar } from '../components/alumnos/accionesAlumno'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { organizacion, rol } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { listarAlumnos, ORDEN_ALUMNOS } from '../services/alumnosService'
import { formatearFecha } from '../utils/catalogos'
import { hayErrores, validarAlumno } from '../utils/validaciones'

const route = useRoute()

const alumnos = ref([])
const busqueda = ref('')
const curso = ref('')
const estado = ref('activos')
const orden = ref('apellido')
const porPagina = ref(5)
const pagina = ref(1)
const formulario = ref(null) // null = cerrado
const editandoId = ref(null)
const errores = ref({})
const ultimoCreado = ref(null) // para ofrecer el paso siguiente: inscribirlo

// Solo el administrador modifica; el tutor consulta. La base aplica la misma regla (RLS).
const puedeEditar = computed(() => rol.value === 'escuela_admin')
const listado = useOperacion()
const guardado = useOperacion()
const accion = useOperacion()

const totalPaginas = computed(() => Math.max(1, Math.ceil(alumnos.value.length / porPagina.value)))
const paginaActual = computed(() => Math.min(pagina.value, totalPaginas.value))
const alumnosPaginados = computed(() => {
  const inicio = (paginaActual.value - 1) * porPagina.value
  return alumnos.value.slice(inicio, inicio + porPagina.value)
})
const rangoMostrado = computed(() => {
  if (!alumnos.value.length) return { desde: 0, hasta: 0 }
  const desde = (paginaActual.value - 1) * porPagina.value + 1
  const hasta = Math.min(desde + porPagina.value - 1, alumnos.value.length)
  return { desde, hasta }
})

async function cargar() {
  const activos = { activos: true, inactivos: false, todos: null }[estado.value]
  const lista = await listado.ejecutar(() => listarAlumnos({ busqueda: busqueda.value, curso: curso.value, activos, orden: orden.value }))
  if (lista) {
    alumnos.value = lista
    pagina.value = 1
  }
}

function nuevo() {
  ultimoCreado.value = null
  editandoId.value = null
  formulario.value = formularioVacio()
  errores.value = {}
  guardado.limpiar()
}

function editar(alumno) {
  ultimoCreado.value = null
  editandoId.value = alumno.id
  formulario.value = aFormulario(alumno)
  errores.value = {}
  guardado.limpiar()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function guardar() {
  errores.value = validarAlumno(formulario.value)
  if (hayErrores(errores.value)) return
  const guardadoOk = await guardarAlumno(guardado, { id: editandoId.value, escuelaId: organizacion.value.id, formulario: formulario.value })
  if (!guardadoOk) return
  ultimoCreado.value = editandoId.value ? null : guardadoOk
  formulario.value = null
  accion.limpiar()
  accion.exito.value = guardado.exito.value
  await cargar()
}

async function quitar(alumno) {
  ultimoCreado.value = null
  if (await quitarAlumno(accion, alumno, cantidadInscripciones(alumno))) await cargar()
}

async function reactivarAlumno(alumno) {
  ultimoCreado.value = null
  if (await reactivar(accion, alumno)) await cargar()
}

onMounted(() => {
  // Mensaje que deja el detalle al eliminar un alumno
  if (route.query.eliminado) {
    accion.exito.value = `${route.query.eliminado} se eliminó.`
    // Se limpia la URL sin pasar por el router: cambiar la ruta recrearía la vista y perdería el mensaje
    window.history.replaceState(window.history.state, '', route.path)
  }
  cargar()
})
</script>

<template>
  <section class="page-intro">
    <div><p>Estudiantes de la escuela que pueden hacer pasantías</p><h2>Alumnos</h2></div>
    <button v-if="puedeEditar && !formulario" class="primary-button" type="button" @click="nuevo">+ Registrar Estudiantes ({{ alumnos.length }})</button>
  </section>

  <p v-if="!puedeEditar" class="aviso aviso--info">Tu rol es de consulta: podés ver los alumnos, pero solo el administrador de la escuela los carga, modifica o da de baja.</p>
  <AvisoOperacion :error="accion.error.value" :exito="accion.exito.value" />
  <p v-if="ultimoCreado && accion.exito.value" class="aviso aviso--info">
    Siguiente paso: <RouterLink class="link-accion" :to="`/alumnos/${ultimoCreado.id}`">inscribir a {{ ultimoCreado.nombre }} en una pasantía →</RouterLink>
  </p>

  <div v-if="formulario" class="modal-backdrop" @click.self="formulario = null">
    <section class="modal-card" role="dialog" aria-modal="true" aria-labelledby="alumno-modal-title">
      <header class="modal-header">
        <h2 id="alumno-modal-title">{{ editandoId ? 'Modificar estudiante de su nómina' : 'Registrar estudiante' }}</h2>
        <button class="modal-close" type="button" aria-label="Cerrar formulario" @click="formulario = null">CERRAR [×]</button>
      </header>
      <form class="modal-body formulario" novalidate @submit.prevent="guardar">
        <FormAlumno v-model="formulario" :errores="errores" />
        <AvisoOperacion :error="guardado.error.value" />
        <div class="acciones acciones--fin modal-actions">
          <button class="secondary-button" type="button" @click="formulario = null">Cancelar</button>
          <button class="primary-button" type="submit" :disabled="guardado.cargando.value">{{ guardado.cargando.value ? 'Guardando...' : 'Guardar estudiante' }}</button>
        </div>
      </form>
    </section>
  </div>

  <section class="panel table-panel">
    <form class="filtros" role="search" @submit.prevent="cargar">
      <label class="search-field">⌕<input v-model="busqueda" placeholder="Buscar por apellido, nombre o DNI" aria-label="Buscar alumnos" /></label>
      <select v-model="curso" aria-label="Filtrar por curso" @change="cargar"><option value="">Todos los cursos</option><option v-for="n in 7" :key="n" :value="n">{{ n }}° año</option></select>
      <select v-model="estado" aria-label="Filtrar por estado" @change="cargar"><option value="activos">Activos</option><option value="inactivos">Dados de baja</option><option value="todos">Todos</option></select>
      <select v-model="orden" aria-label="Ordenar por" @change="cargar"><option v-for="(o, clave) in ORDEN_ALUMNOS" :key="clave" :value="clave">Orden: {{ o.etiqueta }}</option></select>
      <select v-model.number="porPagina" aria-label="Mostrar estudiantes" @change="pagina = 1">
        <option :value="5">Mostrar 5 estudiantes</option>
        <option :value="10">Mostrar 10 estudiantes</option>
        <option :value="25">Mostrar 25 estudiantes</option>
        <option :value="50">Mostrar 50 estudiantes</option>
      </select>
      <button class="filter-button" type="submit" :disabled="listado.cargando.value">Buscar</button>
    </form>
    <div style="padding:0 20px"><AvisoOperacion :cargando="listado.cargando.value" texto-cargando="Cargando alumnos..." :error="listado.error.value" /></div>
    <p v-if="!listado.cargando.value && !alumnos.length && !listado.error.value" class="vacio">No hay alumnos que coincidan con los filtros.</p>
    <div v-else-if="alumnos.length" class="table-wrap">
      <table class="tabla">
        <thead><tr><th>ALUMNO</th><th>DOCUMENTO</th><th>CURSO</th><th>PLANES</th><th>NÓMINAS</th><th>CREADO EL</th><th>ESTADO</th><th>OPERACIONES</th></tr></thead>
        <tbody>
          <tr v-for="a in alumnosPaginados" :key="a.id">
            <td><RouterLink class="link-accion" :to="`/alumnos/${a.id}`"><strong>{{ nombreCompleto(a) }}</strong></RouterLink><small>Nac.: {{ formatearFecha(a.fecha_nacimiento) }}{{ a.especialidad ? ` · ${a.especialidad}` : '' }}</small></td>
            <td>{{ a.tipo_documento || 'DNI' }} {{ a.dni }}</td>
            <td>{{ a.curso ? `${a.curso}° ${a.division || ''}` : '—' }}</td>
            <td>{{ cantidadPlanes(a) }}</td>
            <td>{{ cantidadInscripciones(a) }}</td>
            <td>{{ formatearFecha(a.creado_en) }}</td>
            <td><EstadoBadge :estado="a.activo ? 'activo_alumno' : 'inactivo'" :etiqueta="a.activo ? 'Activo' : 'De baja'" /></td>
            <td>
              <div class="acciones">
                <RouterLink class="product-action" :to="`/alumnos/${a.id}`">{{ puedeEditar && a.activo ? 'Inscribir' : 'Ver' }}</RouterLink>
                <template v-if="puedeEditar">
                  <button class="product-action" type="button" @click="editar(a)">Modificar</button>
                  <button v-if="a.activo" class="product-action product-action--danger" type="button" :disabled="accion.cargando.value" @click="quitar(a)">{{ cantidadInscripciones(a) ? 'Desvincular' : 'Eliminar' }}</button>
                  <button v-else class="product-action" type="button" :disabled="accion.cargando.value" @click="reactivarAlumno(a)">Reactivar</button>
                </template>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <div class="paginacion">
        <p class="contador">Mostrando estudiantes del {{ rangoMostrado.desde }} al {{ rangoMostrado.hasta }} de un total de {{ alumnos.length }} estudiantes · {{ ORDEN_ALUMNOS[orden].etiqueta }}</p>
        <div v-if="totalPaginas > 1" class="acciones">
          <button class="filter-button" type="button" :disabled="paginaActual <= 1" @click="pagina = paginaActual - 1">Anterior</button>
          <span class="contador">Página {{ paginaActual }} / {{ totalPaginas }}</span>
          <button class="filter-button" type="button" :disabled="paginaActual >= totalPaginas" @click="pagina = paginaActual + 1">Siguiente</button>
        </div>
      </div>
    </div>
  </section>
</template>
