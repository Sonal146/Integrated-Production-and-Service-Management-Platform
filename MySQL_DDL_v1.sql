-- =====================================================
-- Integrated Production and Service Management Platform
-- MySQL Database Schema DDL
-- Version: 1.0
-- Date: October 2024
-- Author: Sonal M. Khobragade
-- =====================================================

-- Drop database if exists and create new one
-- DROP DATABASE IF EXISTS production_service_platform;
-- CREATE DATABASE production_service_platform;
-- USE production_service_platform;

-- =====================================================
-- USER MANAGEMENT TABLES
-- =====================================================

-- User roles lookup table
CREATE TABLE user_roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    role_description TEXT,
    permissions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role_id INT NOT NULL,
    department VARCHAR(50),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES user_roles(role_id)
);

-- =====================================================
-- CUSTOMER MANAGEMENT TABLES
-- =====================================================

-- Customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_code VARCHAR(20) NOT NULL UNIQUE,
    company_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    credit_limit DECIMAL(10,2) DEFAULT 0.00,
    payment_terms INT DEFAULT 30,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- =====================================================
-- ORDER MANAGEMENT TABLES
-- =====================================================

-- Order status lookup table
CREATE TABLE order_status (
    status_id INT PRIMARY KEY AUTO_INCREMENT,
    status_code VARCHAR(20) NOT NULL UNIQUE,
    status_name VARCHAR(50) NOT NULL,
    status_description TEXT,
    sort_order INT,
    is_final_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Service types lookup table
CREATE TABLE service_types (
    service_type_id INT PRIMARY KEY AUTO_INCREMENT,
    service_code VARCHAR(20) NOT NULL UNIQUE,
    service_name VARCHAR(100) NOT NULL,
    service_description TEXT,
    base_price DECIMAL(8,2) DEFAULT 0.00,
    estimated_hours DECIMAL(4,2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Main orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    service_type_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMP,
    priority ENUM('low', 'standard', 'high', 'urgent') DEFAULT 'standard',
    status_id INT NOT NULL,
    assigned_to INT,
    description TEXT,
    special_instructions TEXT,
    quantity INT DEFAULT 1,
    unit_price DECIMAL(8,2),
    total_amount DECIMAL(10,2),
    estimated_completion TIMESTAMP,
    actual_completion TIMESTAMP,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (service_type_id) REFERENCES service_types(service_type_id),
    FOREIGN KEY (status_id) REFERENCES order_status(status_id),
    FOREIGN KEY (assigned_to) REFERENCES users(user_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_order_date (order_date),
    INDEX idx_due_date (due_date),
    INDEX idx_status (status_id),
    INDEX idx_assigned_to (assigned_to)
);

-- Order status history tracking
CREATE TABLE order_status_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    previous_status_id INT,
    new_status_id INT NOT NULL,
    changed_by INT NOT NULL,
    change_reason TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (previous_status_id) REFERENCES order_status(status_id),
    FOREIGN KEY (new_status_id) REFERENCES order_status(status_id),
    FOREIGN KEY (changed_by) REFERENCES users(user_id)
);

-- =====================================================
-- FILE MANAGEMENT TABLES
-- =====================================================

-- File types lookup table
CREATE TABLE file_types (
    file_type_id INT PRIMARY KEY AUTO_INCREMENT,
    file_extension VARCHAR(10) NOT NULL UNIQUE,
    mime_type VARCHAR(100),
    file_category ENUM('source', 'output', 'reference', 'proof') DEFAULT 'source',
    max_file_size_mb INT DEFAULT 50,
    is_allowed BOOLEAN DEFAULT TRUE
);

-- Files table
CREATE TABLE files (
    file_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type_id INT NOT NULL,
    file_hash VARCHAR(64),
    version_number DECIMAL(3,1) DEFAULT 1.0,
    is_current_version BOOLEAN DEFAULT TRUE,
    thumbnail_path VARCHAR(500),
    uploaded_by INT NOT NULL,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (file_type_id) REFERENCES file_types(file_type_id),
    FOREIGN KEY (uploaded_by) REFERENCES users(user_id),
    INDEX idx_order_files (order_id),
    INDEX idx_file_version (order_id, version_number)
);

-- =====================================================
-- VENDOR MANAGEMENT TABLES
-- =====================================================

-- Vendors/Suppliers table
CREATE TABLE vendors (
    vendor_id INT PRIMARY KEY AUTO_INCREMENT,
    vendor_code VARCHAR(20) NOT NULL UNIQUE,
    vendor_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address_line1 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'USA',
    vendor_type ENUM('materials', 'equipment', 'services', 'other') DEFAULT 'materials',
    payment_terms INT DEFAULT 30,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Purchase orders table
CREATE TABLE purchase_orders (
    po_id INT PRIMARY KEY AUTO_INCREMENT,
    po_number VARCHAR(50) NOT NULL UNIQUE,
    vendor_id INT NOT NULL,
    order_date DATE NOT NULL,
    expected_delivery DATE,
    status ENUM('draft', 'sent', 'acknowledged', 'partial', 'delivered', 'cancelled') DEFAULT 'draft',
    total_amount DECIMAL(10,2) DEFAULT 0.00,
    created_by INT NOT NULL,
    approved_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    FOREIGN KEY (approved_by) REFERENCES users(user_id)
);

-- Goods Receipt Notes table
CREATE TABLE goods_receipt_notes (
    grn_id INT PRIMARY KEY AUTO_INCREMENT,
    grn_number VARCHAR(50) NOT NULL UNIQUE,
    po_id INT NOT NULL,
    receipt_date DATE NOT NULL,
    received_by INT NOT NULL,
    quantity_received INT NOT NULL,
    quantity_accepted INT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id),
    FOREIGN KEY (received_by) REFERENCES users(user_id)
);

-- =====================================================
-- FINANCIAL MANAGEMENT TABLES
-- =====================================================

-- Invoices table
CREATE TABLE invoices (
    invoice_id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    order_id INT,
    customer_id INT NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('draft', 'sent', 'paid', 'overdue', 'cancelled') DEFAULT 'draft',
    payment_received DECIMAL(10,2) DEFAULT 0.00,
    payment_date DATE,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id)
);

-- =====================================================
-- NOTIFICATION AND COMMUNICATION TABLES
-- =====================================================

-- Notification templates table
CREATE TABLE notification_templates (
    template_id INT PRIMARY KEY AUTO_INCREMENT,
    template_name VARCHAR(100) NOT NULL UNIQUE,
    template_subject VARCHAR(200) NOT NULL,
    template_body TEXT NOT NULL,
    template_type ENUM('email', 'sms', 'system') DEFAULT 'email',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Notifications log table
CREATE TABLE notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    recipient_id INT,
    recipient_email VARCHAR(100),
    template_id INT,
    subject VARCHAR(200),
    message TEXT,
    notification_type ENUM('email', 'sms', 'system') DEFAULT 'email',
    status ENUM('pending', 'sent', 'delivered', 'failed') DEFAULT 'pending',
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (recipient_id) REFERENCES users(user_id),
    FOREIGN KEY (template_id) REFERENCES notification_templates(template_id)
);

-- =====================================================
-- AUDIT AND LOGGING TABLES
-- =====================================================

-- System audit trail
CREATE TABLE audit_trail (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    changed_by INT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (changed_by) REFERENCES users(user_id),
    INDEX idx_table_record (table_name, record_id),
    INDEX idx_audit_date (created_at)
);

-- System settings table
CREATE TABLE system_settings (
    setting_id INT PRIMARY KEY AUTO_INCREMENT,
    setting_category VARCHAR(50) NOT NULL,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT,
    setting_description TEXT,
    is_encrypted BOOLEAN DEFAULT FALSE,
    updated_by INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES users(user_id),
    UNIQUE KEY unique_setting (setting_category, setting_key)
);

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert user roles
INSERT INTO user_roles (role_name, role_description) VALUES
('System Administrator', 'Full system access and user management'),
('Order Manager', 'Order creation, modification, and customer management'),
('Production Lead', 'Order assignment, status updates, and team management'),
('Designer', 'File management and design work'),
('Customer Service', 'Order inquiries and customer communication'),
('Manager', 'Reporting, analytics, and performance monitoring'),
('Quality Analyst', 'Quality control and testing');

-- Insert order status values
INSERT INTO order_status (status_code, status_name, status_description, sort_order, is_final_status) VALUES
('RECEIVED', 'Received', 'Order has been received and is awaiting processing', 1, FALSE),
('ASSIGNED', 'Assigned', 'Order has been assigned to a team member', 2, FALSE),
('IN_PROGRESS', 'In Progress', 'Work is currently being performed', 3, FALSE),
('REVIEW', 'Under Review', 'Work is under quality review', 4, FALSE),
('REVISION', 'Revision Required', 'Work requires revisions based on review', 5, FALSE),
('APPROVED', 'Approved', 'Work has been approved and is ready for delivery', 6, FALSE),
('DELIVERED', 'Delivered', 'Work has been delivered to customer', 7, TRUE),
('CANCELLED', 'Cancelled', 'Order has been cancelled', 8, TRUE);

-- Insert service types
INSERT INTO service_types (service_code, service_name, service_description, base_price, estimated_hours) VALUES
('EMB_DIGI', 'Embroidery Digitizing', 'Convert artwork to embroidery-ready digital format', 25.00, 2.0),
('VECTOR_ART', 'Vector Art Creation', 'Create scalable vector graphics from raster images', 35.00, 3.0),
('PATCH_DESIGN', 'Custom Patch Design', 'Design custom embroidered patches', 45.00, 4.0),
('LOGO_CLEANUP', 'Logo Cleanup', 'Clean up and optimize existing logos', 20.00, 1.5),
('COLORWAY', 'Color Separation', 'Separate artwork into individual color layers', 15.00, 1.0);

-- Insert file types
INSERT INTO file_types (file_extension, mime_type, file_category, max_file_size_mb) VALUES
('.ai', 'application/illustrator', 'source', 50),
('.eps', 'application/postscript', 'source', 50),
('.pdf', 'application/pdf', 'reference', 25),
('.png', 'image/png', 'reference', 10),
('.jpg', 'image/jpeg', 'reference', 10),
('.jpeg', 'image/jpeg', 'reference', 10),
('.tiff', 'image/tiff', 'source', 50),
('.psd', 'image/vnd.adobe.photoshop', 'source', 100),
('.dst', 'application/octet-stream', 'output', 5),
('.exp', 'application/octet-stream', 'output', 5);

-- Insert notification templates
INSERT INTO notification_templates (template_name, template_subject, template_body, template_type) VALUES
('Order Confirmation', 'Order Confirmation - {{order_number}}', 'Dear {{customer_name}}, Your order {{order_number}} has been received and is being processed. Expected completion: {{due_date}}.', 'email'),
('Status Update', 'Order Status Update - {{order_number}}', 'Your order {{order_number}} status has been updated to: {{status_name}}. {{additional_notes}}', 'email'),
('SLA Alert', 'SLA Alert - Order {{order_number}}', 'ALERT: Order {{order_number}} is approaching its SLA deadline. Please take immediate action.', 'email'),
('Order Complete', 'Order Complete - {{order_number}}', 'Great news! Your order {{order_number}} has been completed and is ready for delivery.', 'email');

-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- Additional indexes for better query performance
CREATE INDEX idx_customers_active ON customers(is_active);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_files_order_current ON files(order_id, is_current_version);
CREATE INDEX idx_notifications_status ON notifications(status, created_at);
CREATE INDEX idx_audit_user_date ON audit_trail(changed_by, created_at);

-- =====================================================
-- VIEWS FOR REPORTING
-- =====================================================

-- View for order summary with customer and status information
CREATE VIEW v_order_summary AS
SELECT 
    o.order_id,
    o.order_number,
    c.company_name,
    c.contact_person,
    st.service_name,
    os.status_name,
    o.order_date,
    o.due_date,
    o.total_amount,
    CONCAT(u.first_name, ' ', u.last_name) AS assigned_to_name,
    DATEDIFF(o.due_date, CURDATE()) AS days_until_due
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN service_types st ON o.service_type_id = st.service_type_id
LEFT JOIN order_status os ON o.status_id = os.status_id
LEFT JOIN users u ON o.assigned_to = u.user_id;

-- View for active orders with file counts
CREATE VIEW v_active_orders_with_files AS
SELECT 
    o.order_id,
    o.order_number,
    c.company_name,
    os.status_name,
    COUNT(f.file_id) as file_count,
    o.due_date,
    o.total_amount
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_status os ON o.status_id = os.status_id
LEFT JOIN files f ON o.order_id = f.order_id AND f.is_current_version = TRUE
WHERE os.is_final_status = FALSE
GROUP BY o.order_id, o.order_number, c.company_name, os.status_name, o.due_date, o.total_amount;

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

DELIMITER //

-- Procedure to update order status with automatic history tracking
CREATE PROCEDURE UpdateOrderStatus(
    IN p_order_id INT,
    IN p_new_status_id INT,
    IN p_changed_by INT,
    IN p_change_reason TEXT
)
BEGIN
    DECLARE v_current_status_id INT;

    -- Get current status
    SELECT status_id INTO v_current_status_id 
    FROM orders 
    WHERE order_id = p_order_id;

    -- Update order status
    UPDATE orders 
    SET status_id = p_new_status_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id;

    -- Insert status history record
    INSERT INTO order_status_history (
        order_id, 
        previous_status_id, 
        new_status_id, 
        changed_by, 
        change_reason
    ) VALUES (
        p_order_id, 
        v_current_status_id, 
        p_new_status_id, 
        p_changed_by, 
        p_change_reason
    );

END //

DELIMITER ;

-- =====================================================
-- END OF SCHEMA
-- =====================================================
