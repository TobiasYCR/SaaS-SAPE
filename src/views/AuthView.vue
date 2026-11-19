<script setup>
import { traducirError } from '../utils/errores'
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { authError } from '../composables/useAuth'
import { supabase } from '../services/supabase'
import CampoContrasena from '../components/common/CampoContrasena.vue'
import { esContrasenaValida } from '../utils/validaciones'

const route = useRoute()
const router = useRouter()
const isRegistering = ref(false)
const fullName = ref('')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const errorMessage = ref('')
// Viene de una sesión cerrada o vencida (App.vue)
const notice = ref(route.query.motivo === 'sesion' ? 'Tu sesión se cerró. Iniciá sesión para continuar.' : '')
const isSubmitting = ref(false)
const cuentaDemoAbierta = ref(false)

const CUENTAS_DEMO = [
  { email: 'rioclaro@test.com', rol: 'Admin escuela', organizacion: 'Escuela Técnica Río Claro' },
  { email: 'tutor.rioclaro@test.com', rol: 'Tutor escuela', organizacion: 'Escuela Técnica Río Claro' },
  { email: 'pixel@test.com', rol: 'Admin empresa', organizacion: 'Pixel Andino S.R.L.' },
  { email: 'tutor.pixel@test.com', rol: 'Tutor empresa', organizacion: 'Pixel Andino S.R.L.' },
  { email: 'coopnorte@test.com', rol: 'Admin empresa', organizacion: 'Cooperativa Norte Ltda.' },
  { email: 'delta@test.com', rol: 'Admin empresa', organizacion: 'Grupo Delta S.A.' },
]

function usarCuentaDemo(cuenta) {
  email.value = cuenta.email
  password.value = 'Sape2026'
  confirmPassword.value = ''
  errorMessage.value = ''
  cuentaDemoAbierta.value = false
}

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
  if (isRegistering.value && !esContrasenaValida(password.value)) {
    errorMessage.value = 'La contraseña debe tener exactamente 8 caracteres alfanuméricos.'
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
    errorMessage.value = traducirError(error)
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
    <div class="auth-layout">
      <aside class="auth-story">
        <RouterLink class="auth-brand" to="/login" aria-label="SAPE, ir al inicio">
          <img class="brand-logo" src="/logo-sape.png" alt="SAPE Pasantías" />
          <span><strong>SAPE</strong><small>Pasantías escolares</small></span>
        </RouterLink>

        <div class="auth-story-copy">
          <span class="auth-story-label">ESCUELA · EXPERIENCIA · FUTURO</span>
        </div>

        <svg class="auth-illustration" viewBox="0 0 440 260" fill="none" aria-hidden="true">
          <path d="M39 223h365" stroke="#E9D9AE" stroke-width="3" stroke-linecap="round"/>
          <path d="M114 103 220 43l106 60v120H114V103Z" fill="#F6EBD1"/>
          <path d="M93 105 220 32l127 73" stroke="#D7A94E" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M194 159h52v64h-52z" fill="#C66F52"/>
          <path d="M128 116h44v39h-44zM268 116h44v39h-44z" fill="#A9C8B0"/>
          <path d="M148 116v39m140-39v39M128 135h44m96 0h44" stroke="#F8F5E9" stroke-width="4"/>
          <path d="M215 65h10v20h-10z" fill="#C66F52"/>
          <path d="M198 91h44" stroke="#315B49" stroke-width="4" stroke-linecap="round"/>
          <path d="M75 220c0-30 13-46 29-46s29 16 29 46m-16-38c0-17 8-28 19-31m-98 69c0-19 8-30 18-30 9 0 17 11 17 30" stroke="#739477" stroke-width="5" stroke-linecap="round"/>
          <path d="M321 220c0-30 13-46 29-46s29 16 29 46m-16-38c0-17 8-28 19-31m-98 69c0-19 8-30 18-30 9 0 17 11 17 30" stroke="#739477" stroke-width="5" stroke-linecap="round"/>
          <path d="M215 114h10" stroke="#315B49" stroke-width="4" stroke-linecap="round"/>
          <circle cx="220" cy="100" r="4" fill="#D7A94E"/>
        </svg>

        <p class="auth-story-note"><span>✳</span> Cada experiencia abre una puerta nueva.</p>
      </aside>

      <section class="auth-card" aria-labelledby="auth-title">
        <p class="auth-eyebrow">{{ isRegistering ? 'EMPIEZA POR AQUÍ' : 'QUÉ BUENO VERTE' }}</p>
        <h1 id="auth-title">{{ title }}</h1>
        <p class="auth-description">
          {{ isRegistering ? 'Crea tu cuenta para acompañar el camino de tus estudiantes.' : 'Ingresa a tu espacio de trabajo.' }}
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

          <CampoContrasena
            v-model="password"
            etiqueta="Contraseña"
            :autocomplete="isRegistering ? 'new-password' : 'current-password'"
          />

          <template v-if="isRegistering">
            <CampoContrasena
              v-model="confirmPassword"
              etiqueta="Confirmar contraseña"
              placeholder="Repite la contraseña"
              autocomplete="new-password"
            />
          </template>

          <p v-if="errorMessage || authError" class="auth-message auth-message--error" role="alert">
            {{ errorMessage || authError }}
          </p>
          <p v-if="notice" class="auth-message auth-message--success" role="status">{{ notice }}</p>

          <button class="primary-button auth-submit" type="submit" :disabled="isSubmitting">
            {{ submitLabel }}
          </button>

          <div v-if="!isRegistering" class="cuentas-demo">
            <button type="button" class="cuentas-demo__toggle" @click="cuentaDemoAbierta = !cuentaDemoAbierta">
              Cuentas de demostración por rol {{ cuentaDemoAbierta ? '▲' : '▼' }}
            </button>
            <div v-if="cuentaDemoAbierta" class="cuentas-demo__lista">
              <button v-for="cuenta in CUENTAS_DEMO" :key="cuenta.email" type="button" @click="usarCuentaDemo(cuenta)">
                <strong>{{ cuenta.rol }}</strong>
                <span>{{ cuenta.organizacion }}</span>
                <small>{{ cuenta.email }} · Sape2026</small>
              </button>
            </div>
          </div>
        </form>

        <p class="auth-switch">
          {{ isRegistering ? '¿Ya tienes una cuenta?' : '¿Todavía no tienes una cuenta?' }}
          <button type="button" @click="toggleMode">
            {{ isRegistering ? 'Inicia sesión' : 'Regístrate' }}
          </button>
        </p>
      </section>
    </div>
  </main>
</template>
