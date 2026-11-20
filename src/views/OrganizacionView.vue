<script setup>
import { onMounted, ref } from 'vue'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import CampoFormulario from '../components/common/CampoFormulario.vue'
import FormEscuela from '../components/organizacion/FormEscuela.vue'
import FormEmpresa from '../components/organizacion/FormEmpresa.vue'
import { aFormulario, aRegistro } from '../components/organizacion/datosOrganizacion'
import { currentUser, esAdmin, ETIQUETA_ROL, organizacion, recargarPerfil } from '../composables/useAuth'
import { confirmar } from '../composables/useConfirmacion'
import { useOperacion } from '../composables/useOperacion'
import { actualizarEscuela, obtenerEscuela } from '../services/escuelasService'
import { actualizarEmpresa, obtenerEmpresa } from '../services/empresasService'
import { actualizarMiembro, asignarMiembro, listarMiembros } from '../services/perfilService'
import { ROLES_MIEMBRO } from '../utils/catalogos'
import { hayErrores, requeridos, validarEmpresa, validarEscuela } from '../utils/validaciones'

const tipo = organizacion.value.tipo
const datos = ref(null)
const errores = ref({})
const miembros = ref([])
const edicionesMiembro = ref({})
const nuevoMiembro = ref({ email: '', rol: `${tipo}_tutor` })
const erroresMiembro = ref({})

const carga = useOperacion()
const guardado = useOperacion()
const alta = useOperacion()
const gestionMiembro = useOperacion()

function cargarMiembros(lista) {
  miembros.value = lista || []
  edicionesMiembro.value = Object.fromEntries(miembros.value.map((miembro) => [
    miembro.id,
    { rol: miembro.rol, activo: miembro.activo },
  ]))
}

async function cargar() {
  const [registro, lista] = await carga.ejecutar(() => Promise.all([
    tipo === 'escuela' ? obtenerEscuela(organizacion.value.id) : obtenerEmpresa(organizacion.value.id),
    listarMiembros(),
  ])) || []
  if (registro) datos.value = aFormulario(tipo, registro)
  if (lista) cargarMiembros(lista)
}

async function guardar() {
  errores.value = tipo === 'escuela' ? validarEscuela(datos.value) : validarEmpresa(datos.value)
  if (hayErrores(errores.value)) return
  const registro = aRegistro(tipo, datos.value)
  const ok = await guardado.ejecutar(
    () => (tipo === 'escuela' ? actualizarEscuela : actualizarEmpresa)(organizacion.value.id, registro),
    'Datos de la organización actualizados.',
  )
  if (ok) await recargarPerfil()
}

async function sumarMiembro() {
  erroresMiembro.value = requeridos(nuevoMiembro.value, { email: 'El email', rol: 'El rol' })
  if (hayErrores(erroresMiembro.value)) return
  const email = nuevoMiembro.value.email.trim()
  const ok = await alta.ejecutar(() => asignarMiembro(email, nuevoMiembro.value.rol).then(() => true), `${email} ya forma parte de la organización.`)
  if (ok) {
    nuevoMiembro.value.email = ''
    cargarMiembros(await listarMiembros())
  }
}

async function guardarMiembro(miembro, activo = edicionesMiembro.value[miembro.id].activo) {
  const edicion = edicionesMiembro.value[miembro.id]
  if (!activo && miembro.activo && !(await confirmar({
    titulo: 'Desactivar acceso',
    mensaje: `¿Desactivar el acceso de ${miembro.nombre_completo || miembro.email}?`,
    textoConfirmar: 'Desactivar',
    peligro: true,
  }))) return

  const ok = await gestionMiembro.ejecutar(
    () => actualizarMiembro(miembro.id, edicion.rol, activo).then(() => true),
    activo ? 'Miembro actualizado y habilitado.' : 'Acceso del miembro desactivado.',
  )
  if (ok) cargarMiembros(await listarMiembros())
}

onMounted(cargar)
</script>

