<script setup>
import { RouterLink } from 'vue-router'

const stats = [
  { label: 'Estudiantes activos', value: '248', change: '+12%', trend: 'up', icon: '♙', tone: 'blue' },
  { label: 'Ofertas disponibles', value: '36', change: '+8%', trend: 'up', icon: '▤', tone: 'violet' },
  { label: 'Postulaciones pendientes', value: '18', change: '−4%', trend: 'down', icon: '✓', tone: 'orange' },
  { label: 'Pasantías en curso', value: '74', change: '+16%', trend: 'up', icon: '◷', tone: 'green' },
]

const activities = [
  { initials: 'ML', name: 'María López', action: 'se postuló a', target: 'Diseño UX Junior', time: 'Hace 12 min', tone: 'pink' },
  { initials: 'EP', name: 'Estudio Pixel', action: 'publicó una nueva oferta', target: 'Marketing digital', time: 'Hace 45 min', tone: 'blue' },
  { initials: 'JG', name: 'Juan García', action: 'completó el seguimiento de', target: 'Práctica profesional', time: 'Ayer, 16:30', tone: 'orange' },
]
</script>

<template>
  <section class="welcome-row"><div><h2>Buen día, Andrea <span>✦</span></h2><p>Este es el estado de tu institución para hoy.</p></div><RouterLink class="primary-button" to="/offers">+ Publicar oferta</RouterLink></section>
  <section class="stats-grid"><article v-for="stat in stats" :key="stat.label" class="stat-card"><div class="stat-head"><span>{{ stat.label }}</span><span class="stat-icon" :class="`tone-${stat.tone}`">{{ stat.icon }}</span></div><div class="stat-value">{{ stat.value }}</div><div class="stat-change" :class="stat.trend">{{ stat.change }} <span>vs. mes anterior</span></div></article></section>
  <section class="dashboard-grid"><article class="panel activity-panel"><div class="panel-heading"><div><p class="eyebrow">ACTIVIDAD RECIENTE</p><h3>Lo que está pasando</h3></div><button class="text-button">Ver todo →</button></div><div class="activity-list"><div v-for="item in activities" :key="item.name" class="activity-item"><div class="avatar" :class="`avatar--${item.tone}`">{{ item.initials }}</div><p><strong>{{ item.name }}</strong> {{ item.action }} <strong>{{ item.target }}</strong><span>{{ item.time }}</span></p><button class="dots">•••</button></div></div></article><article class="panel progress-panel"><div class="panel-heading"><div><p class="eyebrow">AVANCE INSTITUCIONAL</p><h3>Estado de pasantías</h3></div><button class="icon-button">···</button></div><div class="donut-wrap"><div class="donut"><strong>74</strong><span>en curso</span></div><div class="legend"><p><i class="dot dot-blue"></i>En curso <strong>74</strong></p><p><i class="dot dot-light"></i>Finalizadas <strong>128</strong></p><p><i class="dot dot-pale"></i>Pendientes <strong>46</strong></p></div></div><RouterLink class="secondary-button" to="/followups">Ver seguimientos</RouterLink></article></section>
</template>
