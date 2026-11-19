<script setup>
import { ref, useId } from 'vue'

const datos = defineModel({ type: String, default: '' })
defineProps({
  etiqueta: { type: String, default: 'Contraseña' },
  placeholder: { type: String, default: 'Exactamente 8 letras o números' },
  autocomplete: { type: String, default: 'current-password' },
})

const visible = ref(false)
const id = useId()
</script>

<template>
  <div class="campo-password">
    <label :for="id">{{ etiqueta }}</label>
    <div class="campo-password__control">
      <input
        :id="id"
        v-model="datos"
        :type="visible ? 'text' : 'password'"
        :autocomplete="autocomplete"
        :placeholder="placeholder"
        minlength="8"
        maxlength="8"
        pattern="[A-Za-z0-9]{8}"
        required
      >
      <button
        type="button"
        class="campo-password__toggle"
        :aria-label="visible ? 'Ocultar contraseña' : 'Mostrar contraseña'"
        :title="visible ? 'Ocultar contraseña' : 'Mostrar contraseña'"
        @click="visible = !visible"
      >
        {{ visible ? '◉' : '◎' }}
      </button>
    </div>
  </div>
</template>
