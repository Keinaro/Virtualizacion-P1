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

  if (!respuesta.ok) {
    const detalle = await respuesta.text()
    throw new Error(detalle || `Error ${respuesta.status}`)
  }

  return respuesta.status === 204 ? null : respuesta.json()
}

export const api = {
  get: (ruta) => peticion(ruta),
  post: (ruta, cuerpo) => peticion(ruta, { method: 'POST', body: JSON.stringify(cuerpo) }),
  put: (ruta, cuerpo) => peticion(ruta, { method: 'PUT', body: JSON.stringify(cuerpo) }),
  delete: (ruta) => peticion(ruta, { method: 'DELETE' })
}