<template>
  <section class="page-intro">
    <div><p>{{ tipo === 'escuela' ? 'Datos de la escuela' : 'Datos de la empresa' }} y personas que la usan</p><h2>{{ organizacion.nombre }}</h2></div>
  </section>

  <AvisoOperacion :cargando="carga.cargando.value" :error="carga.error.value" />

  <div v-if="datos" class="dos-columnas">
    <form class="panel formulario" novalidate @submit.prevent="guardar">
      <div class="seccion-titulo"><h3>Datos</h3></div>
      <p v-if="!esAdmin" class="aviso aviso--info">Solo los administradores pueden modificar estos datos.</p>
      <fieldset :disabled="!esAdmin" style="border:0;padding:0;margin:0">
        <FormEscuela v-if="tipo === 'escuela'" v-model="datos" :errores="errores" />
        <FormEmpresa v-else v-model="datos" :errores="errores" />
      </fieldset>
      <AvisoOperacion :error="guardado.error.value" :exito="guardado.exito.value" />
      <div v-if="esAdmin" class="acciones acciones--fin">
        <button class="primary-button" type="submit" :disabled="guardado.cargando.value">{{ guardado.cargando.value ? 'Guardando...' : 'Guardar cambios' }}</button>
      </div>
    </form>

    <section class="panel">
      <div class="seccion-titulo"><h3>Miembros</h3></div>
      <ul class="lista-seguimientos">
        <li v-for="m in miembros" :key="m.id">
          <div class="cabecera"><span>{{ m.nombre_completo || m.email }} <small v-if="m.id === currentUser?.id">(tu cuenta)</small></span><span><span v-if="!m.activo" class="estado estado--rojo" style="margin-right:6px">Desactivado</span><span class="estado estado--azul">{{ ETIQUETA_ROL[m.rol] }}</span></span></div>
          {{ m.email }}
          <div v-if="esAdmin && m.id !== currentUser?.id && edicionesMiembro[m.id]" class="acciones" style="margin-top:10px">
            <select v-model="edicionesMiembro[m.id].rol" :aria-label="`Rol de ${m.nombre_completo || m.email}`">
              <option v-for="(etiqueta, valor) in ROLES_MIEMBRO[tipo]" :key="valor" :value="valor">{{ etiqueta }}</option>
            </select>
            <button class="secondary-button boton-chico" type="button" :disabled="gestionMiembro.cargando.value || edicionesMiembro[m.id].rol === m.rol" @click="guardarMiembro(m)">Guardar rol</button>
            <button v-if="m.activo" class="boton-peligro boton-chico" type="button" :disabled="gestionMiembro.cargando.value" @click="guardarMiembro(m, false)">Desactivar acceso</button>
            <button v-else class="secondary-button boton-chico" type="button" :disabled="gestionMiembro.cargando.value" @click="guardarMiembro(m, true)">Reactivar acceso</button>
          </div>
        </li>
      </ul>
      <AvisoOperacion :cargando="gestionMiembro.cargando.value" :error="gestionMiembro.error.value" :exito="gestionMiembro.exito.value" />

      <form v-if="esAdmin" class="formulario" style="margin-top:18px" novalidate @submit.prevent="sumarMiembro">
        <p class="campo-ayuda" style="margin:0">La persona primero se registra en SAPE con su email. Después la sumás acá con el rol que corresponda.</p>
        <CampoFormulario etiqueta="Email del usuario" :error="erroresMiembro.email" obligatorio>
          <input v-model="nuevoMiembro.email" type="email" maxlength="150" />
        </CampoFormulario>
        <CampoFormulario etiqueta="Rol" :error="erroresMiembro.rol" obligatorio>
          <select v-model="nuevoMiembro.rol">
            <option v-for="(etiqueta, valor) in ROLES_MIEMBRO[tipo]" :key="valor" :value="valor">{{ etiqueta }}</option>
          </select>
        </CampoFormulario>
        <AvisoOperacion :error="alta.error.value" :exito="alta.exito.value" />
        <div class="acciones acciones--fin">
          <button class="secondary-button" type="submit" :disabled="alta.cargando.value">{{ alta.cargando.value ? 'Sumando...' : 'Sumar miembro' }}</button>
        </div>
      </form>
    </section>
  </div>
</template>
