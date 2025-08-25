-- PostgreSQL Database Initialization Script
-- This script runs automatically when the database is created for the first time

-- Create a sample database schema
CREATE SCHEMA IF NOT EXISTS app_schema;

-- Create a sample users table
CREATE TABLE IF NOT EXISTS app_schema.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create a sample products table
CREATE TABLE IF NOT EXISTS app_schema.products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    category_id INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create a sample categories table
CREATE TABLE IF NOT EXISTS app_schema.categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    parent_id INTEGER REFERENCES app_schema.categories(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create a sample orders table
CREATE TABLE IF NOT EXISTS app_schema.orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES app_schema.users(id),
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    shipping_address TEXT,
    billing_address TEXT
);

-- Create a sample order_items table
CREATE TABLE IF NOT EXISTS app_schema.order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES app_schema.orders(id),
    product_id INTEGER NOT NULL REFERENCES app_schema.products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- Add foreign key constraint for products -> categories
ALTER TABLE app_schema.products 
ADD CONSTRAINT fk_products_category 
FOREIGN KEY (category_id) REFERENCES app_schema.categories(id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON app_schema.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON app_schema.users(username);
CREATE INDEX IF NOT EXISTS idx_products_category ON app_schema.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_name ON app_schema.products(name);
CREATE INDEX IF NOT EXISTS idx_orders_user ON app_schema.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_date ON app_schema.orders(order_date);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON app_schema.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON app_schema.order_items(product_id);

-- Insert sample data
INSERT INTO app_schema.categories (name, description) VALUES
    ('Electronics', 'Electronic devices and gadgets'),
    ('Books', 'Books and publications'),
    ('Clothing', 'Clothing and accessories'),
    ('Home & Garden', 'Home and garden items')
ON CONFLICT (name) DO NOTHING;

INSERT INTO app_schema.users (username, email, password_hash, first_name, last_name) VALUES
    ('john_doe', 'john@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeQ8ST1LK0WpG.8z2', 'John', 'Doe'),
    ('jane_smith', 'jane@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeQ8ST1LK0WpG.8z2', 'Jane', 'Smith'),
    ('admin_user', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeQ8ST1LK0WpG.8z2', 'Admin', 'User')
ON CONFLICT (username) DO NOTHING;

INSERT INTO app_schema.products (name, description, price, stock_quantity, category_id) VALUES
    ('Laptop Computer', 'High-performance laptop for work and gaming', 999.99, 50, 1),
    ('Programming Book', 'Learn Docker and Kubernetes', 29.99, 100, 2),
    ('T-Shirt', 'Comfortable cotton t-shirt', 19.99, 200, 3),
    ('Garden Tool Set', 'Complete set of garden tools', 89.99, 25, 4)
ON CONFLICT DO NOTHING;

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at columns
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON app_schema.users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON app_schema.products 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create a read-only role for reports
CREATE ROLE readonly_user;
GRANT CONNECT ON DATABASE mydatabase TO readonly_user;
GRANT USAGE ON SCHEMA app_schema TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA app_schema TO readonly_user;

-- Grant permissions to the main user
GRANT ALL PRIVILEGES ON SCHEMA app_schema TO myuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA app_schema TO myuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app_schema TO myuser;

-- Create a view for order summaries
CREATE OR REPLACE VIEW app_schema.order_summary AS
SELECT 
    o.id,
    o.order_date,
    u.username,
    u.email,
    o.total_amount,
    o.status,
    COUNT(oi.id) as item_count
FROM app_schema.orders o
JOIN app_schema.users u ON o.user_id = u.id
LEFT JOIN app_schema.order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.order_date, u.username, u.email, o.total_amount, o.status;

COMMENT ON SCHEMA app_schema IS 'Main application schema for e-commerce data';
COMMENT ON TABLE app_schema.users IS 'User accounts and profiles';
COMMENT ON TABLE app_schema.products IS 'Product catalog with pricing and inventory';
COMMENT ON TABLE app_schema.categories IS 'Product categories with hierarchy support';
COMMENT ON TABLE app_schema.orders IS 'Customer orders and transactions';
COMMENT ON TABLE app_schema.order_items IS 'Individual items within orders';

-- Print completion message
DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully!';
    RAISE NOTICE 'Created schema: app_schema';
    RAISE NOTICE 'Created tables: users, products, categories, orders, order_items';
    RAISE NOTICE 'Created indexes and triggers for performance and data integrity';
    RAISE NOTICE 'Inserted sample data for testing';
END $$;