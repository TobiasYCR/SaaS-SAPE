import { createRouter, createWebHistory } from 'vue-router'
import AuthView from '../views/AuthView.vue'
import { asegurarPerfil, currentUser, errorPerfil, esAdmin, initializeAuth, organizacion } from '../composables/useAuth'

// meta:
//   requiresAuth  requiere sesión
//   publicAuth    solo sin sesión (login)
//   sinOrg        pantalla para usuarios que todavía no tienen organización
//   tipo          'escuela' | 'empresa': solo ese tipo de organización
//   soloAdmin     solo escuela_admin / empresa_admin
//   titulo        título de la barra superior
const routes = [
  { path: '/', redirect: '/dashboard' },
  { path: '/login', component: AuthView, meta: { publicAuth: true } },
  { path: '/registro-organizacion', component: () => import('../views/RegistroOrganizacionView.vue'), meta: { requiresAuth: true, sinOrg: true, titulo: 'Registrar organización' } },
  { path: '/dashboard', component: () => import('../views/DashboardView.vue'), meta: { requiresAuth: true, titulo: 'Resumen general' } },
  { path: '/escuelas', component: () => import('../views/EscuelasView.vue'), meta: { requiresAuth: true, titulo: 'Escuelas' } },
  { path: '/empresas', component: () => import('../views/EmpresasView.vue'), meta: { requiresAuth: true, titulo: 'Empresas' } },
  { path: '/convenios', component: () => import('../views/ConveniosView.vue'), meta: { requiresAuth: true, titulo: 'Convenios' } },
  { path: '/convenios/:id', component: () => import('../views/ConvenioDetalleView.vue'), meta: { requiresAuth: true, titulo: 'Detalle del convenio' } },
  { path: '/alumnos', component: () => import('../views/AlumnosView.vue'), meta: { requiresAuth: true, tipo: 'escuela', titulo: 'Alumnos' } },
  { path: '/alumnos/:id', component: () => import('../views/AlumnoDetalleView.vue'), meta: { requiresAuth: true, tipo: 'escuela', titulo: 'Detalle del alumno' } },
  { path: '/inscripciones', component: () => import('../views/InscripcionesView.vue'), meta: { requiresAuth: true, titulo: 'Inscripciones' } },
  { path: '/inscripciones/:id', component: () => import('../views/InscripcionDetalleView.vue'), meta: { requiresAuth: true, titulo: 'Detalle de la inscripción' } },
  { path: '/seguimientos', component: () => import('../views/SeguimientosView.vue'), meta: { requiresAuth: true, titulo: 'Seguimientos' } },
  { path: '/organizacion', component: () => import('../views/OrganizacionView.vue'), meta: { requiresAuth: true, titulo: 'Mi organización' } },
  { path: '/change-password', component: () => import('../views/ChangePasswordView.vue'), meta: { requiresAuth: true, titulo: 'Cambiar contraseña' } },
  { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior: () => ({ top: 0 }),
})

router.beforeEach(async (to) => {
  await initializeAuth()

  if (to.meta.requiresAuth && !currentUser.value) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }
  if (!currentUser.value) return true

  await asegurarPerfil()

  // No se pudo leer el perfil (sin conexión, base caída): no se redirige; App muestra el error y permite reintentar
  if (errorPerfil.value) return to.meta.publicAuth ? '/dashboard' : true

  if (to.meta.publicAuth) return organizacion.value ? '/dashboard' : '/registro-organizacion'

  // Sin organización: solo puede registrarla o cambiar su contraseña
  if (!organizacion.value && !to.meta.sinOrg && to.path !== '/change-password') return '/registro-organizacion'
  if (organizacion.value && to.meta.sinOrg) return '/dashboard'

  if (to.meta.tipo && organizacion.value?.tipo !== to.meta.tipo) return '/dashboard'
  if (to.meta.soloAdmin && !esAdmin.value) return '/dashboard'
  return true
})

export default router
