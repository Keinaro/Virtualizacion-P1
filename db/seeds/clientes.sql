-- ============================================================
-- Área 4 — Seed de integrantes del grupo (BASE: clientes_db)
-- EVIDENCIA OBLIGATORIA: los carnés deben quedar sembrados en la
-- BD y verse luego en la UI y en los pedidos.
-- Idempotente gracias a ON CONFLICT.
-- ============================================================

INSERT INTO clientes (carne, nombre, correo) VALUES
    ('1200022', 'Daniel', 'jdpazo@correo.url.edu.gt'),
    ('1230222', 'Giancarlo', 'gortega@correo.url.edu.gt'),
    ('1177523', 'George', 'Jfmunozp@correo.url.edu.gt'),
    ('1248823', 'Julio', 'jjroblesg@correo.url.edu.gt'),
    ('1078123', 'Sofia', 'asasturiast@correo.url.edu.gt'),
    ('1067423', 'Lucia', 'alchavezp@correo.url.edu.gt')
ON CONFLICT (carne) DO UPDATE
    SET nombre = EXCLUDED.nombre,
        correo = EXCLUDED.correo;
