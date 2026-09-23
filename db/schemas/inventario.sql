CREATE TABLE IF NOT EXISTS existencias (
    id             SERIAL PRIMARY KEY,
    sku            VARCHAR(40) NOT NULL UNIQUE,
    nombre         VARCHAR(160) NOT NULL,
    categoria      VARCHAR(80),
    precio         NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    stock          INTEGER NOT NULL CHECK (stock >= 0),
    stock_minimo   INTEGER NOT NULL DEFAULT 5 CHECK (stock_minimo >= 0),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);