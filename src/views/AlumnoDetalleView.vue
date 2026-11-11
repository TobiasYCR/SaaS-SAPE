<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import FormAlumno from '../components/alumnos/FormAlumno.vue'
import { aFormulario, guardarAlumno, nombreCompleto, quitarAlumno, reactivar } from '../components/alumnos/accionesAlumno'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { organizacion, rol } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { obtenerAlumno } from '../services/alumnosService'
import { listarConvenios } from '../services/conveniosService'
import { inscribirAlumno, listarInscripciones } from '../services/inscripcionesService'
import { formatearFecha } from '../utils/catalogos'
import { hayErrores, validarAlumno } from '../utils/validaciones'

// Función principal: desde el alumno se elige un convenio activo y se lo inscribe.
const route = useRoute()
const router = useRouter()
const id = route.params.id

const alumno = ref(null)
const inscripciones = ref([])
const convenios = ref([])
const convenioElegido = ref('')
const errorInscripcion = ref('')
const formulario = ref(null) // modificación: null = cerrado
const errores = ref({})

const carga = useOperacion()
const inscripcion = useOperacion()
const edicion = useOperacion()
const accion = useOperacion()

const esAdminEscuela = computed(() => rol.value === 'escuela_admin')
const puedeInscribir = computed(() => esAdminEscuela.value && alumno.value?.activo)
// Convenios activos en los que el alumno todavía no está inscripto
const disponibles = computed(() => {
  const inscriptos = new Set(inscripciones.value.map((i) => i.convenio_id))
  return convenios.value.filter((c) => !inscriptos.has(c.id))
})

async function cargar() {
  const res = await carga.ejecutar(() => Promise.all([
    obtenerAlumno(id),
    listarInscripciones({ alumnoId: id }),
    listarConvenios({ estado: 'activo' }),
  ]))
  if (!res) return
  ;[alumno.value, inscripciones.value, convenios.value] = res
}

async function inscribir() {
  errorInscripcion.value = convenioElegido.value ? '' : 'Elegí un convenio activo.'
  if (errorInscripcion.value) return
  const nueva = await inscripcion.ejecutar(() => inscribirAlumno(convenioElegido.value, id))
  if (nueva) router.push({ path: `/inscripciones/${nueva.id}`, query: { nueva: '1' } })
}

function modificar() {
  formulario.value = aFormulario(alumno.value)
  errores.value = {}
  edicion.limpiar()
}

// Mismas reglas que el alta: validarAlumno en pantalla y CHECK/UNIQUE en la base
async function guardar() {
  errores.value = validarAlumno(formulario.value)
  if (hayErrores(errores.value)) return
  const guardado = await guardarAlumno(edicion, { id, escuelaId: organizacion.value.id, formulario: formulario.value })
  if (!guardado) return
  alumno.value = guardado
  formulario.value = null
  accion.limpiar()
  accion.exito.value = edicion.exito.value
}

async function quitar() {
  const resultado = await quitarAlumno(accion, alumno.value, inscripciones.value.length)
  if (resultado === 'eliminado') router.replace({ path: '/alumnos', query: { eliminado: nombreCompleto(alumno.value) } })
  else if (resultado === 'baja') alumno.value = { ...alumno.value, activo: false }
}

