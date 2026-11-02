import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import './assets/styles/styles.css'
import './assets/styles/auth.css'
import './assets/styles/education-theme.css'
import './assets/styles/app.css'

createApp(App).use(router).mount('#app')
