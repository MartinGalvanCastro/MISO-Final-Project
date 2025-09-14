-- Mock data for inventory service
INSERT INTO inventory (product_id, available_quantity, reserved_quantity, updated_at) VALUES
('prod-001', 50, 5, CURRENT_TIMESTAMP),
('prod-002', 25, 0, CURRENT_TIMESTAMP),
('prod-003', 15, 2, CURRENT_TIMESTAMP),
('prod-004', 100, 10, CURRENT_TIMESTAMP),
('prod-005', 8, 2, CURRENT_TIMESTAMP),
('prod-006', 200, 15, CURRENT_TIMESTAMP),
('prod-007', 75, 0, CURRENT_TIMESTAMP),
('prod-008', 30, 5, CURRENT_TIMESTAMP),
('prod-009', 5, 1, CURRENT_TIMESTAMP),
('prod-010', 150, 20, CURRENT_TIMESTAMP);