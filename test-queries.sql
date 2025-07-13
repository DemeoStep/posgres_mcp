-- Test queries to validate MCP server functionality

-- 1. Basic user information
SELECT 
    id, 
    username, 
    email, 
    first_name || ' ' || last_name as full_name,
    active,
    created_at
FROM users 
WHERE active = true 
ORDER BY created_at DESC;

-- 2. Product catalog with categories
SELECT 
    p.id,
    p.name as product_name,
    c.name as category,
    p.price,
    p.in_stock,
    p.description
FROM sales.products p
JOIN sales.categories c ON p.category_id = c.id
ORDER BY c.name, p.price DESC;

-- 3. Order summary with customer details
SELECT 
    o.id as order_id,
    u.username,
    u.email,
    o.total_amount,
    o.status,
    o.order_date,
    COUNT(oi.id) as items_count
FROM sales.orders o
JOIN users u ON o.user_id = u.id
LEFT JOIN sales.order_items oi ON o.id = oi.order_id
GROUP BY o.id, u.username, u.email, o.total_amount, o.status, o.order_date
ORDER BY o.order_date DESC;

-- 4. User activity analytics
SELECT 
    u.username,
    u.email,
    a.page_views,
    a.session_duration,
    a.last_login,
    a.device_type,
    a.created_date
FROM analytics.user_analytics a
JOIN users u ON a.user_id = u.id
WHERE a.created_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY a.page_views DESC;

-- 5. Sales by category
SELECT 
    c.name as category,
    COUNT(DISTINCT o.id) as orders_count,
    SUM(oi.quantity) as items_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue
FROM sales.categories c
JOIN sales.products p ON c.id = p.category_id
JOIN sales.order_items oi ON p.id = oi.product_id
JOIN sales.orders o ON oi.order_id = o.id
WHERE o.status = 'completed'
GROUP BY c.id, c.name
ORDER BY total_revenue DESC;

-- 6. Top customers by spending
SELECT 
    u.username,
    u.email,
    COUNT(o.id) as total_orders,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as avg_order_value,
    MAX(o.order_date) as last_order_date
FROM users u
JOIN sales.orders o ON u.id = o.user_id
WHERE o.status IN ('completed', 'shipped')
GROUP BY u.id, u.username, u.email
ORDER BY total_spent DESC;

-- 7. Inventory status
SELECT 
    p.name as product,
    c.name as category,
    p.price,
    p.in_stock,
    CASE 
        WHEN p.in_stock THEN 'Available'
        ELSE 'Out of Stock'
    END as availability_status
FROM sales.products p
JOIN sales.categories c ON p.category_id = c.id
ORDER BY p.in_stock DESC, c.name, p.name;

-- 8. Monthly order trends (sample for time-based analysis)
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as total_orders,
    SUM(total_amount) as monthly_revenue,
    AVG(total_amount) as avg_order_value
FROM sales.orders
WHERE order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC;
