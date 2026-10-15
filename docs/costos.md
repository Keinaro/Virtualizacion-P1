# Anexo de costos: CAPEX vs OPEX — Área 6

> Comparativo en **quetzales (Q)** entre una infraestructura física
> tradicional y una alternativa basada en contenedores desplegados en nube
> para el proyecto El Quetzal.

## 0. Supuestos del análisis

El análisis parte de los requerimientos reales definidos para El Quetzal:

- VM requerida: **2 vCPU, 4 GB de RAM y 25 GB de disco**.
- Stack: **7 contenedores**: gateway nginx, 5 microservicios Flask y PostgreSQL.
- Las imágenes propias ocupan aproximadamente **1.3 GB en total**:
  5 microservicios de ~245 MB cada uno y gateway de ~74 MB.
- Horizonte de comparación: **3 años**.
- Tipo de cambio utilizado: **Q7.63682 por US$1**, Banco de Guatemala,
  vigente el 24 de septiembre de 2026.
- Los precios expresados originalmente en dólares se convierten a quetzales
  utilizando dicho tipo de cambio.
- Los valores de hardware corresponden a precios de lista y no incluyen
  posibles costos de importación, envío o impuestos adicionales.

Siguiendo el enfoque de TCO visto en clase, se reconoce que una
infraestructura física también genera costos de energía, enfriamiento,
espacio y administración. Sin embargo, estos rubros no se incorporan como
cifras al comparativo porque el proyecto no dispone de una medición real de
consumo ni de un costo de personal asignado. Esto evita utilizar
estimaciones sin respaldo.

## 1. Escenario A — Infraestructura tradicional (CAPEX)

Para representar una implementación tradicional se utiliza como referencia
un servidor Dell PowerEdge T160. Aunque su capacidad es superior al sizing
mínimo requerido por El Quetzal, representa la inversión que una
organización tendría que realizar para disponer de infraestructura física
empresarial propia.

| Concepto | Costo unitario (Q) | Cantidad | Total (Q) | Fuente |
|---|---:|---:|---:|---|
| Servidor Dell PowerEdge T160, 32 GB RAM, 1 TB SATA, 3 años ProSupport | Q33,594.29 | 1 | Q33,594.29 | Dell, precio de lista US$4,398.99 |
| Licencia Ubuntu Server | Q0.00 | 1 | Q0.00 | Canonical: Ubuntu Server sin tarifa de licencia para usuario final |
| Disco externo Toshiba Canvio Advance 2 TB para respaldo | Q1,046.17 | 1 | Q1,046.17 | Dell, precio de lista US$136.99 |
| UPS APC Back-UPS Pro 1500VA/900W | Q2,084.85 | 1 | Q2,084.85 | Dell, precio de lista US$273.00 |
| Instalación inicial | Q0.00 | 1 | Q0.00 | Implementación realizada por el equipo del proyecto |
| **Subtotal CAPEX** |  |  | **Q36,725.31** | |

### Costos recurrentes asociados

| Concepto | Costo anual (Q) | Fuente / criterio |
|---|---:|---|
| Mantenimiento de hardware | Q0.00 adicional durante los primeros 3 años | El precio del PowerEdge T160 utilizado incluye 3 años de ProSupport |
| Energía eléctrica | No cuantificado | No existe medición real de consumo del servidor en el proyecto; se evita introducir una estimación sin respaldo |
| Administración / personal | No cuantificado | Se excluye de ambos escenarios porque el proyecto no asigna un costo específico de personal |

Por lo anterior, el valor de **Q36,725.31** representa únicamente el costo
directo cuantificado de adquisición de infraestructura. El TCO real de una
solución física sería mayor al agregar energía, espacio, enfriamiento y
administración.

## 2. Escenario B — Contenedores en nube (OPEX)

El sizing del proyecto es de 2 vCPU y 4 GB de RAM. Como referencia se usa
Amazon Lightsail, cuyo paquete Linux Medium incluye **2 vCPU, 4 GB de RAM,
80 GB SSD y 4 TB de transferencia de datos por US$24 mensuales**.

Los 80 GB de almacenamiento incluidos superan los 25 GB requeridos por la
VM del proyecto.

| Concepto | Costo mensual (Q) | Costo anual (Q) | Fuente |
|---|---:|---:|---|
| Cómputo: AWS Lightsail, 2 vCPU, 4 GB RAM | Q183.28 | Q2,199.40 | Amazon Lightsail, US$24/mes |
| Almacenamiento persistente | Q0.00 adicional | Q0.00 adicional | 80 GB SSD incluidos en la instancia |
| Transferencia de datos | Q0.00 adicional | Q0.00 adicional | Hasta 4 TB incluidos en la instancia |
| Registro de imágenes | Q0.00 | Q0.00 | Docker Personal / Docker Hub con repositorios públicos |
| **Subtotal OPEX** | **Q183.28** | **Q2,199.40** | |

