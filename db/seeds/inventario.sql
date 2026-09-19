-- ============================================================
-- Área 4 — Seed de productos (BASE: inventario_db)
-- Datos iniciales para poder demostrar el flujo de pedido
-- y la alerta de stock bajo en el dashboard.
-- ============================================================

INSERT INTO existencias (sku, nombre, categoria, precio, stock, stock_minimo) VALUES
    ('CAF-001', 'Café en grano Antigua 1 lb',   'Bebidas',    75.00, 40,  10),
    ('CAF-002', 'Café molido Cobán 1 lb',       'Bebidas',    68.50, 25,  10),
    ('TEX-001', 'Güipil bordado artesanal',     'Textiles',  450.00,  8,   3),
    ('TEX-002', 'Faja típica de Sololá',        'Textiles',  180.00, 15,   5),
    ('ART-001', 'Máscara de madera tallada',    'Artesanía', 320.00,  4,   5),
    ('ART-002', 'Cerámica de Chinautla',        'Artesanía', 210.00, 12,   5),
    ('DUL-001', 'Dulces típicos surtidos',      'Alimentos',  45.00, 60,  15),
    ('DUL-002', 'Chocolate artesanal 200 g',    'Alimentos',  55.00,  3,  10)
ON CONFLICT (sku) DO UPDATE
    SET nombre       = EXCLUDED.nombre,
        categoria    = EXCLUDED.categoria,
        precio       = EXCLUDED.precio,
        stock_minimo = EXCLUDED.stock_minimo;
