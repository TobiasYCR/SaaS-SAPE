import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'
import OffersView from '../views/OffersView.vue'
import ApplicationsView from '../views/ApplicationsView.vue'
import FollowupsView from '../views/FollowupsView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', redirect: '/dashboard' },
    { path: '/dashboard', component: DashboardView },
    { path: '/offers', component: OffersView },
    { path: '/applications', component: ApplicationsView },
    { path: '/followups', component: FollowupsView },
  ],
})

export default router
