<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import CampoFormulario from '../components/common/CampoFormulario.vue'
import DatosPruebaBadge from '../components/common/DatosPruebaBadge.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import FormPropuesta from '../components/convenios/FormPropuesta.vue'
import { esAdmin, rol } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { listarAlumnos } from '../services/alumnosService'
import {
  actualizarPropuesta, actualizarRequisito, cambiarEstadoConvenio, crearRequisito, eliminarRequisito,
  listarRequisitos, obtenerConvenio, retirarPostulacion,
} from '../services/conveniosService'
import { inscribirAlumno, listarInscripciones } from '../services/inscripcionesService'
import { formatearFecha, TIPOS_REQUISITO } from '../utils/catalogos'
import { hayErrores, limpiarVacios, validarConvenio, validarRequisito } from '../utils/validaciones'

const route = useRoute()
const router = useRouter()
const id = route.params.id

const convenio = ref(null)
const requisitos = ref([])
const inscripciones = ref([])
const alumnosDisponibles = ref([])
const alumnoElegido = ref('')
const propuesta = ref(null)
const erroresPropuesta = ref({})
const requisito = ref(null)
const erroresRequisito = ref({})

const carga = useOperacion()
const accion = useOperacion()
const formReq = useOperacion()

const estado = computed(() => convenio.value?.estado)
const esEscuelaAdmin = computed(() => rol.value === 'escuela_admin')
const esEmpresaAdmin = computed(() => rol.value === 'empresa_admin')
const configurable = computed(() => estado.value === 'aceptado' && esAdmin.value)
const ocupados = computed(() => inscripciones.value.filter((i) => ['aceptada', 'en_curso', 'finalizada'].includes(i.estado)).length)

async function cargar() {
  const resultado = await carga.ejecutar(() => Promise.all([obtenerConvenio(id), listarRequisitos(id), listarInscripciones({ convenioId: id })]))
  if (!resultado) return
  ;[convenio.value, requisitos.value, inscripciones.value] = resultado
  if (esEscuelaAdmin.value && estado.value === 'activo') {
    const inscriptos = new Set(inscripciones.value.map((i) => i.alumno_id))
    alumnosDisponibles.value = (await listarAlumnos({ activos: true })).filter((a) => !inscriptos.has(a.id))
  }
}

const MENSAJES = {
  aceptado: 'Aceptaste la postulación. Ahora configuren los requisitos de inscripción.',
  rechazado: 'Rechazaste la postulación.',
  activo: 'El convenio está activo: la escuela ya puede inscribir alumnos.',
  finalizado: 'El convenio se finalizó.',
  cancelado: 'El convenio se canceló. Queda en el historial.',
}
const CONFIRMAR = {
  rechazado: '¿Rechazar la postulación de la empresa?',
  activo: 'Al activar el convenio se cierran los requisitos y ya no se pueden modificar. ¿Continuar?',
  finalizado: '¿Finalizar el convenio?',
  cancelado: '¿Cancelar el convenio? Queda registrado en el historial.',
}

async function cambiarEstado(nuevo) {
  if (CONFIRMAR[nuevo] && !window.confirm(CONFIRMAR[nuevo])) return
  if (nuevo === 'activo' && !requisitos.value.length && !window.confirm('El convenio no tiene requisitos. Los alumnos se van a poder inscribir sin cargar datos. ¿Activar igual?')) return
  const ok = await accion.ejecutar(() => cambiarEstadoConvenio(id, nuevo), MENSAJES[nuevo])
  if (ok) await cargar()
}

async function retirar() {
  if (!window.confirm('¿Retirar la postulación? Se elimina porque la escuela todavía no respondió.')) return
  const ok = await accion.ejecutar(() => retirarPostulacion(id).then(() => true))
  if (ok) router.replace('/convenios')
}

function editarPropuesta() {
  const c = convenio.value
  propuesta.value = { area: c.area ?? '', descripcion: c.descripcion ?? '', cupos: c.cupos, ciclo_lectivo: c.ciclo_lectivo, fecha_inicio: c.fecha_inicio ?? '', fecha_fin: c.fecha_fin ?? '' }
  erroresPropuesta.value = {}
}

async function guardarPropuesta() {
  erroresPropuesta.value = validarConvenio(propuesta.value)
  if (hayErrores(erroresPropuesta.value)) return
  const ok = await accion.ejecutar(() => actualizarPropuesta(id, limpiarVacios(propuesta.value)), 'Propuesta actualizada.')
  if (ok) {
    propuesta.value = null
    await cargar()
  }
}

function nuevoRequisito() {
  requisito.value = { id: null, nombre: '', descripcion: '', tipo: 'texto', obligatorio: true, orden: requisitos.value.length + 1 }
  erroresRequisito.value = {}
  formReq.limpiar()
}

function editarRequisito(r) {
  requisito.value = { ...r, descripcion: r.descripcion ?? '' }
  erroresRequisito.value = {}
  formReq.limpiar()
}

