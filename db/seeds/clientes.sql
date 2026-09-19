-- ============================================================
-- Área 4 — Seed de integrantes del grupo (BASE: clientes_db)
-- EVIDENCIA OBLIGATORIA: los carnés deben quedar sembrados en la
-- BD y verse luego en la UI y en los pedidos.
-- Idempotente gracias a ON CONFLICT.
-- TODO: reemplazar con los carnés y nombres reales del grupo.
-- ============================================================

INSERT INTO clientes (carne, nombre, correo) VALUES
    ('0000000', 'Integrante 1 — CAMBIAR', 'integrante1@url.edu.gt'),
    ('0000001', 'Integrante 2 — CAMBIAR', 'integrante2@url.edu.gt'),
    ('0000002', 'Integrante 3 — CAMBIAR', 'integrante3@url.edu.gt'),
    ('0000003', 'Integrante 4 — CAMBIAR', 'integrante4@url.edu.gt'),
    ('0000004', 'Integrante 5 — CAMBIAR', 'integrante5@url.edu.gt'),
    ('0000005', 'Integrante 6 — CAMBIAR', 'integrante6@url.edu.gt')
ON CONFLICT (carne) DO UPDATE
    SET nombre = EXCLUDED.nombre,
        correo = EXCLUDED.correo;
