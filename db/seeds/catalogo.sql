-- ============================================================
-- Área 4 — Seed de catálogo (BASE: catalogo_db)
-- ============================================================

INSERT INTO categorias (nombre, descripcion) VALUES
    ('Bebidas',   'Café y bebidas típicas de Guatemala'),
    ('Textiles',  'Tejidos y bordados artesanales'),
    ('Artesanía', 'Piezas talladas y cerámica'),
    ('Alimentos', 'Dulces típicos y productos comestibles')
ON CONFLICT (nombre) DO UPDATE
    SET descripcion = EXCLUDED.descripcion;
