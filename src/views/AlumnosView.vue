<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import CampoFormulario from '../components/common/CampoFormulario.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { organizacion, rol } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { actualizarAlumno, crearAlumno, darDeBajaAlumno, eliminarAlumno, listarAlumnos, reactivarAlumno } from '../services/alumnosService'
import { formatearFecha } from '../utils/catalogos'
import { hayErrores, limpiarVacios, validarAlumno } from '../utils/validaciones'

const VACIO = { nombre: '', apellido: '', dni: '', fecha_nacimiento: '', curso: '', division: '', especialidad: '', email: '', telefono: '', responsable_nombre: '', responsable_telefono: '' }

const alumnos = ref([])
const busqueda = ref('')
const curso = ref('')
const estado = ref('activos')
const formulario = ref(null) // null = cerrado
const editandoId = ref(null)
const errores = ref({})
const ultimoCreado = ref(null) // para ofrecer el paso siguiente: inscribirlo

const puedeEditar = computed(() => rol.value === 'escuela_admin')
const listado = useOperacion()
const guardado = useOperacion()
const accion = useOperacion()

const cantidadInscripciones = (a) => a.inscripciones?.[0]?.count ?? 0

async function cargar() {
  const activos = { activos: true, inactivos: false, todos: null }[estado.value]
  const lista = await listado.ejecutar(() => listarAlumnos({ busqueda: busqueda.value, curso: curso.value, activos }))
  if (lista) alumnos.value = lista
}

function nuevo() {
  ultimoCreado.value = null
  editandoId.value = null
  formulario.value = { ...VACIO }
  errores.value = {}
  guardado.limpiar()
}

