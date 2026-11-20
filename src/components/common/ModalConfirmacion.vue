<script setup>
import { nextTick, onBeforeUnmount, ref, watch } from 'vue'
import { estadoConfirmacion, responderConfirmacion } from '../../composables/useConfirmacion'

const botonConfirmar = ref(null)
const botonCancelar = ref(null)

function alPresionarTecla(evento) {
  if (evento.key === 'Escape' && estadoConfirmacion.abierta) {
    evento.preventDefault()
    responderConfirmacion(false)
  }
}

watch(
  () => estadoConfirmacion.abierta,
  async (abierta) => {
    if (abierta) {
      window.addEventListener('keydown', alPresionarTecla)
      await nextTick()
      if (estadoConfirmacion.peligro) {
        botonCancelar.value?.focus()
      } else {
        botonConfirmar.value?.focus()
      }
    } else {
      window.removeEventListener('keydown', alPresionarTecla)
    }
  },
)

onBeforeUnmount(() => {
  window.removeEventListener('keydown', alPresionarTecla)
})
</script>

<template>
  <Teleport to="body">
    <Transition name="modal-confirmacion">
      <div
        v-if="estadoConfirmacion.abierta"
        class="modal-confirmacion__fondo"
        role="presentation"
        @click.self="responderConfirmacion(false)"
      >
        <div
          class="modal-confirmacion__caja"
          role="alertdialog"
          aria-modal="true"
          aria-labelledby="modal-confirmacion-titulo"
          aria-describedby="modal-confirmacion-mensaje"
        >
          <div class="modal-confirmacion__cabecera">
            <span
              class="modal-confirmacion__icono"
              :class="estadoConfirmacion.peligro ? 'modal-confirmacion__icono--peligro' : 'modal-confirmacion__icono--info'"
              aria-hidden="true"
            >
              {{ estadoConfirmacion.peligro ? '!' : '?' }}
            </span>
            <h3 id="modal-confirmacion-titulo" class="modal-confirmacion__titulo">
              {{ estadoConfirmacion.titulo }}
            </h3>
          </div>

          <p id="modal-confirmacion-mensaje" class="modal-confirmacion__mensaje">
            {{ estadoConfirmacion.mensaje }}
          </p>

          <div class="acciones acciones--fin modal-confirmacion__acciones">
            <button
              ref="botonCancelar"
              class="secondary-button"
              type="button"
              @click="responderConfirmacion(false)"
            >
              {{ estadoConfirmacion.textoCancelar }}
            </button>
            <button
              ref="botonConfirmar"
              :class="estadoConfirmacion.peligro ? 'boton-peligro' : 'primary-button'"
              type="button"
              @click="responderConfirmacion(true)"
            >
              {{ estadoConfirmacion.textoConfirmar }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-confirmacion__fondo {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: grid;
  place-items: center;
  padding: 16px;
  background: rgba(25, 38, 30, 0.42);
  backdrop-filter: blur(2px);
}

.modal-confirmacion__caja {
  width: min(440px, 100%);
  background: var(--paper, #fffefa);
  border: 1px solid var(--line, #e7e3d8);
  border-radius: 16px;
  padding: 22px 24px;
  box-shadow: 0 22px 48px rgba(25, 38, 30, 0.22);
}

.modal-confirmacion__cabecera {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 10px;
}

.modal-confirmacion__icono {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  display: grid;
  place-items: center;
  font-size: 16px;
  font-weight: 800;
  flex-shrink: 0;
}

.modal-confirmacion__icono--info {
  background: var(--green-soft, #e8efe6);
  color: var(--green, #38664f);
}

.modal-confirmacion__icono--peligro {
  background: #ffecec;
  color: #b04444;
}

.modal-confirmacion__titulo {
  margin: 0;
  font-family: Georgia, 'Times New Roman', serif !important;
  font-size: 18px;
  font-weight: 700;
  color: var(--navy, #29382f);
}

.modal-confirmacion__mensaje {
  margin: 0 0 20px;
  font-size: 14px;
  line-height: 1.5;
  color: #4b5d75;
}

.modal-confirmacion__acciones {
  gap: 10px;
}

.modal-confirmacion-enter-active,
.modal-confirmacion-leave-active {
  transition: opacity 0.16s ease;
}

.modal-confirmacion-enter-active .modal-confirmacion__caja,
.modal-confirmacion-leave-active .modal-confirmacion__caja {
  transition: transform 0.16s ease, opacity 0.16s ease;
}

.modal-confirmacion-enter-from,
.modal-confirmacion-leave-to {
  opacity: 0;
}

.modal-confirmacion-enter-from .modal-confirmacion__caja,
.modal-confirmacion-leave-to .modal-confirmacion__caja {
  transform: translateY(-8px) scale(0.97);
  opacity: 0;
}
</style>
