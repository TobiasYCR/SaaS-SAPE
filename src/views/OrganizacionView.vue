<script setup>
import { onMounted, ref } from 'vue'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import CampoFormulario from '../components/common/CampoFormulario.vue'
import FormEscuela from '../components/organizacion/FormEscuela.vue'
import FormEmpresa from '../components/organizacion/FormEmpresa.vue'
import { aFormulario, aRegistro } from '../components/organizacion/datosOrganizacion'
import { esAdmin, ETIQUETA_ROL, organizacion, recargarPerfil } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { actualizarEscuela, obtenerEscuela } from '../services/escuelasService'
import { actualizarEmpresa, obtenerEmpresa } from '../services/empresasService'
import { asignarMiembro, listarMiembros } from '../services/perfilService'
import { ROLES_MIEMBRO } from '../utils/catalogos'
import { hayErrores, requeridos, validarEmpresa, validarEscuela } from '../utils/validaciones'

const tipo = organizacion.value.tipo
const datos = ref(null)
const errores = ref({})
const miembros = ref([])
const nuevoMiembro = ref({ email: '', rol: `${tipo}_tutor` })
const erroresMiembro = ref({})

const carga = useOperacion()
const guardado = useOperacion()
const alta = useOperacion()

async function cargar() {
  const [registro, lista] = await carga.ejecutar(() => Promise.all([
    tipo === 'escuela' ? obtenerEscuela(organizacion.value.id) : obtenerEmpresa(organizacion.value.id),
    listarMiembros(),
  ])) || []
  if (registro) datos.value = aFormulario(tipo, registro)
  if (lista) miembros.value = lista
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
    miembros.value = await listarMiembros()
  }
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
          <div class="cabecera"><span>{{ m.nombre_completo || m.email }}</span><span><span v-if="!m.activo" class="estado estado--rojo" style="margin-right:6px">Desactivado</span><span class="estado estado--azul">{{ ETIQUETA_ROL[m.rol] }}</span></span></div>
          {{ m.email }}
        </li>
      </ul>

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
