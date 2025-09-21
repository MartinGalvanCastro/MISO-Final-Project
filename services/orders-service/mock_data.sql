-- Mock data for orders service (20+ entries)
INSERT INTO orders (id, order_number, client_id, vendor_id, items, total, status, created_at, delivery_id) VALUES
(
    'order-001',
    'ORD-12345',
    'client-001',
    'vendor-001',
    '[
        {"product_id": "prod-001", "quantity": 2, "price": 25.99},
        {"product_id": "prod-002", "quantity": 1, "price": 15.50}
    ]'::json,
    67.48,
    'created',
    '2025-09-14 10:00:00',
    'delivery-001'
),
(
    'order-002',
    'ORD-67890',
    'client-002',
    'vendor-001',
    '[
        {"product_id": "prod-003", "quantity": 1, "price": 99.99},
        {"product_id": "prod-001", "quantity": 3, "price": 25.99}
    ]'::json,
    177.96,
    'created',
    '2025-09-14 09:30:00',
    'delivery-002'
),
(
    'order-003',
    'ORD-ABCDE',
    'client-001',
    'vendor-002',
    '[
        {"product_id": "prod-004", "quantity": 5, "price": 12.99},
        {"product_id": "prod-005", "quantity": 2, "price": 45.00}
    ]'::json,
    154.95,
    'pending',
    '2025-09-14 11:15:00',
    NULL
),
(
    'order-004',
    'ORD-FGHIJ',
    'client-003',
    'vendor-002',
    '[
        {"product_id": "prod-002", "quantity": 4, "price": 15.50}
    ]'::json,
    62.00,
    'validated',
    '2025-09-14 08:45:00',
    NULL
),
(
    'order-005',
    'ORD-KLMNO',
    'client-002',
    'vendor-001',
    '[
        {"product_id": "prod-001", "quantity": 1, "price": 25.99},
        {"product_id": "prod-003", "quantity": 1, "price": 99.99},
        {"product_id": "prod-006", "quantity": 2, "price": 8.75}
    ]'::json,
    143.48,
    'rejected',
    '2025-09-14 07:20:00',
    NULL
),
(
    'order-006',
    'ORD-PQRST',
    'client-004',
    'vendor-001',
    '[
        {"product_id": "prod-007", "quantity": 3, "price": 33.25},
        {"product_id": "prod-008", "quantity": 1, "price": 78.90}
    ]'::json,
    178.65,
    'created',
    '2025-09-14 12:30:00',
    'delivery-003'
),
(
    'order-007',
    'ORD-UVWXY',
    'client-005',
    'vendor-003',
    '[
        {"product_id": "prod-009", "quantity": 2, "price": 45.50},
        {"product_id": "prod-010", "quantity": 1, "price": 120.00}
    ]'::json,
    211.00,
    'created',
    '2025-09-14 13:15:00',
    'delivery-004'
),
(
    'order-008',
    'ORD-ZABCD',
    'client-001',
    'vendor-002',
    '[
        {"product_id": "prod-004", "quantity": 2, "price": 12.99},
        {"product_id": "prod-011", "quantity": 1, "price": 55.75}
    ]'::json,
    81.73,
    'pending',
    '2025-09-14 14:00:00',
    NULL
),
(
    'order-009',
    'ORD-EFGHI',
    'client-006',
    'vendor-001',
    '[
        {"product_id": "prod-001", "quantity": 5, "price": 25.99},
        {"product_id": "prod-012", "quantity": 2, "price": 18.50}
    ]'::json,
    166.95,
    'validated',
    '2025-09-14 15:20:00',
    NULL
),
(
    'order-010',
    'ORD-JKLMN',
    'client-003',
    'vendor-003',
    '[
        {"product_id": "prod-013", "quantity": 1, "price": 89.99},
        {"product_id": "prod-014", "quantity": 3, "price": 22.33}
    ]'::json,
    156.98,
    'created',
    '2025-09-14 16:45:00',
    'delivery-005'
),
(
    'order-011',
    'ORD-OPQRS',
    'client-007',
    'vendor-002',
    '[
        {"product_id": "prod-015", "quantity": 4, "price": 11.25},
        {"product_id": "prod-002", "quantity": 2, "price": 15.50}
    ]'::json,
    76.00,
    'pending',
    '2025-09-14 17:10:00',
    NULL
),
(
    'order-012',
    'ORD-TUVWX',
    'client-002',
    'vendor-001',
    '[
        {"product_id": "prod-003", "quantity": 2, "price": 99.99},
        {"product_id": "prod-016", "quantity": 1, "price": 67.50}
    ]'::json,
    267.48,
    'created',
    '2025-09-14 18:25:00',
    'delivery-006'
),
(
    'order-013',
    'ORD-YZABC',
    'client-008',
    'vendor-003',
    '[
        {"product_id": "prod-017", "quantity": 1, "price": 134.99},
        {"product_id": "prod-018", "quantity": 2, "price": 28.75}
    ]'::json,
    192.49,
    'validated',
    '2025-09-14 19:40:00',
    NULL
),
(
    'order-014',
    'ORD-DEFGH',
    'client-004',
    'vendor-002',
    '[
        {"product_id": "prod-019", "quantity": 3, "price": 19.99},
        {"product_id": "prod-020", "quantity": 1, "price": 85.00}
    ]'::json,
    144.97,
    'created',
    '2025-09-14 20:15:00',
    'delivery-007'
),
(
    'order-015',
    'ORD-IJKLM',
    'client-005',
    'vendor-001',
    '[
        {"product_id": "prod-001", "quantity": 1, "price": 25.99},
        {"product_id": "prod-021", "quantity": 4, "price": 14.25}
    ]'::json,
    82.99,
    'pending',
    '2025-09-14 21:30:00',
    NULL
),
(
    'order-016',
    'ORD-NOPQR',
    'client-009',
    'vendor-003',
    '[
        {"product_id": "prod-022", "quantity": 2, "price": 45.50},
        {"product_id": "prod-023", "quantity": 1, "price": 98.75}
    ]'::json,
    189.75,
    'rejected',
    '2025-09-14 22:00:00',
    NULL
),
(
    'order-017',
    'ORD-STUVW',
    'client-006',
    'vendor-002',
    '[
        {"product_id": "prod-024", "quantity": 5, "price": 8.99},
        {"product_id": "prod-025", "quantity": 1, "price": 156.00}
    ]'::json,
    200.95,
    'created',
    '2025-09-15 08:15:00',
    'delivery-008'
),
(
    'order-018',
    'ORD-XYZAB',
    'client-010',
    'vendor-001',
    '[
        {"product_id": "prod-026", "quantity": 3, "price": 32.50},
        {"product_id": "prod-027", "quantity": 2, "price": 24.99}
    ]'::json,
    147.48,
    'validated',
    '2025-09-15 09:30:00',
    NULL
),
(
    'order-019',
    'ORD-CDEFG',
    'client-007',
    'vendor-003',
    '[
        {"product_id": "prod-028", "quantity": 1, "price": 199.99},
        {"product_id": "prod-029", "quantity": 2, "price": 35.25}
    ]'::json,
    270.49,
    'created',
    '2025-09-15 10:45:00',
    'delivery-009'
),
(
    'order-020',
    'ORD-HIJKL',
    'client-001',
    'vendor-002',
    '[
        {"product_id": "prod-030", "quantity": 4, "price": 16.75},
        {"product_id": "prod-004", "quantity": 2, "price": 12.99}
    ]'::json,
    92.98,
    'pending',
    '2025-09-15 11:20:00',
    NULL
),
(
    'order-021',
    'ORD-MNOPQ',
    'client-003',
    'vendor-001',
    '[
        {"product_id": "prod-031", "quantity": 1, "price": 245.00},
        {"product_id": "prod-032", "quantity": 3, "price": 18.99}
    ]'::json,
    301.97,
    'created',
    '2025-09-15 12:35:00',
    'delivery-010'
),
(
    'order-022',
    'ORD-RSTUV',
    'client-008',
    'vendor-003',
    '[
        {"product_id": "prod-033", "quantity": 2, "price": 67.50},
        {"product_id": "prod-034", "quantity": 1, "price": 123.25}
    ]'::json,
    258.25,
    'validated',
    '2025-09-15 13:50:00',
    NULL
);