async function guardarRequisito() {
  erroresRequisito.value = validarRequisito(requisito.value)
  if (hayErrores(erroresRequisito.value)) return
  const { id: reqId, ...datos } = limpiarVacios(requisito.value)
  const ok = reqId
    ? await formReq.ejecutar(() => actualizarRequisito(reqId, datos), 'Requisito actualizado.')
    : await formReq.ejecutar(() => crearRequisito({ ...datos, convenio_id: id }), 'Requisito agregado.')
  if (ok) {
    requisito.value = null
    requisitos.value = await listarRequisitos(id)
  }
}

async function quitarRequisito(r) {
  if (!window.confirm(`¿Eliminar el requisito "${r.nombre}"?`)) return
  const ok = await formReq.ejecutar(() => eliminarRequisito(r.id).then(() => true), 'Requisito eliminado.')
  if (ok) requisitos.value = await listarRequisitos(id)
}

async function inscribir() {
  if (!alumnoElegido.value) return
  const nueva = await accion.ejecutar(() => inscribirAlumno(id, alumnoElegido.value))
  if (nueva) router.push(`/inscripciones/${nueva.id}`)
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div><p><RouterLink class="link-accion" to="/convenios">← Convenios</RouterLink></p><h2>{{ convenio?.area || 'Convenio' }}</h2></div>
    <EstadoBadge v-if="convenio" :estado="convenio.estado" />
  </section>

  <AvisoOperacion :cargando="carga.cargando.value" texto-cargando="Cargando convenio..." :error="carga.error.value" />
  <AvisoOperacion :error="accion.error.value" :exito="accion.exito.value" />

  <template v-if="convenio">
    <section class="panel seccion">
      <dl class="detalle">
        <div><dt>Empresa</dt><dd>{{ convenio.empresa?.nombre_fantasia || convenio.empresa?.razon_social }} <DatosPruebaBadge v-if="convenio.empresa?.datos_prueba" /></dd></div>
        <div><dt>Escuela</dt><dd>{{ convenio.escuela?.nombre }} <DatosPruebaBadge v-if="convenio.escuela?.datos_prueba" /></dd></div>
        <div><dt>Ciclo lectivo</dt><dd>{{ convenio.ciclo_lectivo }}</dd></div>
        <div><dt>Cupos</dt><dd>{{ ocupados }} ocupados de {{ convenio.cupos }}</dd></div>
        <div><dt>Período</dt><dd>{{ formatearFecha(convenio.fecha_inicio) }} al {{ formatearFecha(convenio.fecha_fin) }}</dd></div>
        <div><dt>Postulado</dt><dd>{{ formatearFecha(convenio.creado_en) }}</dd></div>
        <div><dt>Respuesta de la escuela</dt><dd>{{ formatearFecha(convenio.respondido_en) }}</dd></div>
        <div class="campo--ancho"><dt>Propuesta</dt><dd>{{ convenio.descripcion || 'Sin descripción.' }}</dd></div>
      </dl>

      <div class="acciones" style="margin-top:18px">
        <template v-if="estado === 'postulado' && esEscuelaAdmin">
          <button class="primary-button" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('aceptado')">Aceptar postulación</button>
          <button class="boton-peligro" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('rechazado')">Rechazar</button>
        </template>
        <template v-if="esEmpresaAdmin && ['postulado', 'aceptado'].includes(estado) && !propuesta">
          <button class="secondary-button" type="button" @click="editarPropuesta">Editar propuesta</button>
        </template>
        <button v-if="estado === 'postulado' && esEmpresaAdmin" class="boton-peligro" type="button" :disabled="accion.cargando.value" @click="retirar">Retirar postulación</button>
        <button v-if="configurable" class="primary-button" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('activo')">Cerrar requisitos y activar</button>
        <button v-if="estado === 'activo' && esAdmin" class="secondary-button" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('finalizado')">Finalizar convenio</button>
        <button v-if="['aceptado', 'activo'].includes(estado) && esAdmin" class="boton-peligro" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('cancelado')">Cancelar convenio</button>
      </div>
    </section>

    <form v-if="propuesta" class="panel formulario seccion" novalidate @submit.prevent="guardarPropuesta">
      <div class="seccion-titulo"><h3>Editar propuesta</h3></div>
      <FormPropuesta v-model="propuesta" :errores="erroresPropuesta" :con-ciclo="false" />
      <div class="acciones acciones--fin">
        <button class="filter-button" type="button" @click="propuesta = null">Cancelar</button>
        <button class="primary-button" type="submit" :disabled="accion.cargando.value">Guardar propuesta</button>
      </div>
    </form>

    <section class="panel seccion">
      <div class="seccion-titulo">
        <h3>Requisitos de inscripción</h3>
        <button v-if="configurable && !requisito" class="secondary-button boton-chico" type="button" @click="nuevoRequisito">+ Agregar requisito</button>
      </div>
      <p v-if="estado === 'postulado'" class="aviso aviso--info">Los requisitos se configuran cuando la escuela acepta la postulación.</p>
      <p v-else-if="estado === 'aceptado'" class="aviso aviso--info">Etapa de configuración: escuela y empresa definen qué datos se piden para inscribir alumnos. Al activar el convenio quedan fijos.</p>
      <AvisoOperacion :error="formReq.error.value" :exito="formReq.exito.value" />

      <form v-if="requisito" class="formulario seccion" novalidate @submit.prevent="guardarRequisito">
        <div class="form-grid">
          <CampoFormulario etiqueta="Nombre" :error="erroresRequisito.nombre" obligatorio><input v-model="requisito.nombre" maxlength="120" placeholder="Certificado médico" /></CampoFormulario>
          <CampoFormulario etiqueta="Tipo de dato" :error="erroresRequisito.tipo" obligatorio>
            <select v-model="requisito.tipo"><option v-for="(etiqueta, valor) in TIPOS_REQUISITO" :key="valor" :value="valor">{{ etiqueta }}</option></select>
          </CampoFormulario>
          <CampoFormulario etiqueta="Aclaración" ancho><input v-model="requisito.descripcion" maxlength="250" /></CampoFormulario>
          <CampoFormulario etiqueta="Orden"><input v-model.number="requisito.orden" type="number" min="0" max="99" /></CampoFormulario>
          <label class="campo-check"><input v-model="requisito.obligatorio" type="checkbox" /> Obligatorio para enviar la inscripción</label>
        </div>
        <div class="acciones acciones--fin">
          <button class="filter-button" type="button" @click="requisito = null">Cancelar</button>
          <button class="primary-button" type="submit" :disabled="formReq.cargando.value">{{ requisito.id ? 'Guardar requisito' : 'Agregar requisito' }}</button>
        </div>
      </form>

      <p v-if="!requisitos.length && estado !== 'postulado'" class="vacio">Sin requisitos cargados.</p>
      <div v-else-if="requisitos.length" class="table-wrap">
        <table class="tabla" style="min-width:560px">
          <thead><tr><th>#</th><th>REQUISITO</th><th>TIPO</th><th>OBLIGATORIO</th><th v-if="configurable"></th></tr></thead>
          <tbody>
            <tr v-for="r in requisitos" :key="r.id">
              <td>{{ r.orden }}</td>
              <td><strong>{{ r.nombre }}</strong><small v-if="r.descripcion">{{ r.descripcion }}</small></td>
              <td>{{ TIPOS_REQUISITO[r.tipo] }}</td>
              <td>{{ r.obligatorio ? 'Sí' : 'No' }}</td>
              <td v-if="configurable"><div class="acciones"><button class="product-action" type="button" @click="editarRequisito(r)">Editar</button><button class="product-action product-action--danger" type="button" @click="quitarRequisito(r)">Eliminar</button></div></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section class="panel seccion">
      <div class="seccion-titulo"><h3>Alumnos inscriptos</h3></div>
      <form v-if="esEscuelaAdmin && estado === 'activo'" class="acciones seccion" @submit.prevent="inscribir">
        <select v-model="alumnoElegido" class="filter-button" aria-label="Alumno a inscribir" style="flex:1 1 260px;min-height:44px">
          <option value="">Elegí un alumno para inscribir</option>
          <option v-for="a in alumnosDisponibles" :key="a.id" :value="a.id">{{ a.apellido }}, {{ a.nombre }} — DNI {{ a.dni }}</option>
        </select>
        <button class="primary-button" type="submit" :disabled="!alumnoElegido || accion.cargando.value">Inscribir</button>
      </form>
      <p v-if="esEscuelaAdmin && estado === 'activo' && !alumnosDisponibles.length" class="aviso aviso--info">Todos los alumnos activos ya están inscriptos. <RouterLink class="link-accion" to="/alumnos">Cargar un alumno nuevo</RouterLink></p>
      <p v-else-if="estado !== 'activo'" class="aviso aviso--info">Las inscripciones se habilitan cuando el convenio está activo.</p>
      <p v-if="!inscripciones.length" class="vacio">Todavía no hay alumnos inscriptos.</p>
      <div v-else class="table-wrap">
        <table class="tabla" style="min-width:520px">
          <thead><tr><th>ALUMNO</th><th>DNI</th><th>ESTADO</th><th></th></tr></thead>
          <tbody>
            <tr v-for="i in inscripciones" :key="i.id">
              <td><strong>{{ i.alumno?.apellido }}, {{ i.alumno?.nombre }}</strong></td>
              <td>{{ i.alumno?.dni }}</td>
              <td><EstadoBadge :estado="i.estado" /></td>
              <td><RouterLink class="link-accion" :to="`/inscripciones/${i.id}`">Ver →</RouterLink></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </template>
</template>
