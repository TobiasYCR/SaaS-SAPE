<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { supabase } from '../auth'

const empresas = ref([])
const nombre = ref('')
const descripcion = ref('')
const rubro = ref('')
const ubicacion = ref('')
const contacto = ref('')
const activa = ref(true)
const archivoLogo = ref(null)
const vistaPrevia = ref('')
const logoUrlExistente = ref('')
const logoRutaExistente = ref('')
const inputLogo = ref(null)
const empresaEditandoId = ref(null)
const cargando = ref(false)
const mensaje = ref('')
const errorMensaje = ref('')

async function cargarEmpresas(limpiarMensaje = true) {
  cargando.value = true
  errorMensaje.value = ''
  if (limpiarMensaje) mensaje.value = ''
  const { data, error } = await supabase.from('empresas').select('*').order('creado_en', { ascending: false })
  if (error) errorMensaje.value = error.message?.toLowerCase().includes('could not find the table') ? 'No existe la tabla empresas en Supabase. Ejecutá el SQL de configuración' : error.message
  else empresas.value = data ?? []
  cargando.value = false
}

function seleccionarLogo(evento) {
  errorMensaje.value = ''
  const archivo = evento.target.files?.[0]
  if (!archivo) return
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(archivo.type)) {
    errorMensaje.value = 'El logo debe ser JPG, PNG o WEBP'
    evento.target.value = ''
    return
  }
  if (archivo.size > 5 * 1024 * 1024) {
    errorMensaje.value = 'El logo no puede superar los 5 MB'
    evento.target.value = ''
    return
  }
  if (vistaPrevia.value) URL.revokeObjectURL(vistaPrevia.value)
  archivoLogo.value = archivo
  vistaPrevia.value = URL.createObjectURL(archivo)
}

async function subirLogo() {
  if (!archivoLogo.value) return null
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) throw new Error('No hay un usuario autenticado')
  const extension = archivoLogo.value.name.split('.').pop().toLowerCase()
  const ruta = `${user.id}/${crypto.randomUUID()}.${extension}`
  const { error: errorSubida } = await supabase.storage.from('empresas').upload(ruta, archivoLogo.value, { cacheControl: '3600', upsert: false })
  if (errorSubida) throw errorSubida
  const { data } = supabase.storage.from('empresas').getPublicUrl(ruta)
  return { url: data.publicUrl, ruta }
}

async function guardarEmpresa() {
  errorMensaje.value = ''
  mensaje.value = ''
  if (!nombre.value.trim()) return void (errorMensaje.value = 'El nombre es obligatorio')
  if (!empresaEditandoId.value && !archivoLogo.value) return void (errorMensaje.value = 'Seleccioná un logo para la empresa')
  cargando.value = true
  let nuevoLogo = null
  try {
    nuevoLogo = await subirLogo()
    const datosEmpresa = { nombre: nombre.value.trim(), descripcion: descripcion.value.trim() || null, rubro: rubro.value.trim() || null, ubicacion: ubicacion.value.trim() || null, contacto: contacto.value.trim() || null, activa: activa.value, logo_url: nuevoLogo?.url ?? logoUrlExistente.value, logo_ruta: nuevoLogo?.ruta ?? logoRutaExistente.value }
    const consulta = empresaEditandoId.value ? supabase.from('empresas').update(datosEmpresa).eq('id', empresaEditandoId.value) : supabase.from('empresas').insert(datosEmpresa)
    const { error } = await consulta
    if (error) {
      if (nuevoLogo?.ruta) await supabase.storage.from('empresas').remove([nuevoLogo.ruta])
      throw error
    }
    if (empresaEditandoId.value && nuevoLogo?.ruta && logoRutaExistente.value) await supabase.storage.from('empresas').remove([logoRutaExistente.value])
    mensaje.value = empresaEditandoId.value ? 'Empresa actualizada correctamente' : 'Empresa creada correctamente'
    limpiarFormulario()
    await cargarEmpresas(false)
  } catch (error) {
    errorMensaje.value = error.message?.toLowerCase().includes('bucket not found') ? 'No existe el bucket empresas en Supabase. Ejecutá el SQL de configuración' : error.message || 'No se pudo guardar la empresa'
  } finally {
    cargando.value = false
  }
}

