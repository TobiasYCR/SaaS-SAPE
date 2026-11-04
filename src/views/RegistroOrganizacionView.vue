<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import AvisoOperacion from '../components/common/AvisoOperacion.vue'
import FormEscuela from '../components/organizacion/FormEscuela.vue'
import FormEmpresa from '../components/organizacion/FormEmpresa.vue'
import { aRegistro, formularioVacio } from '../components/organizacion/datosOrganizacion'
import { recargarPerfil } from '../composables/useAuth'
import { useOperacion } from '../composables/useOperacion'
import { registrarOrganizacion } from '../services/perfilService'
import { hayErrores, validarEmpresa, validarEscuela } from '../utils/validaciones'

const router = useRouter()
const tipo = ref('escuela')
const datos = ref(formularioVacio('escuela'))
const errores = ref({})
const { cargando, error, ejecutar } = useOperacion()

function elegirTipo(nuevo) {
  if (tipo.value === nuevo) return
  tipo.value = nuevo
  datos.value = formularioVacio(nuevo)
  errores.value = {}
}

async function registrar() {
  errores.value = tipo.value === 'escuela' ? validarEscuela(datos.value) : validarEmpresa(datos.value)
  if (hayErrores(errores.value)) return
  const ok = await ejecutar(() => registrarOrganizacion(tipo.value, aRegistro(tipo.value, datos.value)))
  if (!ok) return
  await recargarPerfil()
  router.replace('/dashboard')
}
</script>

<template>
  <section class="page-intro">
    <div><p>Último paso para empezar a usar SAPE</p><h2>Registrá tu organización</h2></div>
  </section>

  <section class="panel seccion">
    <p class="aviso aviso--info">Tu cuenta todavía no pertenece a ninguna organización. Registrá tu escuela o tu empresa y vas a quedar como administrador. Si otra persona ya la registró, pedile que te sume desde <strong>Mi organización</strong>.</p>

    <div class="selector-tipo" role="group" aria-label="Tipo de organización">
      <button type="button" :aria-pressed="tipo === 'escuela'" @click="elegirTipo('escuela')">
        <strong>Escuela</strong>Administra alumnos, acepta convenios e inscribe pasantes.
      </button>
      <button type="button" :aria-pressed="tipo === 'empresa'" @click="elegirTipo('empresa')">
        <strong>Empresa</strong>Elige escuelas, se postula y recibe pasantes.
      </button>
    </div>
  </section>

  <form class="panel formulario" novalidate @submit.prevent="registrar">
    <FormEscuela v-if="tipo === 'escuela'" v-model="datos" :errores="errores" />
    <FormEmpresa v-else v-model="datos" :errores="errores" />
    <AvisoOperacion :error="error" />
    <div class="acciones acciones--fin">
      <button class="primary-button" type="submit" :disabled="cargando">{{ cargando ? 'Registrando...' : `Registrar ${tipo}` }}</button>
    </div>
  </form>
</template>
