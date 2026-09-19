# Anexo de costos: CAPEX vs OPEX — Área 6

> Comparativo en **quetzales (Q)** entre infraestructura tradicional y
> contenedores para El Quetzal. Usar cifras realistas y justificadas
> (cotizaciones, precios de lista, tarifas de nube), no estimaciones sueltas.

## 1. Escenario A — Infraestructura tradicional (CAPEX)

| Concepto | Costo unitario (Q) | Cantidad | Total (Q) | Fuente |
|---|---|---|---|---|
| Servidor físico | | | | |
| Licencias de SO | | | | |
| Almacenamiento / respaldo | | | | |
| UPS y red | | | | |
| Instalación inicial | | | | |
| **Subtotal CAPEX** | | | | |

Costos recurrentes asociados (anuales):

| Concepto | Costo anual (Q) | Fuente |
|---|---|---|
| Mantenimiento de hardware | | |
| Energía eléctrica | | |
| Administración / personal | | |

## 2. Escenario B — Contenedores (OPEX)

| Concepto | Costo mensual (Q) | Costo anual (Q) | Fuente |
|---|---|---|---|
| Cómputo (VM / instancia) | | | |
| Almacenamiento persistente | | | |
| Transferencia de datos | | | |
| Registro de imágenes | | | |
| **Subtotal OPEX** | | | |

## 3. Comparativo a 3 años

| Año | Tradicional (Q) | Contenedores (Q) | Diferencia (Q) |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| **Total** | | | |

## 4. Beneficios operativos y de escalabilidad

- **Despliegue reproducible:** `docker compose up` levanta el stack completo;
  no hay pasos manuales que se olviden entre ambientes.
- **Escalabilidad selectiva:** se replica solo el microservicio saturado
  (ej. `pedidos` en temporada alta), no el servidor entero.
- **Aislamiento de fallos:** un servicio caído no arrastra a los demás.
- **Portabilidad:** la misma imagen corre en la VM de desarrollo y en nube.
- **Tiempo de recuperación:** recrear un contenedor toma segundos frente a
  reinstalar un servidor.

## 5. Conclusión

> TODO(Área 6): recomendación fundamentada para El Quetzal según los números
> de las tablas anteriores.
