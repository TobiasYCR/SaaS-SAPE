<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import FormAlumno from '../components/alumnos/FormAlumno.vue'
import { aFormulario, cantidadInscripciones, formularioVacio, guardarAlumno, nombreCompleto, quitarAlumno, reactivar } from '../components/alumnos/accionesAlumno'
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
const formulario = ref(null) // null = cerrado
const editandoId = ref(null)
const errores = ref({})
const ultimoCreado = ref(null) // para ofrecer el paso siguiente: inscribirlo

// Solo el administrador modifica; el tutor consulta. La base aplica la misma regla (RLS).
const puedeEditar = computed(() => rol.value === 'escuela_admin')
const listado = useOperacion()
const guardado = useOperacion()
const accion = useOperacion()

async function cargar() {
  const activos = { activos: true, inactivos: false, todos: null }[estado.value]
  const lista = await listado.ejecutar(() => listarAlumnos({ busqueda: busqueda.value, curso: curso.value, activos, orden: orden.value }))
  if (lista) alumnos.value = lista
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
    <button v-if="puedeEditar && !formulario" class="primary-button" type="button" @click="nuevo">+ Nuevo alumno</button>
  </section>

  <p v-if="!puedeEditar" class="aviso aviso--info">Tu rol es de consulta: podés ver los alumnos, pero solo el administrador de la escuela los carga, modifica o da de baja.</p>
  <AvisoOperacion :error="accion.error.value" :exito="accion.exito.value" />
  <p v-if="ultimoCreado && accion.exito.value" class="aviso aviso--info">
    Siguiente paso: <RouterLink class="link-accion" :to="`/alumnos/${ultimoCreado.id}`">inscribir a {{ ultimoCreado.nombre }} en una pasantía →</RouterLink>
  </p>

  <form v-if="formulario" class="panel formulario seccion" novalidate @submit.prevent="guardar">
    <div class="seccion-titulo"><h3>{{ editandoId ? 'Modificar alumno' : 'Nuevo alumno' }}</h3></div>
    <FormAlumno v-model="formulario" :errores="errores" />
    <AvisoOperacion :error="guardado.error.value" />
    <div class="acciones acciones--fin">
      <button class="filter-button" type="button" @click="formulario = null">Cancelar</button>
      <button class="primary-button" type="submit" :disabled="guardado.cargando.value">{{ guardado.cargando.value ? 'Guardando...' : 'Guardar' }}</button>
    </div>
  </form>

  <section class="panel table-panel">
    <form class="filtros" role="search" @submit.prevent="cargar">
      <label class="search-field">⌕<input v-model="busqueda" placeholder="Buscar por apellido, nombre o DNI" aria-label="Buscar alumnos" /></label>
      <select v-model="curso" aria-label="Filtrar por curso" @change="cargar"><option value="">Todos los cursos</option><option v-for="n in 7" :key="n" :value="n">{{ n }}° año</option></select>
      <select v-model="estado" aria-label="Filtrar por estado" @change="cargar"><option value="activos">Activos</option><option value="inactivos">Dados de baja</option><option value="todos">Todos</option></select>
      <select v-model="orden" aria-label="Ordenar por" @change="cargar"><option v-for="(o, clave) in ORDEN_ALUMNOS" :key="clave" :value="clave">Orden: {{ o.etiqueta }}</option></select>
      <button class="filter-button" type="submit" :disabled="listado.cargando.value">Buscar</button>
    </form>
    <div style="padding:0 20px"><AvisoOperacion :cargando="listado.cargando.value" texto-cargando="Cargando alumnos..." :error="listado.error.value" /></div>
    <p v-if="!listado.cargando.value && !alumnos.length && !listado.error.value" class="vacio">No hay alumnos que coincidan con los filtros.</p>
    <div v-else-if="alumnos.length" class="table-wrap">
      <table class="tabla">
        <thead><tr><th>ALUMNO</th><th>DNI</th><th>CURSO</th><th>ESPECIALIDAD</th><th>INSCRIPCIONES</th><th>ESTADO</th><th>ACCIONES</th></tr></thead>
        <tbody>
          <tr v-for="a in alumnos" :key="a.id">
            <td><RouterLink class="link-accion" :to="`/alumnos/${a.id}`"><strong>{{ nombreCompleto(a) }}</strong></RouterLink><small>Nac.: {{ formatearFecha(a.fecha_nacimiento) }}</small></td>
            <td>{{ a.dni }}</td>
            <td>{{ a.curso ? `${a.curso}° ${a.division || ''}` : '—' }}</td>
            <td>{{ a.especialidad || '—' }}</td>
            <td>{{ cantidadInscripciones(a) }}</td>
            <td><EstadoBadge :estado="a.activo ? 'activo_alumno' : 'inactivo'" :etiqueta="a.activo ? 'Activo' : 'De baja'" /></td>
            <td>
              <div class="acciones">
                <RouterLink class="product-action" :to="`/alumnos/${a.id}`">{{ puedeEditar && a.activo ? 'Inscribir' : 'Ver' }}</RouterLink>
                <template v-if="puedeEditar">
                  <button class="product-action" type="button" @click="editar(a)">Modificar</button>
                  <button v-if="a.activo" class="product-action product-action--danger" type="button" :disabled="accion.cargando.value" @click="quitar(a)">{{ cantidadInscripciones(a) ? 'Dar de baja' : 'Eliminar' }}</button>
                  <button v-else class="product-action" type="button" :disabled="accion.cargando.value" @click="reactivarAlumno(a)">Reactivar</button>
                </template>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <p class="contador">{{ alumnos.length }} alumno(s) · {{ ORDEN_ALUMNOS[orden].etiqueta }}</p>
    </div>
  </section>
</template>