El almacenamiento de las imágenes propias del proyecto, aproximadamente
1.3 GB, puede mantenerse en los repositorios públicos de Docker Hub sin
costo adicional bajo el plan utilizado para el proyecto académico.

## 3. Comparativo a 3 años

La tabla presenta los costos directos cuantificados acumulados. En el
escenario tradicional la inversión se realiza desde el inicio; en nube el
costo se distribuye mensualmente.

| Año | Tradicional CAPEX acumulado (Q) | Contenedores OPEX acumulado (Q) | Diferencia (Q) |
|---|---:|---:|---:|
| 1 | Q36,725.31 | Q2,199.40 | Q34,525.91 |
| 2 | Q36,725.31 | Q4,398.81 | Q32,326.50 |
| 3 | Q36,725.31 | Q6,598.21 | Q30,127.10 |
| **TCO directo cuantificado a 3 años** | **Q36,725.31** | **Q6,598.21** | **Q30,127.10** |

Bajo estos supuestos, el escenario basado en contenedores y nube representa
aproximadamente un **82% menor costo directo cuantificado durante los
primeros tres años**.

Es importante señalar que esta comparación favorece al escenario físico en
el sentido de que todavía no se agregan sus costos de energía,
enfriamiento, espacio físico ni administración. Por otra parte, el costo de
la nube puede variar si aumenta el consumo, se agregan respaldos o se
requieren recursos superiores a los incluidos en el paquete analizado.

## 4. Beneficios operativos y de escalabilidad

- **Menor inversión inicial:** no es necesario realizar un desembolso de
  más de Q36 mil para adquirir infraestructura propia.
- **Pago según capacidad contratada:** El Quetzal puede iniciar con una
  instancia acorde con sus requerimientos actuales y aumentar capacidad
  posteriormente.
- **Despliegue reproducible:** `docker compose up` permite levantar el stack
  completo con la misma configuración en diferentes ambientes.
- **Escalabilidad selectiva:** es posible aumentar o replicar únicamente el
  microservicio que presente mayor demanda, por ejemplo `pedidos`, en lugar
  de sustituir todo un servidor físico.
- **Aislamiento de servicios:** los microservicios se ejecutan en
  contenedores independientes, reduciendo el impacto de fallos entre
  componentes.
- **Portabilidad:** las mismas imágenes pueden ejecutarse en la VM del
  proyecto o trasladarse a otro proveedor de infraestructura.
- **Menor riesgo de obsolescencia:** la renovación del hardware físico queda
  en manos del proveedor de nube.
- **Recuperación más rápida:** un contenedor puede recrearse desde su imagen
  y configuración sin reinstalar manualmente todo un servidor.

## 5. Conclusión

Para el escenario actual de **El Quetzal**, la alternativa basada en
contenedores sobre infraestructura en la nube resulta más conveniente desde
el punto de vista de costos directos y flexibilidad operativa.

El proyecto necesita únicamente 2 vCPU, 4 GB de RAM y 25 GB de
almacenamiento. Adquirir un servidor empresarial físico supone una
inversión inicial aproximada de **Q36,725.31**, mientras que una instancia
en nube con capacidad igual o superior representa aproximadamente
**Q183.28 mensuales** o **Q6,598.21 durante tres años**, manteniendo los
precios actuales.

La diferencia directa cuantificada a tres años es de aproximadamente
**Q30,127.10**, equivalente a cerca del **82%** del costo inicial del
escenario tradicional. Además, el modelo OPEX evita una inversión inicial
elevada y facilita el crecimiento de la aplicación conforme aumente su
demanda.

Por estas razones, para El Quetzal se recomienda mantener la arquitectura
de microservicios contenerizados y utilizar infraestructura bajo demanda
para una eventual implementación productiva. Una infraestructura física
propia tendría mayor sentido únicamente si, en el futuro, el volumen de
trabajo fuera constante y suficientemente alto para justificar la
inversión, operación y mantenimiento del hardware durante un horizonte
mayor.

## 6. Fuentes consultadas

1. Banco de Guatemala. Tipo de Cambio de Referencia vigente al
   24 de septiembre de 2026: Q7.63682 por US$1.
2. Dell Technologies. PowerEdge T160: configuración con 32 GB de RAM,
   1 TB SATA y 3 años de ProSupport.
3. Dell Technologies. Toshiba Canvio Advance, disco externo de 2 TB.
4. Dell Technologies. APC Back-UPS Pro 1500VA/900W.
5. Amazon Web Services. Amazon Lightsail — paquete Linux Medium:
   2 vCPU, 4 GB RAM, 80 GB SSD y 4 TB de transferencia.
6. Docker. Docker Personal / Docker Hub, plan gratuito para uso individual
   y educativo.
7. Canonical. Ubuntu Server: sistema operativo sin tarifa de licencia para
   usuario final.