async function reactivarAlumno() {
  const actualizado = await reactivar(accion, alumno.value)
  if (actualizado) alumno.value = actualizado
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div>
      <p><RouterLink class="link-accion" to="/alumnos">← Alumnos</RouterLink></p>
      <h2>{{ alumno ? `${alumno.apellido}, ${alumno.nombre}` : 'Alumno' }}</h2>
    </div>
    <EstadoBadge v-if="alumno" :estado="alumno.activo ? 'activo_alumno' : 'inactivo'" :etiqueta="alumno.activo ? 'Activo' : 'De baja'" />
  </section>

  <AvisoOperacion :cargando="carga.cargando.value" texto-cargando="Cargando alumno..." :error="carga.error.value" />
  <AvisoOperacion :error="accion.error.value" :exito="accion.exito.value" />

  <template v-if="alumno">
    <form v-if="formulario" class="panel formulario seccion" novalidate @submit.prevent="guardar">
      <div class="seccion-titulo"><h3>Modificar alumno</h3></div>
      <FormAlumno v-model="formulario" :errores="errores" />
      <AvisoOperacion :error="edicion.error.value" />
      <div class="acciones acciones--fin">
        <button class="filter-button" type="button" @click="formulario = null">Cancelar</button>
        <button class="primary-button" type="submit" :disabled="edicion.cargando.value">{{ edicion.cargando.value ? 'Guardando...' : 'Guardar cambios' }}</button>
      </div>
    </form>

    <section v-else class="panel seccion">
      <dl class="detalle">
        <div><dt>DNI</dt><dd>{{ alumno.dni }}</dd></div>
        <div><dt>Curso</dt><dd>{{ alumno.curso ? `${alumno.curso}° ${alumno.division || ''}` : '—' }}</dd></div>
        <div><dt>Especialidad</dt><dd>{{ alumno.especialidad || '—' }}</dd></div>
        <div><dt>Nacimiento</dt><dd>{{ formatearFecha(alumno.fecha_nacimiento) }}</dd></div>
        <div><dt>Email</dt><dd>{{ alumno.email || '—' }}</dd></div>
        <div><dt>Teléfono</dt><dd>{{ alumno.telefono || '—' }}</dd></div>
        <div><dt>Responsable</dt><dd>{{ alumno.responsable_nombre || '—' }}{{ alumno.responsable_telefono ? ` · ${alumno.responsable_telefono}` : '' }}</dd></div>
      </dl>
      <div v-if="esAdminEscuela" class="acciones" style="margin-top:18px">
        <button class="secondary-button" type="button" @click="modificar">Modificar datos</button>
        <button v-if="alumno.activo" class="boton-peligro" type="button" :disabled="accion.cargando.value" @click="quitar">{{ inscripciones.length ? 'Dar de baja' : 'Eliminar' }}</button>
        <button v-else class="secondary-button" type="button" :disabled="accion.cargando.value" @click="reactivarAlumno">Reactivar</button>
      </div>
    </section>

    <section class="panel seccion">
      <div class="seccion-titulo"><h3>Inscribir en una pasantía</h3></div>
      <p v-if="!alumno.activo" class="aviso aviso--info">El alumno está dado de baja. Reactivalo para poder inscribirlo.</p>
      <p v-else-if="rol !== 'escuela_admin'" class="aviso aviso--info">Solo el administrador de la escuela inscribe alumnos.</p>
      <p v-else-if="!disponibles.length" class="aviso aviso--info">
        No hay convenios activos disponibles para este alumno. Los convenios se activan cuando una empresa se postula, la escuela acepta y se configuran los requisitos.
        <RouterLink class="link-accion" to="/convenios">Ver convenios</RouterLink>
      </p>
      <form v-if="puedeInscribir && disponibles.length" class="formulario" novalidate @submit.prevent="inscribir">
        <label class="campo" :class="{ 'campo--invalido': errorInscripcion }">
          <span>Convenio activo<span class="obligatorio" aria-hidden="true">*</span></span>
          <select v-model="convenioElegido">
            <option value="">Elegí un convenio</option>
            <option v-for="c in disponibles" :key="c.id" :value="c.id">
              {{ c.empresa?.nombre_fantasia || c.empresa?.razon_social }} — {{ c.area }} ({{ c.ciclo_lectivo }}, {{ c.cupos }} cupos)
            </option>
          </select>
          <small v-if="errorInscripcion" class="campo-error" role="alert">{{ errorInscripcion }}</small>
          <small v-else class="campo-ayuda">La inscripción se crea en borrador. En el paso siguiente completás los datos que pide el convenio y la enviás a la empresa.</small>
        </label>
        <AvisoOperacion :error="inscripcion.error.value" />
        <div class="acciones acciones--fin">
          <button class="primary-button" type="submit" :disabled="inscripcion.cargando.value">{{ inscripcion.cargando.value ? 'Inscribiendo...' : 'Inscribir y completar datos' }}</button>
        </div>
      </form>
    </section>

    <section class="panel seccion">
      <div class="seccion-titulo"><h3>Historial de pasantías</h3></div>
      <p v-if="!inscripciones.length" class="vacio">El alumno todavía no tiene inscripciones.</p>
      <div v-else class="table-wrap">
        <table class="tabla" style="min-width:560px">
          <thead><tr><th>EMPRESA</th><th>ÁREA</th><th>PERÍODO</th><th>ESTADO</th><th></th></tr></thead>
          <tbody>
            <tr v-for="i in inscripciones" :key="i.id">
              <td><strong>{{ i.convenio?.empresa?.nombre_fantasia || i.convenio?.empresa?.razon_social }}</strong></td>
              <td>{{ i.convenio?.area || '—' }}</td>
              <td>{{ formatearFecha(i.fecha_inicio) }} – {{ formatearFecha(i.fecha_fin) }}</td>
              <td><EstadoBadge :estado="i.estado" /></td>
              <td><RouterLink class="link-accion" :to="`/inscripciones/${i.id}`">Ver →</RouterLink></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </template>
</template>