function editarEmpresa(empresa) {
  empresaEditandoId.value = empresa.id
  nombre.value = empresa.nombre
  descripcion.value = empresa.descripcion ?? ''
  rubro.value = empresa.rubro ?? ''
  ubicacion.value = empresa.ubicacion ?? ''
  contacto.value = empresa.contacto ?? ''
  activa.value = empresa.activa
  logoUrlExistente.value = empresa.logo_url ?? ''
  logoRutaExistente.value = empresa.logo_ruta ?? ''
  archivoLogo.value = null
  vistaPrevia.value = ''
  if (inputLogo.value) inputLogo.value.value = ''
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function eliminarEmpresa(empresa) {
  if (!window.confirm(`¿Querés eliminar la empresa "${empresa.nombre}"?`)) return
  cargando.value = true
  errorMensaje.value = ''
  const { error } = await supabase.from('empresas').delete().eq('id', empresa.id)
  if (error) {
    errorMensaje.value = error.message
    cargando.value = false
    return
  }
  if (empresa.logo_ruta) await supabase.storage.from('empresas').remove([empresa.logo_ruta])
  mensaje.value = 'Empresa eliminada correctamente'
  if (empresaEditandoId.value === empresa.id) limpiarFormulario()
  await cargarEmpresas(false)
  cargando.value = false
}

function limpiarFormulario() {
  nombre.value = ''
  descripcion.value = ''
  rubro.value = ''
  ubicacion.value = ''
  contacto.value = ''
  activa.value = true
  empresaEditandoId.value = null
  archivoLogo.value = null
  logoUrlExistente.value = ''
  logoRutaExistente.value = ''
  if (vistaPrevia.value) URL.revokeObjectURL(vistaPrevia.value)
  vistaPrevia.value = ''
  if (inputLogo.value) inputLogo.value.value = ''
}

function cancelarEdicion() {
  limpiarFormulario()
  mensaje.value = ''
  errorMensaje.value = ''
}

onMounted(cargarEmpresas)
onBeforeUnmount(() => { if (vistaPrevia.value) URL.revokeObjectURL(vistaPrevia.value) })
</script>

<template>
  <section class="page-intro"><div><p>Gestioná las organizaciones que ofrecen pasantías escolares</p><h2>Empresas</h2></div></section>
  <main class="products-layout">
    <section class="panel product-form-panel">
      <p class="eyebrow">{{ empresaEditandoId ? 'EDITAR EMPRESA' : 'NUEVA EMPRESA' }}</p>
      <h2>{{ empresaEditandoId ? 'Editar empresa' : 'Cargar empresa' }}</h2>
      <p>Completá los datos de la organización y sumá un logo JPG, PNG o WEBP de hasta 5 MB</p>
      <form class="product-form" @submit.prevent="guardarEmpresa">
        <label>Nombre<input v-model="nombre" type="text" maxlength="120" required></label>
        <label>Descripción<textarea v-model="descripcion" rows="3"></textarea></label>
        <div class="product-form-row"><label>Rubro<input v-model="rubro" type="text" maxlength="80"></label><label>Ubicación<input v-model="ubicacion" type="text" maxlength="120"></label></div>
        <label>Contacto<input v-model="contacto" type="text" maxlength="120" placeholder="Mail o teléfono"></label>
        <label>Logo<input ref="inputLogo" type="file" accept="image/jpeg,image/png,image/webp" @change="seleccionarLogo"><small>Máximo 5 MB</small></label>
        <div v-if="vistaPrevia || logoUrlExistente" class="product-preview"><img :src="vistaPrevia || logoUrlExistente" alt="Vista previa del logo"><span>{{ vistaPrevia ? 'Nuevo logo seleccionado' : 'Logo actual' }}</span></div>
        <label class="product-check"><input v-model="activa" type="checkbox">Empresa activa</label>
        <p v-if="errorMensaje" class="product-message product-message--error" role="alert">{{ errorMensaje }}</p>
        <p v-if="mensaje" class="product-message product-message--success" role="status">{{ mensaje }}</p>
        <div class="product-actions"><button class="primary-button" type="submit" :disabled="cargando">{{ cargando ? 'Guardando...' : empresaEditandoId ? 'Actualizar empresa' : 'Crear empresa' }}</button><button v-if="empresaEditandoId" class="secondary-button" type="button" @click="cancelarEdicion">Cancelar</button></div>
      </form>
    </section>
    <section class="panel products-list-panel">
      <div class="products-list-header"><div><p class="eyebrow">ORGANIZACIONES</p><h2>Empresas registradas</h2></div><button class="filter-button" :disabled="cargando" @click="cargarEmpresas">Actualizar</button></div>
      <p v-if="cargando && !empresas.length" class="products-empty">Cargando empresas...</p>
      <p v-else-if="!empresas.length" class="products-empty">Todavía no cargaste empresas</p>
      <div v-else class="product-table-wrap"><table class="product-table"><thead><tr><th>LOGO</th><th>EMPRESA</th><th>RUBRO</th><th>UBICACIÓN</th><th>ESTADO</th><th>ACCIONES</th></tr></thead><tbody><tr v-for="empresa in empresas" :key="empresa.id"><td><img v-if="empresa.logo_url" class="product-thumbnail" :src="empresa.logo_url" :alt="empresa.nombre"><span v-else class="product-no-image">Sin logo</span></td><td class="product-cell"><strong>{{ empresa.nombre }}</strong><small>{{ empresa.descripcion || 'Sin descripción' }}</small></td><td>{{ empresa.rubro || 'Sin rubro' }}</td><td>{{ empresa.ubicacion || 'Sin ubicación' }}</td><td><span class="product-status" :class="empresa.activa ? 'product-status--active' : 'product-status--inactive'">{{ empresa.activa ? 'Activa' : 'Inactiva' }}</span></td><td><div class="product-actions-cell"><button class="product-action" @click="editarEmpresa(empresa)">Editar</button><button class="product-action product-action--danger" @click="eliminarEmpresa(empresa)">Eliminar</button></div></td></tr></tbody></table></div>
    </section>
  </main>
</template>
