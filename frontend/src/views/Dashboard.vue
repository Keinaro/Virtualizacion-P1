<script setup>
// Área 6 — Dashboard: total de productos, valor del inventario en Q,
// pedidos del día y alerta de stock bajo.
import { onMounted, onBeforeUnmount, nextTick, ref } from 'vue'
import { Chart, BarController, BarElement, CategoryScale, LinearScale, Tooltip } from 'chart.js'
import { api } from '../services/api.js'

Chart.register(BarController, BarElement, CategoryScale, LinearScale, Tooltip)

const resumen = ref(null)
const cargando = ref(false)
const error = ref('')

const canvasGrafica = ref(null)
let grafica = null

function formatoQuetzales (valor) {
  return Number(valor || 0).toLocaleString('es-GT', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}

function dibujarGrafica (productos) {
  if (!canvasGrafica.value) return

  const ordenados = [...productos].sort((a, b) => a.stock - b.stock)
  const colorBajo = '#dc2626'
  const colorNormal = '#0f766e'

  grafica = new Chart(canvasGrafica.value, {
    type: 'bar',
    data: {
      labels: ordenados.map((p) => p.sku),
      datasets: [{
        label: 'Stock',
        data: ordenados.map((p) => p.stock),
        backgroundColor: ordenados.map((p) =>
          p.stock <= p.stock_minimo ? colorBajo : colorNormal
        ),
        borderRadius: 4
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            title: (items) => ordenados[items[0].dataIndex].nombre,
            label: (item) => `Stock: ${item.raw}`
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: { stepSize: 5 }
        }
      }
    }
  })
}

async function cargar () {
  cargando.value = true
  error.value = ''
  try {
    const [datosResumen, productos] = await Promise.all([
      api.get('/reportes/resumen'),
      api.get('/inventario/productos')
    ])
    resumen.value = datosResumen
    cargando.value = false
    await nextTick()
    dibujarGrafica(productos)
  } catch (e) {
    error.value = `No se pudo cargar el resumen: ${e.message}`
    cargando.value = false
  }
}

onMounted(cargar)
onBeforeUnmount(() => grafica?.destroy())
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
      <p>Q {{ formatoQuetzales(resumen.valor_inventario) }}</p>
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

  <section v-if="!cargando && !error" class="grafica-contenedor">
    <h3>Stock por producto</h3>
    <div class="grafica-lienzo">
      <canvas ref="canvasGrafica"></canvas>
    </div>
  </section>
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

.grafica-contenedor {
  background: #fff;
  border-radius: 8px;
  padding: 1.25rem;
  border: 1px solid #e4e7eb;
  margin-top: 1.5rem;
}

.grafica-contenedor h3 {
  margin: 0 0 1rem;
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: #52606d;
}

.grafica-lienzo {
  height: 280px;
}
</style>
