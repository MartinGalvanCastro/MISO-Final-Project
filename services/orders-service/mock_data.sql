-- Mock data for orders service
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
);