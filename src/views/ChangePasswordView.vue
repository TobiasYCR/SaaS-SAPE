<script setup>
import { ref } from 'vue'
import { supabase } from '../auth'

const password = ref('')
const confirmPassword = ref('')
const errorMessage = ref('')
const notice = ref('')
const isSubmitting = ref(false)

async function updatePassword() {
  errorMessage.value = ''
  notice.value = ''

  if (password.value !== confirmPassword.value) {
    errorMessage.value = 'Las contraseñas no coinciden.'
    return
  }

  if (!supabase) {
    errorMessage.value = 'La autenticación no está configurada.'
    return
  }

  isSubmitting.value = true
  try {
    const { error } = await supabase.auth.updateUser({ password: password.value })
    if (error) throw error
    password.value = ''
    confirmPassword.value = ''
    notice.value = 'Tu contraseña se actualizó correctamente.'
  } catch (error) {
    errorMessage.value = error.message || 'No se pudo actualizar la contraseña.'
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <section class="page-intro">
    <div>
      <h2>Cambiar contraseña</h2>
      <p>Elige una contraseña nueva para proteger tu cuenta.</p>
    </div>
  </section>

  <form class="panel password-panel" @submit.prevent="updatePassword">
    <label for="new-password">Nueva contraseña</label>
    <input
      id="new-password"
      v-model="password"
      type="password"
      autocomplete="new-password"
      minlength="8"
      placeholder="Mínimo 8 caracteres"
      required
    >

    <label for="confirm-new-password">Confirmar contraseña</label>
    <input
      id="confirm-new-password"
      v-model="confirmPassword"
      type="password"
      autocomplete="new-password"
      minlength="8"
      placeholder="Escribe nuevamente tu contraseña"
      required
    >

    <p v-if="errorMessage" class="auth-message auth-message--error" role="alert">{{ errorMessage }}</p>
    <p v-if="notice" class="auth-message auth-message--success" role="status">{{ notice }}</p>

    <button class="primary-button" type="submit" :disabled="isSubmitting">
      {{ isSubmitting ? 'Guardando...' : 'Guardar nueva contraseña' }}
    </button>
  </form>
</template>
