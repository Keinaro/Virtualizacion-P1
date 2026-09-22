CREATE TABLE IF NOT EXISTS clientes (
    id        SERIAL PRIMARY KEY,
    carne     VARCHAR(20) NOT NULL UNIQUE,
    nombre    VARCHAR(160) NOT NULL,
    correo    VARCHAR(160),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);