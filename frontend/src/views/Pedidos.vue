<script setup>
// Área 6 — Vista de pedidos: crear pedido y ver historial con carné.

import { onMounted, ref } from 'vue'
import { api } from '../services/api.js'

const pedidos = ref([])
const cargando = ref(false)
const error = ref('')

// Formulario de creación
const carne = ref('')
const lineas = ref([
  {
    sku: '',
    cantidad: 1
  }
])

const enviando = ref(false)
const mensaje = ref('')
const errorCreacion = ref('')

// ------------------------------------------------------------
// Cargar historial de pedidos
// ------------------------------------------------------------

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

// ------------------------------------------------------------
// Agregar otra línea al pedido
// ------------------------------------------------------------

function agregarLinea () {
  lineas.value.push({
    sku: '',
    cantidad: 1
  })
}

// ------------------------------------------------------------
// Eliminar una línea del pedido
// ------------------------------------------------------------

function eliminarLinea (indice) {
  if (lineas.value.length > 1) {
    lineas.value.splice(indice, 1)
  }
}

// ------------------------------------------------------------
// Crear pedido
// ------------------------------------------------------------

async function crearPedido () {
  mensaje.value = ''
  errorCreacion.value = ''

  // Validar carné
  if (!carne.value.trim()) {
    errorCreacion.value = 'Debe ingresar el carné.'
    return
  }

  // Validar productos
  for (const linea of lineas.value) {
    if (!linea.sku.trim()) {
      errorCreacion.value = 'Todos los productos deben tener un SKU.'
      return
    }

    if (!linea.cantidad || linea.cantidad <= 0) {
      errorCreacion.value = 'La cantidad debe ser mayor que cero.'
      return
    }
  }

  const nuevoPedido = {
    carne: carne.value.trim(),
    lineas: lineas.value.map(linea => ({
      sku: linea.sku.trim(),
      cantidad: Number(linea.cantidad)
    }))
  }

  enviando.value = true

  try {
    await api.post('/pedidos/pedidos', nuevoPedido)

    mensaje.value = 'Pedido creado correctamente.'

    // Limpiar formulario
    carne.value = ''
    lineas.value = [
      {
        sku: '',
        cantidad: 1
      }
    ]

    // Volver a cargar historial
    await cargar()
  } catch (e) {
    if (e.status === 409) {
      errorCreacion.value =
        `No se pudo crear el pedido por falta de stock. ${e.message}`
    } else if (e.status === 400) {
      errorCreacion.value =
        `Los datos del pedido no son válidos. ${e.message}`
    } else {
      errorCreacion.value =
        `No se pudo crear el pedido: ${e.message}`
    }
  } finally {
    enviando.value = false
  }
}

onMounted(cargar)
</script>

<template>
  <div class="pagina">
    <h2>Pedidos</h2>

    <!-- FORMULARIO PARA CREAR PEDIDO -->
    <section class="tarjeta">
      <h3>Crear nuevo pedido</h3>

      <form @submit.prevent="crearPedido">
        <div class="campo">
          <label for="carne">Carné</label>

          <input
            id="carne"
            v-model="carne"
            type="text"
            placeholder="Ej. 1234526"
          >
        </div>

        <h4>Productos</h4>

        <div
          v-for="(linea, indice) in lineas"
          :key="indice"
          class="linea-producto"
        >
          <div class="campo">
            <label>SKU</label>

            <input
              v-model="linea.sku"
              type="text"
              placeholder="Ej. PROD-01"
            >
          </div>

          <div class="campo">
            <label>Cantidad</label>

            <input
              v-model.number="linea.cantidad"
              type="number"
              min="1"
            >
          </div>

          <button
            v-if="lineas.length > 1"
            type="button"
            class="boton-eliminar"
            @click="eliminarLinea(indice)"
          >
            Eliminar
          </button>
        </div>

        <div class="acciones">
          <button
            type="button"
            class="boton-secundario"
            @click="agregarLinea"
          >
            + Agregar producto
          </button>

          <button
            type="submit"
            :disabled="enviando"
          >
            {{ enviando ? 'Creando...' : 'Crear pedido' }}
          </button>
        </div>
      </form>

      <p
        v-if="mensaje"
        class="exito"
      >
        {{ mensaje }}
      </p>

      <p
        v-if="errorCreacion"
        class="error"
      >
        {{ errorCreacion }}
      </p>
    </section>

    <!-- HISTORIAL -->
    <section class="tarjeta">
      <h3>Historial de pedidos</h3>

      <p
        v-if="cargando"
        class="cargando"
      >
        Cargando pedidos…
      </p>

      <p
        v-else-if="error"
        class="error"
      >
        {{ error }}
      </p>

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
          <tr
            v-for="p in pedidos"
            :key="p.id"
          >
            <td>{{ p.id }}</td>
            <td>{{ p.carne }}</td>
            <td>{{ p.estado }}</td>
            <td>{{ p.total }}</td>
            <td>{{ p.creado_en }}</td>
          </tr>

          <tr v-if="pedidos.length === 0">
            <td colspan="5">
              Sin pedidos registrados.
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<style scoped>
.pagina {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.tarjeta {
  background: white;
  padding: 24px;
  border-radius: 10px;
}

.campo {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 14px;
}

.campo label {
  font-weight: 600;
}

.campo input {
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: 6px;
}

.linea-producto {
  display: grid;
  grid-template-columns: 2fr 1fr auto;
  gap: 12px;
  align-items: end;
  margin-bottom: 12px;
}

.acciones {
  display: flex;
  gap: 12px;
  margin-top: 16px;
}

button {
  padding: 10px 16px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

button[type='submit'] {
  background: #16877c;
  color: white;
}

.boton-secundario {
  background: #e8e8e8;
}

.boton-eliminar {
  background: #c0392b;
  color: white;
  margin-bottom: 14px;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error {
  background: #fde2e2;
  color: #a32121;
  padding: 12px;
  border-radius: 6px;
  margin-top: 14px;
}

.exito {
  background: #e1f5e8;
  color: #186a3b;
  padding: 12px;
  border-radius: 6px;
  margin-top: 14px;
}

.cargando {
  color: #666;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 15px;
}

th,
td {
  text-align: left;
  padding: 12px;
  border-bottom: 1px solid #ddd;
}

th {
  background: #f5f5f5;
}

@media (max-width: 700px) {
  .linea-producto {
    grid-template-columns: 1fr;
  }

  .acciones {
    flex-direction: column;
  }
}
</style>