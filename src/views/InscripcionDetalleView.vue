<script setup>
import { computed, onMounted, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import CampoFormulario from '../components/common/CampoFormulario.vue'
import EstadoBadge from '../components/common/EstadoBadge.vue'
import { currentUser, esAdmin, rol } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { listarRequisitos } from '../services/conveniosService'
import {
  actualizarInscripcion, borrarDato, cambiarEstadoInscripcion, eliminarInscripcion, guardarDato,
  listarDatos, obtenerInscripcion, subirDocumento, urlDocumento,
} from '../services/inscripcionesService'
import { crearSeguimiento, eliminarSeguimiento, listarSeguimientos } from '../services/seguimientosService'
import { formatearFecha, hoy } from '../utils/catalogos'
import { hayErrores, limpiarVacios, validarInscripcion, validarSeguimiento, validarValorRequisito } from '../utils/validaciones'

const route = useRoute()
const router = useRouter()
const id = route.params.id

const inscripcion = ref(null)
const requisitos = ref([])
const valores = ref({})          // requisito_id -> { valor, archivo_ruta }
const archivos = ref({})         // requisito_id -> File
const erroresDatos = ref({})
const periodo = ref(null)
const erroresPeriodo = ref({})
const seguimientos = ref([])
const seguimiento = ref(null)
const erroresSeg = ref({})

const carga = useOperacion()
const accion = useOperacion()
const datosOp = useOperacion()
const segOp = useOperacion()

const estado = computed(() => inscripcion.value?.estado)
const esEscuelaAdmin = computed(() => rol.value === 'escuela_admin')
const esEmpresaAdmin = computed(() => rol.value === 'empresa_admin')
const editableDatos = computed(() => estado.value === 'borrador' && esEscuelaAdmin.value)
const faltantes = computed(() => requisitos.value.filter((r) => r.obligatorio && !valores.value[r.id]?.guardado).length)

async function cargar() {
  const res = await carga.ejecutar(async () => {
    const insc = await obtenerInscripcion(id)
    const [reqs, datos, segs] = await Promise.all([listarRequisitos(insc.convenio_id), listarDatos(id), listarSeguimientos(id)])
    return { insc, reqs, datos, segs }
  })
  if (!res) return
  inscripcion.value = res.insc
  requisitos.value = res.reqs
  seguimientos.value = res.segs
  valores.value = Object.fromEntries(res.reqs.map((r) => {
    const d = res.datos.find((x) => x.requisito_id === r.id)
    return [r.id, { valor: d?.valor ?? '', archivo_ruta: d?.archivo_ruta ?? null, guardado: Boolean(d) }]
  }))
  archivos.value = {}
}

async function guardarDatos() {
  erroresDatos.value = {}
  for (const r of requisitos.value) {
    const msg = r.tipo === 'archivo' ? '' : validarValorRequisito(r.tipo, valores.value[r.id].valor)
    if (msg) erroresDatos.value[r.id] = msg
  }
  if (hayErrores(erroresDatos.value)) return
  const ok = await datosOp.ejecutar(async () => {
    for (const r of requisitos.value) {
      const v = valores.value[r.id]
      if (r.tipo === 'archivo') {
        const archivo = archivos.value[r.id]
        if (archivo) {
          const ruta = await subirDocumento(inscripcion.value.convenio_id, id, archivo)
          await guardarDato(id, r.id, { archivo_ruta: ruta })
        }
      } else if (String(v.valor ?? '').trim() !== '') {
        await guardarDato(id, r.id, { valor: String(v.valor).trim() })
      } else if (v.guardado) {
        await borrarDato(id, r.id)
      }
    }
    return true
  }, 'Datos guardados.')
  if (ok) await cargar()
}

function elegirArchivo(reqId, evento) {
  const archivo = evento.target.files?.[0]
  erroresDatos.value[reqId] = ''
  if (!archivo) return
  if (!['application/pdf', 'image/jpeg', 'image/png'].includes(archivo.type)) erroresDatos.value[reqId] = 'Solo PDF, JPG o PNG.'
  else if (archivo.size > 10 * 1024 * 1024) erroresDatos.value[reqId] = 'El archivo no puede superar los 10 MB.'
  else archivos.value[reqId] = archivo
  if (erroresDatos.value[reqId]) evento.target.value = ''
}

async function verArchivo(ruta) {
  const url = await accion.ejecutar(() => urlDocumento(ruta))
  if (url) window.open(url, '_blank', 'noopener')
}

const MENSAJES = {
  enviada: 'Inscripción enviada. La empresa tiene que aceptarla o rechazarla.',
  aceptada: 'Inscripción aceptada.',
  rechazada: 'Inscripción rechazada.',
  en_curso: 'La pasantía está en curso. Ya se pueden registrar seguimientos.',
  finalizada: 'La pasantía finalizó.',
  cancelada: 'La inscripción se canceló. Queda en el historial.',
}
const CONFIRMAR = {
  enviada: '¿Enviar la inscripción a la empresa? Después ya no se pueden modificar los datos.',
  rechazada: '¿Rechazar la inscripción?',
  finalizada: '¿Marcar la pasantía como finalizada?',
  cancelada: '¿Cancelar la inscripción? Queda registrada en el historial.',
}

async function cambiarEstado(nuevo) {
  if (CONFIRMAR[nuevo] && !window.confirm(CONFIRMAR[nuevo])) return
  const ok = await accion.ejecutar(() => cambiarEstadoInscripcion(id, nuevo), MENSAJES[nuevo])
  if (ok) await cargar()
}

async function eliminarBorrador() {
  if (!window.confirm('¿Eliminar este borrador? Se borran también los datos cargados.')) return
  const ok = await accion.ejecutar(() => eliminarInscripcion(id).then(() => true))
  if (ok) router.replace(`/convenios/${inscripcion.value.convenio_id}`)
}

function editarPeriodo() {
  const i = inscripcion.value
  periodo.value = { fecha_inicio: i.fecha_inicio ?? '', fecha_fin: i.fecha_fin ?? '', horas_totales: i.horas_totales ?? '', observaciones: i.observaciones ?? '' }
  erroresPeriodo.value = {}
}

async function guardarPeriodo() {
  erroresPeriodo.value = validarInscripcion(periodo.value)
  if (hayErrores(erroresPeriodo.value)) return
  const datos = limpiarVacios(periodo.value)
  datos.horas_totales = datos.horas_totales ? Number(datos.horas_totales) : null
  const ok = await accion.ejecutar(() => actualizarInscripcion(id, datos), 'Período actualizado.')
  if (ok) {
    periodo.value = null
    await cargar()
  }
}

function nuevoSeguimiento() {
  seguimiento.value = { fecha: hoy(), progreso: '', observaciones: '', proxima_fecha: '' }
  erroresSeg.value = {}
  segOp.limpiar()
}

async function guardarSeguimiento() {
  erroresSeg.value = validarSeguimiento(seguimiento.value)
  if (hayErrores(erroresSeg.value)) return
  const datos = { ...limpiarVacios(seguimiento.value), inscripcion_id: id, progreso: Number(seguimiento.value.progreso) }
  const ok = await segOp.ejecutar(() => crearSeguimiento(datos), 'Seguimiento registrado.')
  if (ok) {
    seguimiento.value = null
    seguimientos.value = await listarSeguimientos(id)
  }
}

async function quitarSeguimiento(s) {
  if (!window.confirm(`¿Eliminar el seguimiento del ${formatearFecha(s.fecha)}?`)) return
  const ok = await segOp.ejecutar(() => eliminarSeguimiento(s.id).then(() => true), 'Seguimiento eliminado.')
  if (ok) seguimientos.value = await listarSeguimientos(id)
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div>
      <p><RouterLink class="link-accion" to="/inscripciones">← Inscripciones</RouterLink></p>
      <h2>{{ inscripcion ? `${inscripcion.alumno?.apellido}, ${inscripcion.alumno?.nombre}` : 'Inscripción' }}</h2>
    </div>
    <EstadoBadge v-if="inscripcion" :estado="inscripcion.estado" />
  </section>

  <AvisoOperacion :cargando="carga.cargando.value" texto-cargando="Cargando inscripción..." :error="carga.error.value" />
  <AvisoOperacion :error="accion.error.value" :exito="accion.exito.value" />
  <p v-if="route.query.nueva && estado === 'borrador'" class="aviso aviso--exito" role="status">
    Inscripción creada en borrador. Completá los datos de inscripción, guardalos y enviala a la empresa.
  </p>

  <template v-if="inscripcion">
    <section class="panel seccion">
      <dl class="detalle">
        <div><dt>Alumno</dt><dd>{{ inscripcion.alumno?.apellido }}, {{ inscripcion.alumno?.nombre }} · DNI {{ inscripcion.alumno?.dni }}</dd></div>
        <div><dt>Curso</dt><dd>{{ inscripcion.alumno?.curso ? `${inscripcion.alumno.curso}° ${inscripcion.alumno.division || ''}` : '—' }}</dd></div>
        <div><dt>Convenio</dt><dd><RouterLink class="link-accion" :to="`/convenios/${inscripcion.convenio_id}`">{{ inscripcion.convenio?.area }}</RouterLink></dd></div>
        <div><dt>Empresa</dt><dd>{{ inscripcion.convenio?.empresa?.nombre_fantasia || inscripcion.convenio?.empresa?.razon_social }}</dd></div>
        <div><dt>Escuela</dt><dd>{{ inscripcion.convenio?.escuela?.nombre }}</dd></div>
        <div><dt>Período</dt><dd>{{ formatearFecha(inscripcion.fecha_inicio) }} al {{ formatearFecha(inscripcion.fecha_fin) }}</dd></div>
        <div><dt>Horas</dt><dd>{{ inscripcion.horas_totales || '—' }}</dd></div>
        <div class="campo--ancho"><dt>Observaciones</dt><dd>{{ inscripcion.observaciones || '—' }}</dd></div>
      </dl>

      <div class="acciones" style="margin-top:18px">
        <template v-if="esEscuelaAdmin">
          <button v-if="estado === 'borrador'" class="primary-button" type="button" :disabled="accion.cargando.value || faltantes > 0" :title="faltantes ? 'Completá los requisitos obligatorios' : ''" @click="cambiarEstado('enviada')">Enviar a la empresa</button>
          <button v-if="estado === 'borrador'" class="boton-peligro" type="button" :disabled="accion.cargando.value" @click="eliminarBorrador">Eliminar borrador</button>
          <button v-if="['enviada', 'aceptada'].includes(estado)" class="boton-peligro" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('cancelada')">Cancelar inscripción</button>
        </template>
        <template v-if="esEmpresaAdmin && estado === 'enviada'">
          <button class="primary-button" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('aceptada')">Aceptar</button>
          <button class="boton-peligro" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('rechazada')">Rechazar</button>
        </template>
        <button v-if="esAdmin && estado === 'aceptada'" class="primary-button" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('en_curso')">Iniciar pasantía</button>
        <button v-if="esAdmin && estado === 'en_curso'" class="secondary-button" type="button" :disabled="accion.cargando.value" @click="cambiarEstado('finalizada')">Finalizar pasantía</button>
        <button v-if="esAdmin && ['aceptada', 'en_curso'].includes(estado) && !periodo" class="filter-button" type="button" @click="editarPeriodo">Editar período y horas</button>
      </div>
      <p v-if="estado === 'borrador' && faltantes" class="campo-ayuda" style="margin-top:10px">Faltan {{ faltantes }} requisito(s) obligatorio(s) para poder enviar.</p>
    </section>

    <form v-if="periodo" class="panel formulario seccion" novalidate @submit.prevent="guardarPeriodo">
      <div class="seccion-titulo"><h3>Período y horas</h3></div>
      <div class="form-grid form-grid--3">
        <CampoFormulario etiqueta="Inicio" :error="erroresPeriodo.fecha_inicio"><input v-model="periodo.fecha_inicio" type="date" /></CampoFormulario>
        <CampoFormulario etiqueta="Fin" :error="erroresPeriodo.fecha_fin"><input v-model="periodo.fecha_fin" type="date" :min="periodo.fecha_inicio || undefined" /></CampoFormulario>
        <CampoFormulario etiqueta="Horas totales" :error="erroresPeriodo.horas_totales"><input v-model="periodo.horas_totales" type="number" min="1" step="1" /></CampoFormulario>
        <CampoFormulario etiqueta="Observaciones" ancho><textarea v-model="periodo.observaciones" maxlength="600" rows="2"></textarea></CampoFormulario>
      </div>
      <div class="acciones acciones--fin">
        <button class="filter-button" type="button" @click="periodo = null">Cancelar</button>
        <button class="primary-button" type="submit" :disabled="accion.cargando.value">Guardar</button>
      </div>
    </form>

    <form class="panel formulario seccion" novalidate @submit.prevent="guardarDatos">
      <div class="seccion-titulo"><h3>Datos de inscripción</h3></div>
      <p v-if="!requisitos.length" class="vacio">Este convenio no pide datos adicionales.</p>
      <p v-else-if="!editableDatos" class="campo-ayuda" style="margin:0">{{ estado === 'borrador' ? 'Solo el administrador de la escuela carga estos datos.' : 'Los datos quedaron fijos al enviar la inscripción.' }}</p>
      <div v-if="requisitos.length" class="form-grid">
        <CampoFormulario v-for="r in requisitos" :key="r.id" :etiqueta="r.nombre" :ayuda="r.descripcion || ''" :error="erroresDatos[r.id]" :obligatorio="r.obligatorio">
          <template v-if="r.tipo === 'archivo'">
            <button v-if="valores[r.id].archivo_ruta" class="link-accion" type="button" style="text-align:left" @click.prevent="verArchivo(valores[r.id].archivo_ruta)">Ver archivo cargado</button>
            <span v-else-if="!editableDatos" class="campo-ayuda">Sin archivo</span>
            <input v-if="editableDatos" type="file" accept="application/pdf,image/jpeg,image/png" @change="elegirArchivo(r.id, $event)" />
          </template>
          <select v-else-if="r.tipo === 'si_no'" v-model="valores[r.id].valor" :disabled="!editableDatos"><option value="">—</option><option value="si">Sí</option><option value="no">No</option></select>
          <input v-else-if="r.tipo === 'fecha'" v-model="valores[r.id].valor" type="date" :disabled="!editableDatos" />
          <input v-else-if="r.tipo === 'numero'" v-model="valores[r.id].valor" inputmode="decimal" :disabled="!editableDatos" />
          <input v-else v-model="valores[r.id].valor" maxlength="500" :disabled="!editableDatos" />
        </CampoFormulario>
      </div>
      <AvisoOperacion :error="datosOp.error.value" :exito="datosOp.exito.value" />
      <div v-if="editableDatos && requisitos.length" class="acciones acciones--fin">
        <button class="primary-button" type="submit" :disabled="datosOp.cargando.value">{{ datosOp.cargando.value ? 'Guardando...' : 'Guardar datos' }}</button>
      </div>
    </form>

    <section class="panel seccion">
      <div class="seccion-titulo">
        <h3>Seguimientos</h3>
        <button v-if="estado === 'en_curso' && !seguimiento" class="secondary-button boton-chico" type="button" @click="nuevoSeguimiento">+ Nuevo seguimiento</button>
      </div>
      <p v-if="estado !== 'en_curso' && estado !== 'finalizada'" class="aviso aviso--info">Los seguimientos se registran cuando la pasantía está en curso.</p>
      <AvisoOperacion :error="segOp.error.value" :exito="segOp.exito.value" />

      <form v-if="seguimiento" class="formulario seccion" novalidate @submit.prevent="guardarSeguimiento">
        <div class="form-grid form-grid--3">
          <CampoFormulario etiqueta="Fecha" :error="erroresSeg.fecha" obligatorio><input v-model="seguimiento.fecha" type="date" /></CampoFormulario>
          <CampoFormulario etiqueta="Progreso (%)" :error="erroresSeg.progreso" obligatorio><input v-model="seguimiento.progreso" type="number" min="0" max="100" /></CampoFormulario>
          <CampoFormulario etiqueta="Próximo seguimiento" :error="erroresSeg.proxima_fecha"><input v-model="seguimiento.proxima_fecha" type="date" :min="seguimiento.fecha || undefined" /></CampoFormulario>
          <CampoFormulario etiqueta="Observaciones" :error="erroresSeg.observaciones" obligatorio ancho><textarea v-model="seguimiento.observaciones" maxlength="1000" rows="3"></textarea></CampoFormulario>
        </div>
        <div class="acciones acciones--fin">
          <button class="filter-button" type="button" @click="seguimiento = null">Cancelar</button>
          <button class="primary-button" type="submit" :disabled="segOp.cargando.value">{{ segOp.cargando.value ? 'Guardando...' : 'Registrar' }}</button>
        </div>
      </form>

      <p v-if="!seguimientos.length" class="vacio">Sin seguimientos registrados.</p>
      <ul v-else class="lista-seguimientos">
        <li v-for="s in seguimientos" :key="s.id">
          <div class="cabecera"><span>{{ formatearFecha(s.fecha) }} · {{ s.progreso }}%</span><span class="campo-ayuda">{{ s.autor?.nombre_completo || 'Contraparte' }}</span></div>
          <div class="progress-bar" style="margin-bottom:8px"><span :style="{ width: `${s.progreso}%` }"></span></div>
          {{ s.observaciones }}
          <div v-if="s.proxima_fecha" class="campo-ayuda" style="margin-top:6px">Próximo: {{ formatearFecha(s.proxima_fecha) }}</div>
          <div v-if="s.autor_id === currentUser?.id" class="acciones" style="margin-top:8px"><button class="product-action product-action--danger" type="button" @click="quitarSeguimiento(s)">Eliminar</button></div>
        </li>
      </ul>
    </section>
  </template>
</template>
