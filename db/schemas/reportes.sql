CREATE TABLE IF NOT EXISTS reportes_generados (
    id          SERIAL PRIMARY KEY,
    tipo        VARCHAR(60) NOT NULL,
    parametros  JSONB NOT NULL DEFAULT '{}'::jsonb,
    resultado   JSONB,
    generado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);