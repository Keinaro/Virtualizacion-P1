-- ============================================================
-- Área 4 — Esquema por microservicio (referencia)
-- Cada bloque se aplica sobre SU propia base de datos.
-- Scripts idempotentes: se pueden correr más de una vez.
-- ============================================================

-- ------------------------------------------------------------
-- BASE: catalogo_db
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorias (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(80)  NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE IF NOT EXISTS productos (
    id           SERIAL PRIMARY KEY,
    sku          VARCHAR(40)  NOT NULL UNIQUE,
    nombre       VARCHAR(160) NOT NULL,
    categoria_id INTEGER      REFERENCES categorias (id),
    precio       NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    creado_en    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- BASE: inventario_db
-- El stock vive aquí; 'pedidos' lo descuenta transaccionalmente.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS existencias (
    id              SERIAL PRIMARY KEY,
    sku             VARCHAR(40)  NOT NULL UNIQUE,
    nombre          VARCHAR(160) NOT NULL,
    categoria       VARCHAR(80),
    precio          NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    stock           INTEGER      NOT NULL CHECK (stock >= 0),
    stock_minimo    INTEGER      NOT NULL DEFAULT 5,
    actualizado_en  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- BASE: clientes_db
-- Los integrantes del grupo se siembran aquí (evidencia: carné).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
    id         SERIAL PRIMARY KEY,
    carne      VARCHAR(20)  NOT NULL UNIQUE,
    nombre     VARCHAR(160) NOT NULL,
    correo     VARCHAR(160),
    creado_en  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- BASE: pedidos_db
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pedidos (
    id           SERIAL PRIMARY KEY,
    carne        VARCHAR(20)  NOT NULL,   -- integrante que creó el pedido
    estado       VARCHAR(20)  NOT NULL DEFAULT 'confirmado'
                 CHECK (estado IN ('confirmado', 'rechazado', 'anulado')),
    total        NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    creado_en    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pedido_lineas (
    id              SERIAL PRIMARY KEY,
    pedido_id       INTEGER      NOT NULL REFERENCES pedidos (id) ON DELETE CASCADE,
    sku             VARCHAR(40)  NOT NULL,
    cantidad        INTEGER      NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0)
);

CREATE INDEX IF NOT EXISTS idx_pedidos_creado_en ON pedidos (creado_en);
CREATE INDEX IF NOT EXISTS idx_pedido_lineas_pedido ON pedido_lineas (pedido_id);

-- ------------------------------------------------------------
-- BASE: reportes_db
-- Lógica de reportes definida por el grupo (Área 5).
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reportes_generados (
    id          SERIAL PRIMARY KEY,
    tipo        VARCHAR(60)  NOT NULL,
    parametros  JSONB        NOT NULL DEFAULT '{}'::jsonb,
    resultado   JSONB,
    generado_en TIMESTAMPTZ  NOT NULL DEFAULT now()
);
