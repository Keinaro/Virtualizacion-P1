<script setup>
// Área 6 — Vista de inventario:
// listar, crear, editar y eliminar productos.

import { onMounted, ref } from 'vue'
import { api } from '../services/api.js'

// ------------------------------------------------------------
// Datos principales
// ------------------------------------------------------------

const productos = ref([])
const cargando = ref(false)
const error = ref('')

const guardando = ref(false)
const mensaje = ref('')
const errorFormulario = ref('')

// Controla si estamos creando o editando
const editando = ref(false)
const skuOriginal = ref('')

// ------------------------------------------------------------
// Formulario
// ------------------------------------------------------------

const formulario = ref({
  sku: '',
  nombre: '',
  categoria: '',
  precio: null,
  stock: null,
  stock_minimo: null
})

// ------------------------------------------------------------
// Cargar productos
// ------------------------------------------------------------

async function cargarProductos () {
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

// ------------------------------------------------------------
// Limpiar formulario
// ------------------------------------------------------------

function limpiarFormulario () {
  formulario.value = {
    sku: '',
    nombre: '',
    categoria: '',
    precio: null,
    stock: null,
    stock_minimo: null
  }

  editando.value = false
  skuOriginal.value = ''
  errorFormulario.value = ''
}

// ------------------------------------------------------------
// Validar formulario
// ------------------------------------------------------------

function validarFormulario () {
  if (!formulario.value.sku.trim()) {
    return 'Debe ingresar el SKU.'
  }

  if (!formulario.value.nombre.trim()) {
    return 'Debe ingresar el nombre del producto.'
  }

  if (!formulario.value.categoria.trim()) {
    return 'Debe ingresar la categoría.'
  }

  if (
    formulario.value.precio === null ||
    formulario.value.precio < 0
  ) {
    return 'El precio debe ser un valor válido.'
  }

  if (
    formulario.value.stock === null ||
    formulario.value.stock < 0
  ) {
    return 'El stock debe ser cero o mayor.'
  }

  if (
    formulario.value.stock_minimo === null ||
    formulario.value.stock_minimo < 0
  ) {
    return 'El stock mínimo debe ser cero o mayor.'
  }

  return ''
}

// ------------------------------------------------------------
// Crear o actualizar producto
// ------------------------------------------------------------

async function guardarProducto () {
  mensaje.value = ''
  errorFormulario.value = ''

  const validacion = validarFormulario()

  if (validacion) {
    errorFormulario.value = validacion
    return
  }

  guardando.value = true

  try {
    if (editando.value) {
      // ACTUALIZAR
      const datosActualizados = {
        nombre: formulario.value.nombre.trim(),
        categoria: formulario.value.categoria.trim(),
        precio: Number(formulario.value.precio),
        stock: Number(formulario.value.stock),
        stock_minimo: Number(formulario.value.stock_minimo)
      }

      await api.put(
        `/inventario/productos/${encodeURIComponent(skuOriginal.value)}`,
        datosActualizados
      )

      mensaje.value = 'Producto actualizado correctamente.'
    } else {
      // CREAR
      const nuevoProducto = {
        sku: formulario.value.sku.trim(),
        nombre: formulario.value.nombre.trim(),
        categoria: formulario.value.categoria.trim(),
        precio: Number(formulario.value.precio),
        stock: Number(formulario.value.stock),
        stock_minimo: Number(formulario.value.stock_minimo)
      }

      await api.post('/inventario/productos', nuevoProducto)

      mensaje.value = 'Producto creado correctamente.'
    }

    limpiarFormulario()
    await cargarProductos()
  } catch (e) {
    if (e.status === 409) {
      errorFormulario.value =
        `No se pudo guardar el producto porque el SKU ya existe. ${e.message}`
    } else if (e.status === 404) {
      errorFormulario.value =
        `El producto que intenta editar no existe. ${e.message}`
    } else if (e.status === 400) {
      errorFormulario.value =
        `Los datos ingresados no son válidos. ${e.message}`
    } else {
      errorFormulario.value =
        `No se pudo guardar el producto: ${e.message}`
    }
  } finally {
    guardando.value = false
  }
}

// ------------------------------------------------------------
// Cargar producto en el formulario para editar
// ------------------------------------------------------------

function editarProducto (producto) {
  editando.value = true
  skuOriginal.value = producto.sku

  formulario.value = {
    sku: producto.sku,
    nombre: producto.nombre,
    categoria: producto.categoria,
    precio: Number(producto.precio),
    stock: Number(producto.stock),
    stock_minimo: Number(producto.stock_minimo)
  }

  mensaje.value = ''
  errorFormulario.value = ''

  window.scrollTo({
    top: 0,
    behavior: 'smooth'
  })
}

// ------------------------------------------------------------
// Eliminar producto
// ------------------------------------------------------------

async function eliminarProducto (producto) {
  const confirmar = window.confirm(
    `¿Está seguro de eliminar el producto ${producto.nombre} (${producto.sku})?`
  )

  if (!confirmar) {
    return
  }

  mensaje.value = ''
  error.value = ''

  try {
    await api.delete(
      `/inventario/productos/${encodeURIComponent(producto.sku)}`
    )

    mensaje.value = 'Producto eliminado correctamente.'

    await cargarProductos()
  } catch (e) {
    if (e.status === 404) {
      error.value = 'El producto que intenta eliminar ya no existe.'
    } else {
      error.value = `No se pudo eliminar el producto: ${e.message}`
    }
  }
}

// ------------------------------------------------------------

onMounted(cargarProductos)
</script>

<template>
  <div class="pagina">
    <h2>Inventario</h2>

    <!-- FORMULARIO -->
    <section class="tarjeta">
      <h3>
        {{ editando ? 'Editar producto' : 'Crear nuevo producto' }}
      </h3>

      <form @submit.prevent="guardarProducto">
        <div class="formulario-grid">
          <div class="campo">
            <label for="sku">SKU</label>

            <input
              id="sku"
              v-model="formulario.sku"
              type="text"
              placeholder="Ej. CAF-003"
              :disabled="editando"
            >
          </div>

          <div class="campo">
            <label for="nombre">Nombre</label>

            <input
              id="nombre"
              v-model="formulario.nombre"
              type="text"
              placeholder="Ej. Café artesanal"
            >
          </div>

          <div class="campo">
            <label for="categoria">Categoría</label>

            <input
              id="categoria"
              v-model="formulario.categoria"
              type="text"
              placeholder="Ej. Bebidas"
            >
          </div>

          <div class="campo">
            <label for="precio">Precio (Q)</label>

            <input
              id="precio"
              v-model.number="formulario.precio"
              type="number"
              min="0"
              step="0.01"
              placeholder="85.00"
            >
          </div>

          <div class="campo">
            <label for="stock">Stock</label>

            <input
              id="stock"
              v-model.number="formulario.stock"
              type="number"
              min="0"
              placeholder="20"
            >
          </div>

          <div class="campo">
            <label for="stock-minimo">Stock mínimo</label>

            <input
              id="stock-minimo"
              v-model.number="formulario.stock_minimo"
              type="number"
              min="0"
              placeholder="5"
            >
          </div>
        </div>

        <div class="acciones">
          <button
            type="submit"
            :disabled="guardando"
          >
            {{
              guardando
                ? 'Guardando...'
                : editando
                  ? 'Guardar cambios'
                  : 'Crear producto'
            }}
          </button>

          <button
            v-if="editando"
            type="button"
            class="boton-secundario"
            @click="limpiarFormulario"
          >
            Cancelar edición
          </button>
        </div>
      </form>

      <p
        v-if="errorFormulario"
        class="error"
      >
        {{ errorFormulario }}
      </p>

      <p
        v-if="mensaje"
        class="exito"
      >
        {{ mensaje }}
      </p>
    </section>

    <!-- LISTADO -->
    <section class="tarjeta">
      <h3>Productos registrados</h3>

      <p
        v-if="cargando"
        class="cargando"
      >
        Cargando inventario…
      </p>

      <p
        v-else-if="error"
        class="error"
      >
        {{ error }}
      </p>

      <div
        v-else
        class="tabla-contenedor"
      >
        <table>
          <thead>
            <tr>
              <th>SKU</th>
              <th>Nombre</th>
              <th>Categoría</th>
              <th>Precio (Q)</th>
              <th>Stock</th>
              <th>Stock mínimo</th>
              <th>Actualizado</th>
              <th>Acciones</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="producto in productos"
              :key="producto.id || producto.sku"
            >
              <td>{{ producto.sku }}</td>

              <td>{{ producto.nombre }}</td>

              <td>{{ producto.categoria }}</td>

              <td>
                {{ Number(producto.precio).toFixed(2) }}
              </td>

              <td>
                <span
                  :class="{
                    'stock-bajo':
                      Number(producto.stock) <=
                      Number(producto.stock_minimo)
                  }"
                >
                  {{ producto.stock }}
                </span>
              </td>

              <td>{{ producto.stock_minimo }}</td>

              <td>{{ producto.actualizado_en }}</td>

              <td class="acciones-tabla">
                <button
                  type="button"
                  class="boton-editar"
                  @click="editarProducto(producto)"
                >
                  Editar
                </button>

                <button
                  type="button"
                  class="boton-eliminar"
                  @click="eliminarProducto(producto)"
                >
                  Eliminar
                </button>
              </td>
            </tr>

            <tr v-if="productos.length === 0">
              <td colspan="8">
                No hay productos registrados.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
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

.formulario-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 14px;
}

.campo {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.campo label {
  font-weight: 600;
}

.campo input {
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: 6px;
}

.campo input:disabled {
  background: #eeeeee;
  cursor: not-allowed;
}

.acciones {
  display: flex;
  gap: 12px;
  margin-top: 18px;
}

button {
  padding: 9px 14px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

button[type='submit'] {
  background: #16877c;
  color: white;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.boton-secundario {
  background: #e8e8e8;
}

.boton-editar {
  background: #e8e8e8;
}

.boton-eliminar {
  background: #c0392b;
  color: white;
}

.acciones-tabla {
  display: flex;
  gap: 8px;
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

.tabla-contenedor {
  overflow-x: auto;
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

.stock-bajo {
  background: #fde2e2;
  color: #a32121;
  font-weight: bold;
  padding: 4px 8px;
  border-radius: 5px;
}

@media (max-width: 800px) {
  .formulario-grid {
    grid-template-columns: 1fr;
  }

  .acciones {
    flex-direction: column;
  }
}
</style>