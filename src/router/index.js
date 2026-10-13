import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'
import OffersView from '../views/OffersView.vue'
import ApplicationsView from '../views/ApplicationsView.vue'
import FollowupsView from '../views/FollowupsView.vue'
import AuthView from '../views/AuthView.vue'
import ChangePasswordView from '../views/ChangePasswordView.vue'
import { currentUser, initializeAuth } from '../auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/dashboard' },
    { path: '/login', component: AuthView, meta: { publicAuth: true } },
    { path: '/dashboard', component: DashboardView, meta: { requiresAuth: true } },
    { path: '/offers', component: OffersView, meta: { requiresAuth: true } },
    { path: '/applications', component: ApplicationsView, meta: { requiresAuth: true } },
    { path: '/followups', component: FollowupsView, meta: { requiresAuth: true } },
    { path: '/change-password', component: ChangePasswordView, meta: { requiresAuth: true } },
  ],
})

router.beforeEach(async (to) => {
  await initializeAuth()

  if (to.meta.requiresAuth && !currentUser.value) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }

  if (to.meta.publicAuth && currentUser.value) {
    return '/dashboard'
  }
})

export default router
