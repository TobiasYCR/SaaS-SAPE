<script setup>
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { authError, supabase } from '../auth'

const route = useRoute()
const router = useRouter()
const isRegistering = ref(false)
const fullName = ref('')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const errorMessage = ref('')
const notice = ref('')
const isSubmitting = ref(false)

const title = computed(() => isRegistering.value ? 'Crea tu cuenta' : 'Bienvenido de nuevo')
const submitLabel = computed(() => {
  if (isSubmitting.value) return 'Procesando...'
  return isRegistering.value ? 'Crear cuenta' : 'Iniciar sesión'
})

function toggleMode() {
  isRegistering.value = !isRegistering.value
  errorMessage.value = ''
  notice.value = ''
  password.value = ''
  confirmPassword.value = ''
}

async function submitAuth() {
  errorMessage.value = ''
  notice.value = ''

  if (!supabase) {
    errorMessage.value = authError.value || 'La autenticación no está configurada.'
    return
  }

  if (isRegistering.value && password.value !== confirmPassword.value) {
    errorMessage.value = 'Las contraseñas no coinciden.'
    return
  }

  isSubmitting.value = true
  try {
    if (isRegistering.value) {
      const { data, error } = await supabase.auth.signUp({
        email: email.value,
        password: password.value,
        options: { data: { full_name: fullName.value.trim() } },
      })

      if (error) throw error
      authError.value = ''
      if (data.session) {
        await router.replace(safeRedirectPath())
      } else {
        notice.value = 'Cuenta creada. Revisa tu correo para confirmar el registro e iniciar sesión.'
        isRegistering.value = false
        password.value = ''
        confirmPassword.value = ''
      }
      return
    }

    const { error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value,
    })
    if (error) throw error
    authError.value = ''
    await router.replace(safeRedirectPath())
  } catch (error) {
    errorMessage.value = error.message || 'No se pudo completar la solicitud.'
  } finally {
    isSubmitting.value = false
  }
}

function safeRedirectPath() {
  const redirect = route.query.redirect
  return typeof redirect === 'string' && redirect.startsWith('/') && !redirect.startsWith('//')
    ? redirect
    : '/dashboard'
}
</script>

<template>
  <main class="auth-page">
    <section class="auth-card" aria-labelledby="auth-title">
      <RouterLink class="auth-brand" to="/login" aria-label="SAPE, ir al inicio">
        <span class="brand-mark">S</span>
        <span><strong>SAPE</strong><small>Pasantías escolares</small></span>
      </RouterLink>

      <p class="auth-eyebrow">GESTIÓN DE PASANTÍAS</p>
      <h1 id="auth-title">{{ title }}</h1>
      <p class="auth-description">
        {{ isRegistering ? 'Regístrate para gestionar las pasantías de tu institución.' : 'Ingresa a tu espacio de trabajo.' }}
      </p>

      <form class="auth-form" @submit.prevent="submitAuth">
        <label v-if="isRegistering" for="full-name">Nombre completo</label>
        <input
          v-if="isRegistering"
          id="full-name"
          v-model="fullName"
          autocomplete="name"
          placeholder="Tu nombre"
          required
          maxlength="100"
        >

        <label for="email">Correo electrónico</label>
        <input
          id="email"
          v-model="email"
          type="email"
          autocomplete="email"
          placeholder="nombre@institucion.edu"
          required
        >

        <label for="password">Contraseña</label>
        <input
          id="password"
          v-model="password"
          type="password"
          :autocomplete="isRegistering ? 'new-password' : 'current-password'"
          placeholder="Mínimo 8 caracteres"
          minlength="8"
          required
        >

        <template v-if="isRegistering">
          <label for="confirm-password">Confirmar contraseña</label>
          <input
            id="confirm-password"
            v-model="confirmPassword"
            type="password"
            autocomplete="new-password"
            placeholder="Repite tu contraseña"
            minlength="8"
            required
          >
        </template>

        <p v-if="errorMessage || authError" class="auth-message auth-message--error" role="alert">
          {{ errorMessage || authError }}
        </p>
        <p v-if="notice" class="auth-message auth-message--success" role="status">{{ notice }}</p>

        <button class="primary-button auth-submit" type="submit" :disabled="isSubmitting">
          {{ submitLabel }}
        </button>
      </form>

      <p class="auth-switch">
        {{ isRegistering ? '¿Ya tienes una cuenta?' : '¿Todavía no tienes una cuenta?' }}
        <button type="button" @click="toggleMode">
          {{ isRegistering ? 'Inicia sesión' : 'Regístrate' }}
        </button>
      </p>
    </section>
  </main>
</template>
