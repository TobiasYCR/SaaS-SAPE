<script setup>
import { ref, computed } from 'vue'
const query = ref('')
const status = ref('Todas')
const offers = [
  { role: 'Diseño UX Junior', company: 'Estudio Pixel', location: 'Remoto', spots: 2, status: 'Activa', posted: 'Hace 2 días', color: 'violet' },
  { role: 'Asistente de marketing', company: 'Nube Agencia', location: 'Córdoba', spots: 1, status: 'Activa', posted: 'Hace 5 días', color: 'blue' },
  { role: 'Soporte técnico', company: 'Cooperativa Norte', location: 'Rosario', spots: 3, status: 'En revisión', posted: 'Hace 1 semana', color: 'orange' },
  { role: 'Administración contable', company: 'Grupo Delta', location: 'Mendoza', spots: 1, status: 'Cerrada', posted: 'Hace 2 semanas', color: 'green' },
]
const filteredOffers = computed(() => offers.filter((offer) => (status.value === 'Todas' || offer.status === status.value) && `${offer.role} ${offer.company}`.toLowerCase().includes(query.value.toLowerCase())))
</script>

<template><section class="page-intro"><div><p>Gestiona las oportunidades para tus estudiantes</p><h2>Ofertas de pasantía</h2></div><button class="primary-button">+ Nueva oferta</button></section><section class="panel table-panel"><div class="toolbar"><label class="search-field">⌕<input v-model="query" placeholder="Buscar por puesto o empresa..." /></label><select v-model="status"><option>Todas</option><option>Activa</option><option>En revisión</option><option>Cerrada</option></select><button class="filter-button">☷ Filtros</button></div><div class="table-wrap"><table><thead><tr><th>OFERTA</th><th>EMPRESA</th><th>UBICACIÓN</th><th>VACANTES</th><th>ESTADO</th><th>PUBLICADA</th><th></th></tr></thead><tbody><tr v-for="offer in filteredOffers" :key="offer.role"><td><div class="offer-title"><span class="company-mark" :class="`mark-${offer.color}`">✦</span><strong>{{ offer.role }}</strong></div></td><td>{{ offer.company }}</td><td>{{ offer.location }}</td><td>{{ offer.spots }}</td><td><span class="status-pill" :class="`status-${offer.status.toLowerCase().replace(' ', '-')}`">{{ offer.status }}</span></td><td>{{ offer.posted }}</td><td><button class="dots">•••</button></td></tr></tbody></table></div><div class="table-footer">Mostrando {{ filteredOffers.length }} de 36 ofertas <span>‹ &nbsp; 1 &nbsp; 2 &nbsp; 3 &nbsp; ... &nbsp; 6 &nbsp; ›</span></div></section></template>
