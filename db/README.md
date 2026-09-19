# Datos — Área 4

Un solo motor Postgres, **una base y un usuario por microservicio** (aislamiento lógico, menor privilegio).

## Estructura

| Archivo | Qué hace |
|---|---|
| `init/01-crear-bases.sh` | Crea las 5 bases y sus usuarios al inicializar el volumen. Corre solo la primera vez (o tras `down -v`). |
| `schema.sql` | Tablas de cada base, como referencia. Cada bloque va sobre su propia base. |
| `seeds/clientes.sql` | **Carnés del equipo** — evidencia obligatoria. |
| `seeds/inventario.sql` | Productos iniciales, incluye casos de stock bajo para el dashboard. |
| `seeds/catalogo.sql` | Categorías. |

## Aplicar esquema y seeds

```bash
# Esquema (ejemplo: inventario)
docker compose exec -T db psql -U inventario_user -d inventario_db < db/schema.sql

# Seeds
docker compose exec -T db psql -U clientes_user   -d clientes_db   < db/seeds/clientes.sql
docker compose exec -T db psql -U inventario_user -d inventario_db < db/seeds/inventario.sql
docker compose exec -T db psql -U catalogo_user   -d catalogo_db   < db/seeds/catalogo.sql
```

## Probar persistencia antes de la demo

```bash
docker compose down        # SIN -v, si no se borra el volumen
docker compose up -d
# confirmar que los datos siguen ahí
docker compose exec db psql -U clientes_user -d clientes_db -c "SELECT carne, nombre FROM clientes;"
```

El volumen se llama `elquetzal_pgdata` (`docker volume ls`).
