<script setup>
// Área 6 — Vista de inventario: listar / crear / editar / eliminar.
import { onMounted, ref } from 'vue'
import { api } from '../services/api.js'

const productos = ref([])
const cargando = ref(false)
const error = ref('')

async function cargar () {
  cargando.value = true
  error.value = ''
  try {
    productos.value = await api.get('/inventario/productos')
  } catch (e) {
    error.value = `No se pudo cargar el inventario: ${e.message}`
  } finally {
    cargando.value = false
  }
}

onMounted(cargar)

// TODO(Área 6): formularios de crear / editar / eliminar producto.
</script>

<template>
  <h2>Inventario</h2>

  <p v-if="cargando" class="cargando">Cargando productos…</p>
  <p v-else-if="error" class="error">{{ error }}</p>

  <table v-else>
    <thead>
      <tr>
        <th>SKU</th>
        <th>Nombre</th>
        <th>Categoría</th>
        <th>Precio (Q)</th>
        <th>Stock</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="p in productos" :key="p.sku">
        <td>{{ p.sku }}</td>
        <td>{{ p.nombre }}</td>
        <td>{{ p.categoria }}</td>
        <td>{{ p.precio }}</td>
        <td>{{ p.stock }}</td>
      </tr>
      <tr v-if="productos.length === 0">
        <td colspan="5">Sin productos registrados.</td>
      </tr>
    </tbody>
  </table>
</template>
