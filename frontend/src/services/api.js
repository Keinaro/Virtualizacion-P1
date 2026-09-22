// ============================================================
// Área 6 — Cliente HTTP centralizado.
// La URL base vive SOLO aquí: cambiar de entorno (dev -> VM) es
// un único cambio. Siempre se llama a través del gateway,
// nunca directo a un microservicio.
// ============================================================

const BASE_URL = '/api'

async function peticion (ruta, opciones = {}) {
  const respuesta = await fetch(`${BASE_URL}${ruta}`, {
    headers: { 'Content-Type': 'application/json' },
    ...opciones
  })

  let datos = null

  if (respuesta.status !== 204) {
    const tipoContenido = respuesta.headers.get('content-type') || ''

    if (tipoContenido.includes('application/json')) {
      datos = await respuesta.json()
    } else {
      datos = await respuesta.text()
    }
  }

  if (!respuesta.ok) {
    let detalle = `Error ${respuesta.status}`

    if (typeof datos === 'string' && datos) {
      detalle = datos
    } else if (datos && typeof datos === 'object') {
      detalle =
        datos.error ||
        datos.mensaje ||
        datos.message ||
        JSON.stringify(datos)
    }

    const error = new Error(detalle)
    error.status = respuesta.status
    throw error
  }

  return datos
}

export const api = {
  get: (ruta) =>
    peticion(ruta),

  post: (ruta, cuerpo) =>
    peticion(ruta, {
      method: 'POST',
      body: JSON.stringify(cuerpo)
    }),

  put: (ruta, cuerpo) =>
    peticion(ruta, {
      method: 'PUT',
      body: JSON.stringify(cuerpo)
    }),

  delete: (ruta) =>
    peticion(ruta, {
      method: 'DELETE'
    })
}