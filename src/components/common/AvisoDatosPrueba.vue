<script setup>
import { organizacion } from '../../composables/useAuth'
</script>

<template>
  <p v-if="organizacion?.datosPrueba" class="aviso aviso--prueba" role="note">
    Estás usando una organización de prueba. Las escuelas, empresas, alumnos y convenios que ves son ficticios
    (cargados con <code>supabase/seed.sql</code>) y se marcan con la etiqueta DATOS DE PRUEBA.
  </p>
</template>
