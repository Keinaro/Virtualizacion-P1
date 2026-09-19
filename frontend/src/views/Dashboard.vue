<script setup>
// Área 6 — Dashboard: total de productos, valor del inventario en Q,
// pedidos del día y alerta de stock bajo.
import { onMounted, ref } from 'vue'
import { api } from '../services/api.js'

const resumen = ref(null)
const cargando = ref(false)
const error = ref('')

async function cargar () {
  cargando.value = true
  error.value = ''
  try {
    resumen.value = await api.get('/reportes/resumen')
  } catch (e) {
    error.value = `No se pudo cargar el resumen: ${e.message}`
  } finally {
    cargando.value = false
  }
}

onMounted(cargar)
</script>

<template>
  <h2>Dashboard</h2>

  <p v-if="cargando" class="cargando">Cargando resumen…</p>
  <p v-else-if="error" class="error">{{ error }}</p>

  <div v-else-if="resumen" class="tarjetas">
    <article>
      <h3>Productos</h3>
      <p>{{ resumen.total_productos }}</p>
    </article>
    <article>
      <h3>Valor del inventario</h3>
      <p>Q {{ resumen.valor_inventario }}</p>
    </article>
    <article>
      <h3>Pedidos de hoy</h3>
      <p>{{ resumen.pedidos_hoy }}</p>
    </article>
    <article>
      <h3>Stock bajo</h3>
      <p>{{ resumen.stock_bajo }}</p>
    </article>
  </div>
</template>

<style scoped>
.tarjetas {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.tarjetas article {
  background: #fff;
  border-radius: 8px;
  padding: 1rem 1.25rem;
  border: 1px solid #e4e7eb;
}

.tarjetas h3 {
  margin: 0 0 0.5rem;
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #52606d;
}

.tarjetas p {
  margin: 0;
  font-size: 1.75rem;
  font-weight: 600;
}
</style>
