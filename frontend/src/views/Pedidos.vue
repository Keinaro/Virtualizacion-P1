<script setup>
// Área 6 — Vista de pedidos: crear pedido y ver historial con carné.
import { onMounted, ref } from 'vue'
import { api } from '../services/api.js'

const pedidos = ref([])
const cargando = ref(false)
const error = ref('')

async function cargar () {
  cargando.value = true
  error.value = ''
  try {
    pedidos.value = await api.get('/pedidos/pedidos')
  } catch (e) {
    error.value = `No se pudo cargar el historial: ${e.message}`
  } finally {
    cargando.value = false
  }
}

onMounted(cargar)

// TODO(Área 6): formulario de creación de pedido (productos + cantidades
// + carné del integrante). Mostrar el error 409 de stock insuficiente
// como mensaje legible, no como fallo silencioso.
</script>

<template>
  <h2>Pedidos</h2>

  <p v-if="cargando" class="cargando">Cargando pedidos…</p>
  <p v-else-if="error" class="error">{{ error }}</p>

  <table v-else>
    <thead>
      <tr>
        <th>Pedido</th>
        <th>Carné</th>
        <th>Estado</th>
        <th>Total (Q)</th>
        <th>Fecha</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="p in pedidos" :key="p.id">
        <td>{{ p.id }}</td>
        <td>{{ p.carne }}</td>
        <td>{{ p.estado }}</td>
        <td>{{ p.total }}</td>
        <td>{{ p.creado_en }}</td>
      </tr>
      <tr v-if="pedidos.length === 0">
        <td colspan="5">Sin pedidos registrados.</td>
      </tr>
    </tbody>
  </table>
</template>
