CREATE TABLE IF NOT EXISTS categorias (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(80) NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE IF NOT EXISTS productos (
    id           SERIAL PRIMARY KEY,
    sku          VARCHAR(40) NOT NULL UNIQUE,
    nombre       VARCHAR(160) NOT NULL,
    categoria_id INTEGER REFERENCES categorias(id),
    precio       NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    creado_en    TIMESTAMPTZ NOT NULL DEFAULT now()
);
