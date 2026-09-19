import { createRouter, createWebHistory } from 'vue-router'

import Inventario from './views/Inventario.vue'
import Pedidos from './views/Pedidos.vue'
import Dashboard from './views/Dashboard.vue'

const routes = [
  { path: '/', redirect: '/dashboard' },
  { path: '/dashboard', name: 'dashboard', component: Dashboard },
  { path: '/inventario', name: 'inventario', component: Inventario },
  { path: '/pedidos', name: 'pedidos', component: Pedidos }
]

export default createRouter({
  history: createWebHistory(),
  routes
})
