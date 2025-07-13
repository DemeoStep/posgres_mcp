-- 02-insert-test-data.sql
-- Insert comprehensive test data for MCP server testing

-- Insert categories first (referenced by products)
INSERT INTO sales.categories (name, description) VALUES
('Electronics', 'Electronic devices and gadgets'),
('Books', 'Physical and digital books'),
('Clothing', 'Apparel and accessories'),
('Home & Garden', 'Home improvement and gardening supplies'),
('Sports', 'Sports equipment and accessories'),
('Toys', 'Toys and games for all ages');

-- Insert test users
INSERT INTO users (username, email, first_name, last_name, active, birth_date, salary, created_at) VALUES
('john_doe', 'john.doe@example.com', 'John', 'Doe', true, '1990-05-15', 75000.00, '2023-01-15 10:30:00'),
('jane_smith', 'jane.smith@example.com', 'Jane', 'Smith', true, '1988-08-22', 82000.00, '2023-02-01 14:15:00'),
('bob_wilson', 'bob.wilson@example.com', 'Bob', 'Wilson', false, '1992-12-03', 68000.00, '2023-02-10 09:45:00'),
('alice_brown', 'alice.brown@example.com', 'Alice', 'Brown', true, '1985-03-18', 95000.00, '2023-01-20 16:20:00'),
('charlie_davis', 'charlie.davis@example.com', 'Charlie', 'Davis', true, '1993-07-09', 72000.00, '2023-03-01 11:10:00'),
('diana_miller', 'diana.miller@example.com', 'Diana', 'Miller', true, '1987-11-14', 89000.00, '2023-02-15 13:30:00'),
('frank_garcia', 'frank.garcia@example.com', 'Frank', 'Garcia', false, '1991-04-27', 71000.00, '2023-01-10 08:45:00'),
('grace_martinez', 'grace.martinez@example.com', 'Grace', 'Martinez', true, '1989-09-12', 77000.00, '2023-02-25 15:55:00'),
('henry_rodriguez', 'henry.rodriguez@example.com', 'Henry', 'Rodriguez', true, '1994-01-30', 65000.00, '2023-03-05 12:20:00'),
('iris_lopez', 'iris.lopez@example.com', 'Iris', 'Lopez', true, '1986-06-08', 91000.00, '2023-01-25 17:40:00');

-- Insert products
INSERT INTO sales.products (name, description, price, category_id, in_stock) VALUES
-- Electronics (category_id = 1)
('Laptop Pro 15"', 'High-performance laptop with 16GB RAM', 1299.99, 1, true),
('Wireless Headphones', 'Noise-cancelling bluetooth headphones', 249.99, 1, true),
('Smartphone X', 'Latest flagship smartphone with dual camera', 899.99, 1, false),
('Tablet Air', 'Lightweight tablet with 10-hour battery', 599.99, 1, true),
('Smart Watch', 'Fitness tracking smartwatch with GPS', 399.99, 1, true),

-- Books (category_id = 2)
('The Data Science Handbook', 'Comprehensive guide to data science', 49.99, 2, true),
('Modern Web Development', 'Learn React, Node.js, and MongoDB', 39.99, 2, true),
('Machine Learning Basics', 'Introduction to ML algorithms', 44.99, 2, true),
('Database Design Principles', 'SQL and NoSQL database design', 54.99, 2, false),

-- Clothing (category_id = 3)
('Cotton T-Shirt', 'Comfortable 100% cotton t-shirt', 19.99, 3, true),
('Denim Jeans', 'Classic blue denim jeans', 79.99, 3, true),
('Winter Jacket', 'Waterproof winter jacket', 149.99, 3, true),
('Running Shoes', 'Lightweight running shoes', 129.99, 3, true),

-- Home & Garden (category_id = 4)
('Coffee Maker', 'Programmable 12-cup coffee maker', 89.99, 4, true),
('Garden Hose', '50ft expandable garden hose', 34.99, 4, true),
('Desk Lamp', 'LED desk lamp with USB charging', 45.99, 4, false),

-- Sports (category_id = 5)
('Tennis Racket', 'Professional tennis racket', 199.99, 5, true),
('Yoga Mat', 'Non-slip exercise yoga mat', 29.99, 5, true),
('Basketball', 'Official size basketball', 24.99, 5, true),

-- Toys (category_id = 6)
('Building Blocks Set', '500-piece building blocks', 59.99, 6, true),
('Board Game Deluxe', 'Strategy board game for 2-6 players', 39.99, 6, true);