function editar(alumno) {
  editandoId.value = alumno.id
  formulario.value = Object.fromEntries(Object.keys(VACIO).map((k) => [k, alumno[k] ?? '']))
  errores.value = {}
  guardado.limpiar()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function guardar() {
  errores.value = validarAlumno(formulario.value)
  if (hayErrores(errores.value)) return
  const datos = limpiarVacios(formulario.value)
  datos.curso = datos.curso ? Number(datos.curso) : null
  const nombre = `${datos.apellido}, ${datos.nombre}`
  const ok = editandoId.value
    ? await guardado.ejecutar(() => actualizarAlumno(editandoId.value, datos), `Se actualizaron los datos de ${nombre}.`)
    : await guardado.ejecutar(() => crearAlumno({ ...datos, escuela_id: organizacion.value.id }), `${nombre} se agregó a la escuela.`)
  if (ok) {
    ultimoCreado.value = editandoId.value ? null : ok
    formulario.value = null
    accion.exito.value = guardado.exito.value
    await cargar()
  }
}

// Con inscripciones: baja lógica para conservar el historial. Sin inscripciones: se puede eliminar.
async function quitar(alumno) {
  ultimoCreado.value = null
  const nombre = `${alumno.apellido}, ${alumno.nombre}`
  if (cantidadInscripciones(alumno) > 0) {
    if (!window.confirm(`${nombre} tiene inscripciones. Se va a dar de baja (queda en el historial y se puede reactivar). ¿Continuar?`)) return
    await accion.ejecutar(() => darDeBajaAlumno(alumno.id), `${nombre} quedó dado de baja.`)
  } else {
    if (!window.confirm(`¿Eliminar definitivamente a ${nombre}? No tiene inscripciones.`)) return
    await accion.ejecutar(() => eliminarAlumno(alumno.id), `${nombre} se eliminó.`)
  }
  await cargar()
}

async function reactivar(alumno) {
  ultimoCreado.value = null
  await accion.ejecutar(() => reactivarAlumno(alumno.id), `${alumno.apellido}, ${alumno.nombre} volvió a estar activo.`)
  await cargar()
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div><p>Estudiantes de la escuela que pueden hacer pasantías</p><h2>Alumnos</h2></div>
    <button v-if="puedeEditar && !formulario" class="primary-button" type="button" @click="nuevo">+ Nuevo alumno</button>
  </section>

  <AvisoOperacion :error="accion.error.value" :exito="accion.exito.value" />
  <p v-if="ultimoCreado && accion.exito.value" class="aviso aviso--info">
    Siguiente paso: <RouterLink class="link-accion" :to="`/alumnos/${ultimoCreado.id}`">inscribir a {{ ultimoCreado.nombre }} en una pasantía →</RouterLink>
  </p>

  <form v-if="formulario" class="panel formulario seccion" novalidate @submit.prevent="guardar">
    <div class="seccion-titulo"><h3>{{ editandoId ? 'Editar alumno' : 'Nuevo alumno' }}</h3></div>
    <div class="form-grid form-grid--3">
      <CampoFormulario etiqueta="Apellido" :error="errores.apellido" obligatorio><input v-model="formulario.apellido" maxlength="80" autocomplete="off" /></CampoFormulario>
      <CampoFormulario etiqueta="Nombre" :error="errores.nombre" obligatorio><input v-model="formulario.nombre" maxlength="80" autocomplete="off" /></CampoFormulario>
      <CampoFormulario etiqueta="DNI" :error="errores.dni" ayuda="Sin puntos" obligatorio><input v-model="formulario.dni" inputmode="numeric" maxlength="8" /></CampoFormulario>
      <CampoFormulario etiqueta="Fecha de nacimiento" :error="errores.fecha_nacimiento"><input v-model="formulario.fecha_nacimiento" type="date" /></CampoFormulario>
      <CampoFormulario etiqueta="Curso" :error="errores.curso">
        <select v-model="formulario.curso"><option value="">—</option><option v-for="n in 7" :key="n" :value="n">{{ n }}°</option></select>
      </CampoFormulario>
      <CampoFormulario etiqueta="División" :error="errores.division"><input v-model="formulario.division" maxlength="10" /></CampoFormulario>
      <CampoFormulario etiqueta="Especialidad" :error="errores.especialidad"><input v-model="formulario.especialidad" maxlength="80" /></CampoFormulario>
      <CampoFormulario etiqueta="Email" :error="errores.email"><input v-model="formulario.email" type="email" maxlength="150" /></CampoFormulario>
      <CampoFormulario etiqueta="Teléfono" :error="errores.telefono"><input v-model="formulario.telefono" type="tel" maxlength="40" /></CampoFormulario>
      <CampoFormulario etiqueta="Responsable (madre, padre o tutor)" :error="errores.responsable_nombre"><input v-model="formulario.responsable_nombre" maxlength="120" /></CampoFormulario>
      <CampoFormulario etiqueta="Teléfono del responsable" :error="errores.responsable_telefono"><input v-model="formulario.responsable_telefono" type="tel" maxlength="40" /></CampoFormulario>
    </div>
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
      <button class="filter-button" type="submit" :disabled="listado.cargando.value">Buscar</button>
    </form>
    <div style="padding:0 20px"><AvisoOperacion :cargando="listado.cargando.value" texto-cargando="Cargando alumnos..." :error="listado.error.value" /></div>
    <p v-if="!listado.cargando.value && !alumnos.length && !listado.error.value" class="vacio">No hay alumnos que coincidan con los filtros.</p>
    <div v-else-if="alumnos.length" class="table-wrap">
      <table class="tabla">
        <thead><tr><th>ALUMNO</th><th>DNI</th><th>CURSO</th><th>ESPECIALIDAD</th><th>INSCRIPCIONES</th><th>ESTADO</th><th v-if="puedeEditar">ACCIONES</th></tr></thead>
        <tbody>
          <tr v-for="a in alumnos" :key="a.id">
            <td><RouterLink class="link-accion" :to="`/alumnos/${a.id}`"><strong>{{ a.apellido }}, {{ a.nombre }}</strong></RouterLink><small>Nac.: {{ formatearFecha(a.fecha_nacimiento) }}</small></td>
            <td>{{ a.dni }}</td>
            <td>{{ a.curso ? `${a.curso}° ${a.division || ''}` : '—' }}</td>
            <td>{{ a.especialidad || '—' }}</td>
            <td>{{ cantidadInscripciones(a) }}</td>
            <td><EstadoBadge :estado="a.activo ? 'activo_alumno' : 'inactivo'" :etiqueta="a.activo ? 'Activo' : 'De baja'" /></td>
            <td v-if="puedeEditar">
              <div class="acciones">
                <RouterLink class="product-action" :to="`/alumnos/${a.id}`">Inscribir</RouterLink>
                <button class="product-action" type="button" @click="editar(a)">Editar</button>
                <button v-if="a.activo" class="product-action product-action--danger" type="button" :disabled="accion.cargando.value" @click="quitar(a)">{{ cantidadInscripciones(a) ? 'Dar de baja' : 'Eliminar' }}</button>
                <button v-else class="product-action" type="button" :disabled="accion.cargando.value" @click="reactivar(a)">Reactivar</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <p class="contador">{{ alumnos.length }} alumno(s)</p>
    </div>
  </section>
</template>
