CREATE TABLE IF NOT EXISTS pedidos (
    id        SERIAL PRIMARY KEY,
    carne     VARCHAR(20) NOT NULL,
    estado    VARCHAR(20) NOT NULL DEFAULT 'confirmado'
              CHECK (estado IN ('confirmado', 'rechazado', 'anulado')),
    total     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pedido_lineas (
    id              SERIAL PRIMARY KEY,
    pedido_id       INTEGER NOT NULL
                    REFERENCES pedidos(id) ON DELETE CASCADE,
    sku             VARCHAR(40) NOT NULL,
    cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0)
);

CREATE INDEX IF NOT EXISTS idx_pedidos_creado_en
    ON pedidos(creado_en);

CREATE INDEX IF NOT EXISTS idx_pedido_lineas_pedido
    ON pedido_lineas(pedido_id);