-- Insert orders
INSERT INTO sales.orders (user_id, total_amount, status, order_date) VALUES
(1, 1549.98, 'completed', '2023-03-10 14:30:00'),
(2, 299.98, 'completed', '2023-03-12 16:45:00'),
(1, 89.99, 'shipped', '2023-03-15 10:20:00'),
(4, 679.97, 'completed', '2023-03-18 09:15:00'),
(5, 199.99, 'pending', '2023-03-20 13:40:00'),
(6, 149.99, 'shipped', '2023-03-22 11:25:00'),
(8, 154.98, 'completed', '2023-03-25 15:10:00'),
(9, 59.99, 'completed', '2023-03-28 12:50:00'),
(10, 1199.99, 'processing', '2023-03-30 16:30:00');

-- Insert order items
INSERT INTO sales.order_items (order_id, product_id, quantity, unit_price) VALUES
-- Order 1 (user 1) - $1549.98
(1, 1, 1, 1299.99),  -- Laptop Pro 15"
(1, 2, 1, 249.99),   -- Wireless Headphones

-- Order 2 (user 2) - $299.98
(2, 2, 1, 249.99),   -- Wireless Headphones
(2, 10, 1, 49.99),   -- Cotton T-Shirt (2x)

-- Order 3 (user 1) - $89.99
(3, 15, 1, 89.99),   -- Coffee Maker

-- Order 4 (user 4) - $679.97
(4, 4, 1, 599.99),   -- Tablet Air
(4, 11, 1, 79.99),   -- Denim Jeans

-- Order 5 (user 5) - $199.99
(5, 18, 1, 199.99),  -- Tennis Racket

-- Order 6 (user 6) - $149.99
(6, 12, 1, 149.99),  -- Winter Jacket

-- Order 7 (user 8) - $154.98
(7, 13, 1, 129.99),  -- Running Shoes
(7, 7, 1, 24.99),    -- The Data Science Handbook (adjusted price)

-- Order 8 (user 9) - $59.99
(8, 21, 1, 59.99),   -- Building Blocks Set

-- Order 9 (user 10) - $1199.99
(9, 1, 1, 1199.99);  -- Laptop Pro 15" (different price)

-- Insert analytics data
INSERT INTO analytics.user_analytics (user_id, page_views, session_duration, last_login, device_type, created_date) VALUES
(1, 45, '02:30:00', '2023-03-30 18:45:00', 'desktop', '2023-03-30'),
(2, 32, '01:45:00', '2023-03-30 16:20:00', 'mobile', '2023-03-30'),
(3, 12, '00:35:00', '2023-03-25 14:10:00', 'tablet', '2023-03-25'),
(4, 67, '03:15:00', '2023-03-30 20:30:00', 'desktop', '2023-03-30'),
(5, 23, '01:20:00', '2023-03-29 12:45:00', 'mobile', '2023-03-29'),
(6, 38, '02:10:00', '2023-03-30 15:55:00', 'desktop', '2023-03-30'),
(7, 8, '00:25:00', '2023-03-20 10:30:00', 'mobile', '2023-03-20'),
(8, 51, '02:45:00', '2023-03-30 19:15:00', 'desktop', '2023-03-30'),
(9, 29, '01:35:00', '2023-03-30 17:20:00', 'tablet', '2023-03-30'),
(10, 73, '04:20:00', '2023-03-30 21:45:00', 'desktop', '2023-03-30');

-- Add some historical analytics data
INSERT INTO analytics.user_analytics (user_id, page_views, session_duration, last_login, device_type, created_date) VALUES
(1, 38, '02:15:00', '2023-03-29 19:30:00', 'desktop', '2023-03-29'),
(2, 25, '01:30:00', '2023-03-29 14:45:00', 'mobile', '2023-03-29'),
(4, 55, '02:50:00', '2023-03-29 20:15:00', 'desktop', '2023-03-29'),
(8, 42, '02:20:00', '2023-03-29 18:40:00', 'desktop', '2023-03-29'),
(10, 69, '03:45:00', '2023-03-29 22:10:00', 'desktop', '2023-03-29');

-- Update sequence values to ensure they're correct
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));
SELECT setval('sales.categories_id_seq', (SELECT MAX(id) FROM sales.categories));
SELECT setval('sales.products_id_seq', (SELECT MAX(id) FROM sales.products));
SELECT setval('sales.orders_id_seq', (SELECT MAX(id) FROM sales.orders));
SELECT setval('sales.order_items_id_seq', (SELECT MAX(id) FROM sales.order_items));
SELECT setval('analytics.user_analytics_id_seq', (SELECT MAX(id) FROM analytics.user_analytics));
