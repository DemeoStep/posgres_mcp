-- 01-create-schema.sql
-- Create test schemas and tables for MCP server testing

-- Create additional schemas for testing
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS analytics;

-- Create users table in public schema
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    birth_date DATE,
    salary DECIMAL(10,2)
);

-- Create products table in sales schema
CREATE TABLE IF NOT EXISTS sales.products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category_id INTEGER,
    in_stock BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create categories table in sales schema
CREATE TABLE IF NOT EXISTS sales.categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table in sales schema
CREATE TABLE IF NOT EXISTS sales.orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create order_items table in sales schema
CREATE TABLE IF NOT EXISTS sales.order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES sales.orders(id),
    product_id INTEGER REFERENCES sales.products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL
);

-- Create user_analytics table in analytics schema
CREATE TABLE IF NOT EXISTS analytics.user_analytics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    page_views INTEGER DEFAULT 0,
    session_duration INTERVAL,
    last_login TIMESTAMP,
    device_type VARCHAR(20),
    created_date DATE DEFAULT CURRENT_DATE
);

-- Add foreign key constraint for products
ALTER TABLE sales.products 
ADD CONSTRAINT fk_products_category 
FOREIGN KEY (category_id) REFERENCES sales.categories(id);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON sales.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_date ON sales.orders(order_date);
CREATE INDEX IF NOT EXISTS idx_products_category ON sales.products(category_id);

-- Create a view for easy querying
CREATE OR REPLACE VIEW sales.order_summary AS
SELECT 
    o.id as order_id,
    u.username,
    u.email,
    o.total_amount,
    o.status,
    o.order_date,
    COUNT(oi.id) as item_count
FROM sales.orders o
JOIN users u ON o.user_id = u.id
LEFT JOIN sales.order_items oi ON o.id = oi.order_id
GROUP BY o.id, u.username, u.email, o.total_amount, o.status, o.order_date;

-- Grant permissions (in case we need different user privileges later)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO testuser;
GRANT SELECT ON ALL TABLES IN SCHEMA sales TO testuser;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO testuser;
GRANT USAGE ON SCHEMA public TO testuser;
GRANT USAGE ON SCHEMA sales TO testuser;
GRANT USAGE ON SCHEMA analytics TO testuser;
