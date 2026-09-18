-- ============================================================
-- Brew & Bite POS Database
-- PostgreSQL
--
-- Story:
-- Brew & Bite is a small café that sells coffee, drinks, meals,
-- and snacks. It serves both registered customers and walk-in
-- customers. A voucher represents one completed sale.
--
-- Important:
-- customer_id in vouchers is nullable because a sale can be made
-- to a walk-in customer who is not registered in the system.
-- ============================================================


-- ============================================================
-- 1. DROP TABLES
-- ============================================================

DROP TABLE IF EXISTS voucher_items CASCADE;
DROP TABLE IF EXISTS vouchers CASCADE;
DROP TABLE IF EXISTS menus CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS shops CASCADE;


-- ============================================================
-- 2. SHOPS
-- ============================================================

CREATE TABLE shops (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- 3. CATEGORIES
-- ============================================================

CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_categories_shop
        FOREIGN KEY (shop_id)
        REFERENCES shops(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_categories_shop_name
        UNIQUE (shop_id, name)
);


-- ============================================================
-- 4. MENU ITEMS
-- ============================================================

CREATE TABLE menus (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,

    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_menus_shop
        FOREIGN KEY (shop_id)
        REFERENCES shops(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_menus_category
        FOREIGN KEY (category_id)
        REFERENCES categories(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_menus_price
        CHECK (price >= 0)
);


-- ============================================================
-- 5. CUSTOMERS
-- ============================================================

CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL,

    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    email VARCHAR(255),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_customers_shop
        FOREIGN KEY (shop_id)
        REFERENCES shops(id)
        ON DELETE CASCADE
);


-- ============================================================
-- 6. VOUCHERS
-- ============================================================
--
-- customer_id is NULL for walk-in customers.
--
-- Example:
--   Registered customer -> customer_id = 1
--   Walk-in customer    -> customer_id = NULL
--
-- This allows the shop to sell to anyone without requiring
-- customer registration.
-- ============================================================

CREATE TABLE vouchers (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL,
    customer_id BIGINT,

    voucher_number VARCHAR(50) NOT NULL,

    subtotal NUMERIC(10, 2) NOT NULL DEFAULT 0,
    discount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    total NUMERIC(10, 2) NOT NULL DEFAULT 0,

    payment_method VARCHAR(50) NOT NULL DEFAULT 'cash',

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_vouchers_shop
        FOREIGN KEY (shop_id)
        REFERENCES shops(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_vouchers_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(id)
        ON DELETE SET NULL,

    CONSTRAINT uq_vouchers_shop_number
        UNIQUE (shop_id, voucher_number),

    CONSTRAINT chk_vouchers_amounts
        CHECK (
            subtotal >= 0
            AND discount >= 0
            AND total >= 0
        )
);


-- ============================================================
-- 7. VOUCHER ITEMS
-- ============================================================
--
-- A voucher can contain multiple menu items.
-- The price is stored here as the selling price at the time
-- of purchase, so changing the menu price later will not
-- change historical sales records.
-- ============================================================

CREATE TABLE voucher_items (
    id BIGSERIAL PRIMARY KEY,

    voucher_id BIGINT NOT NULL,
    menu_id BIGINT NOT NULL,

    quantity INTEGER NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    subtotal NUMERIC(10, 2) NOT NULL,

    CONSTRAINT fk_voucher_items_voucher
        FOREIGN KEY (voucher_id)
        REFERENCES vouchers(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_voucher_items_menu
        FOREIGN KEY (menu_id)
        REFERENCES menus(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_voucher_items_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_voucher_items_price
        CHECK (price >= 0),

    CONSTRAINT chk_voucher_items_subtotal
        CHECK (subtotal >= 0)
);


-- ============================================================
-- 8. INSERT SHOP
-- ============================================================

INSERT INTO shops (name, address, phone)
VALUES
    (
        'Brew & Bite Café',
        '45 Sukhumvit Road, Bangkok, Thailand',
        '02-555-0188'
    );


-- ============================================================
-- 9. INSERT CATEGORIES
-- ============================================================

INSERT INTO categories (shop_id, name)
VALUES
    (1, 'Coffee'),
    (1, 'Drinks'),
    (1, 'Meals'),
    (1, 'Snacks');


-- ============================================================
-- 10. INSERT MENU ITEMS
-- ============================================================

INSERT INTO menus
    (shop_id, category_id, name, description, price)
VALUES

    -- Coffee
    (1, 1, 'Americano', 'Espresso with hot water', 80.00),
    (1, 1, 'Café Latte', 'Espresso with steamed milk', 90.00),
    (1, 1, 'Cappuccino', 'Espresso with steamed milk and milk foam', 95.00),
    (1, 1, 'Mocha', 'Espresso with chocolate and steamed milk', 100.00),

    -- Drinks
    (1, 2, 'Fresh Orange Juice', 'Freshly squeezed orange juice', 70.00),
    (1, 2, 'Thai Iced Tea', 'Sweet Thai tea served over ice', 65.00),
    (1, 2, 'Iced Lemon Tea', 'Refreshing black tea with lemon', 60.00),
    (1, 2, 'Coca-Cola', 'Chilled Coca-Cola', 50.00),

    -- Meals
    (1, 3, 'Chicken Fried Rice', 'Fried rice with chicken and vegetables', 120.00),
    (1, 3, 'Chicken Burger', 'Grilled chicken burger served with fries', 150.00),
    (1, 3, 'Spaghetti Bolognese', 'Spaghetti with beef tomato sauce', 140.00),

    -- Snacks
    (1, 4, 'French Fries', 'Crispy golden French fries', 70.00),
    (1, 4, 'Chocolate Cake', 'Slice of rich chocolate cake', 80.00),
    (1, 4, 'Butter Croissant', 'Freshly baked butter croissant', 75.00);


-- ============================================================
-- 11. INSERT REGISTERED CUSTOMERS
-- ============================================================
--
-- These customers have profiles in the café's system.
-- They are optional for a sale.
-- ============================================================

INSERT INTO customers (shop_id, name, phone, email)
VALUES
    (1, 'Aung Min', '091-234-5678', 'aung.min@example.com'),
    (1, 'Su Su', '092-345-6789', 'su.su@example.com'),
    (1, 'David Chen', '093-456-7890', 'david.chen@example.com'),
    (1, 'Tony Lee', '094-567-8901', 'tony.lee@example.com'),
    (1, 'Steve Smith', '095-678-9012', 'steve.smith@example.com');


-- ============================================================
-- 12. INSERT VOUCHERS / SALES
-- ============================================================

-- ------------------------------------------------------------
-- Sale #1
-- Registered customer: Aung Min
--
-- 2 x Americano       = 160
-- 1 x Chocolate Cake  =  80
-- Subtotal            = 240
-- Discount            =   0
-- Total               = 240
-- ------------------------------------------------------------

INSERT INTO vouchers
    (
        shop_id,
        customer_id,
        voucher_number,
        subtotal,
        discount,
        total,
        payment_method
    )
VALUES
    (1, 1, 'BB-000001', 240.00, 0.00, 240.00, 'cash');


INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (1, 1, 2, 80.00, 160.00),
    (1, 13, 1, 80.00, 80.00);


-- ------------------------------------------------------------
-- Sale #2
-- Walk-in customer
--
-- The customer did not register with the café.
-- customer_id is NULL.
--
-- 1 x Café Latte       =  90
-- 1 x Chicken Burger   = 150
-- 1 x French Fries     =  70
-- Subtotal             = 310
-- Discount             =   0
-- Total                = 310
-- ------------------------------------------------------------

INSERT INTO vouchers
    (
        shop_id,
        customer_id,
        voucher_number,
        subtotal,
        discount,
        total,
        payment_method
    )
VALUES
    (1, NULL, 'BB-000002', 310.00, 0.00, 310.00, 'cash');


INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (2, 2, 1, 90.00, 90.00),
    (2, 10, 1, 150.00, 150.00),
    (2, 12, 1, 70.00, 70.00);


-- ------------------------------------------------------------
-- Sale #3
-- Registered customer: Su Su
--
-- 1 x Cappuccino       =  95
-- 2 x Thai Iced Tea    = 130
-- 1 x Butter Croissant =  75
-- Subtotal             = 300
-- Discount             =  20
-- Total                = 280
-- ------------------------------------------------------------

INSERT INTO vouchers
    (
        shop_id,
        customer_id,
        voucher_number,
        subtotal,
        discount,
        total,
        payment_method
    )
VALUES
    (1, 2, 'BB-000003', 300.00, 20.00, 280.00, 'card');


INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (3, 3, 1, 95.00, 95.00),
    (3, 6, 2, 65.00, 130.00),
    (3, 14, 1, 75.00, 75.00);


-- ------------------------------------------------------------
-- Sale #4
-- Walk-in customer
--
-- 1 x Mocha             = 100
-- 1 x Fresh Orange Juice = 70
-- 1 x Chocolate Cake    =  80
-- Subtotal              = 250
-- Discount              =   0
-- Total                 = 250
-- ------------------------------------------------------------

INSERT INTO vouchers
    (
        shop_id,
        customer_id,
        voucher_number,
        subtotal,
        discount,
        total,
        payment_method
    )
VALUES
    (1, NULL, 'BB-000004', 250.00, 0.00, 250.00, 'qr');


INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (4, 4, 1, 100.00, 100.00),
    (4, 5, 1, 70.00, 70.00),
    (4, 13, 1, 80.00, 80.00);


-- ============================================================
-- 13. INDEXES
-- ============================================================

CREATE INDEX idx_categories_shop_id
    ON categories(shop_id);

CREATE INDEX idx_menus_shop_id
    ON menus(shop_id);

CREATE INDEX idx_menus_category_id
    ON menus(category_id);

CREATE INDEX idx_customers_shop_id
    ON customers(shop_id);

CREATE INDEX idx_vouchers_shop_id
    ON vouchers(shop_id);

CREATE INDEX idx_vouchers_customer_id
    ON vouchers(customer_id);

CREATE INDEX idx_voucher_items_voucher_id
    ON voucher_items(voucher_id);

CREATE INDEX idx_voucher_items_menu_id
    ON voucher_items(menu_id);


-- ============================================================
-- 14. EXAMPLE: SHOW ALL SALES
-- ============================================================

SELECT
    v.voucher_number,
    COALESCE(c.name, 'Walk-in Customer') AS customer,
    v.subtotal,
    v.discount,
    v.total,
    v.payment_method,
    v.created_at
FROM vouchers v
LEFT JOIN customers c
    ON c.id = v.customer_id
ORDER BY v.id;


-- ============================================================
-- 15. EXAMPLE: SHOW VOUCHER DETAILS
-- ============================================================

SELECT
    v.voucher_number,
    COALESCE(c.name, 'Walk-in Customer') AS customer,
    m.name AS menu_item,
    vi.quantity,
    vi.price,
    vi.subtotal
FROM vouchers v
LEFT JOIN customers c
    ON c.id = v.customer_id
JOIN voucher_items vi
    ON vi.voucher_id = v.id
JOIN menus m
    ON m.id = vi.menu_id
ORDER BY v.id, vi.id;

-- ============================================================
-- 20 ADDITIONAL VOUCHERS / SALES
-- ============================================================

-- ------------------------------------------------------------
-- Sale #5
-- Registered customer: David Chen
-- 1 x Americano         =  80
-- 1 x Chicken Fried Rice = 120
-- Subtotal               = 200
-- Discount               =   0
-- Total                  = 200
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 3, 'BB-000005', 200.00, 0.00, 200.00, 'cash');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (5, 1, 1, 80.00, 80.00),
    (5, 9, 1, 120.00, 120.00);


-- ------------------------------------------------------------
-- Sale #6
-- Walk-in customer
-- 2 x Cappuccino        = 190
-- 1 x Chocolate Cake    =  80
-- Subtotal              = 270
-- Discount              =   0
-- Total                 = 270
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000006', 270.00, 0.00, 270.00, 'qr');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (6, 3, 2, 95.00, 190.00),
    (6, 13, 1, 80.00, 80.00);


-- ------------------------------------------------------------
-- Sale #7
-- Registered customer: Aung Min
-- 1 x Mocha              = 100
-- 1 x Spaghetti Bolognese = 140
-- Subtotal                = 240
-- Discount                =   0
-- Total                   = 240
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 1, 'BB-000007', 240.00, 0.00, 240.00, 'card');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (7, 4, 1, 100.00, 100.00),
    (7, 11, 1, 140.00, 140.00);


-- ------------------------------------------------------------
-- Sale #8
-- Walk-in customer
-- 1 x Thai Iced Tea      =  65
-- 1 x French Fries       =  70
-- 1 x Butter Croissant   =  75
-- Subtotal               = 210
-- Discount               =   0
-- Total                  = 210
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000008', 210.00, 0.00, 210.00, 'cash');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (8, 6, 1, 65.00, 65.00),
    (8, 12, 1, 70.00, 70.00),
    (8, 14, 1, 75.00, 75.00);


-- ------------------------------------------------------------
-- Sale #9
-- Registered customer: Su Su
-- 1 x Café Latte         =  90
-- 1 x Iced Lemon Tea     =  60
-- 1 x Chicken Burger     = 150
-- Subtotal               = 300
-- Discount               =  30
-- Total                  = 270
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 2, 'BB-000009', 300.00, 30.00, 270.00, 'card');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (9, 2, 1, 90.00, 90.00),
    (9, 7, 1, 60.00, 60.00),
    (9, 10, 1, 150.00, 150.00);


-- ------------------------------------------------------------
-- Sale #10
-- Walk-in customer
-- 1 x Coca-Cola          =  50
-- 1 x Americano          =  80
-- 1 x Chocolate Cake     =  80
-- Subtotal               = 210
-- Discount               =   0
-- Total                  = 210
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000010', 210.00, 0.00, 210.00, 'cash');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (10, 8, 1, 50.00, 50.00),
    (10, 1, 1, 80.00, 80.00),
    (10, 13, 1, 80.00, 80.00);


-- ------------------------------------------------------------
-- Sale #11
-- Registered customer: David Chen
-- 2 x Chicken Fried Rice = 240
-- 2 x Thai Iced Tea      = 130
-- Subtotal               = 370
-- Discount               =  20
-- Total                  = 350
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 3, 'BB-000011', 370.00, 20.00, 350.00, 'qr');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (11, 9, 2, 120.00, 240.00),
    (11, 6, 2, 65.00, 130.00);


-- ------------------------------------------------------------
-- Sale #12
-- Walk-in customer
-- 1 x Cappuccino         =  95
-- 1 x Fresh Orange Juice =  70
-- 1 x Spaghetti Bolognese = 140
-- Subtotal                = 305
-- Discount                =   0
-- Total                   = 305
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000012', 305.00, 0.00, 305.00, 'cash');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (12, 3, 1, 95.00, 95.00),
    (12, 5, 1, 70.00, 70.00),
    (12, 11, 1, 140.00, 140.00);


-- ------------------------------------------------------------
-- Sale #13
-- Registered customer: Aung Min
-- 1 x Mocha              = 100
-- 2 x Butter Croissant   = 150
-- Subtotal               = 250
-- Discount               =   0
-- Total                  = 250
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 1, 'BB-000013', 250.00, 0.00, 250.00, 'card');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (13, 4, 1, 100.00, 100.00),
    (13, 14, 2, 75.00, 150.00);


-- ------------------------------------------------------------
-- Sale #14
-- Walk-in customer
-- 2 x Americano          = 160
-- 1 x Chicken Burger     = 150
-- 1 x French Fries       =  70
-- Subtotal               = 380
-- Discount               =  30
-- Total                  = 350
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000014', 380.00, 30.00, 350.00, 'qr');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (14, 1, 2, 80.00, 160.00),
    (14, 10, 1, 150.00, 150.00),
    (14, 12, 1, 70.00, 70.00);


-- ------------------------------------------------------------
-- Sale #15
-- Registered customer: Su Su
-- 1 x Café Latte         =  90
-- 1 x Chocolate Cake     =  80
-- 1 x Iced Lemon Tea     =  60
-- Subtotal               = 230
-- Discount               =   0
-- Total                  = 230
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 2, 'BB-000015', 230.00, 0.00, 230.00, 'cash');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (15, 2, 1, 90.00, 90.00),
    (15, 13, 1, 80.00, 80.00),
    (15, 7, 1, 60.00, 60.00);


-- ------------------------------------------------------------
-- Sale #16
-- Walk-in customer
-- 1 x Spaghetti Bolognese = 140
-- 1 x Coca-Cola           =  50
-- Subtotal                = 190
-- Discount                =   0
-- Total                   = 190
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000016', 190.00, 0.00, 190.00, 'cash');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (16, 11, 1, 140.00, 140.00),
    (16, 8, 1, 50.00, 50.00);


-- ------------------------------------------------------------
-- Sale #17
-- Registered customer: David Chen
-- 1 x Chicken Fried Rice  = 120
-- 1 x Thai Iced Tea       =  65
-- 1 x French Fries        =  70
-- Subtotal                = 255
-- Discount                =   0
-- Total                   = 255
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 3, 'BB-000017', 255.00, 0.00, 255.00, 'card');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (17, 9, 1, 120.00, 120.00),
    (17, 6, 1, 65.00, 65.00),
    (17, 12, 1, 70.00, 70.00);


-- ------------------------------------------------------------
-- Sale #18
-- Walk-in customer
-- 2 x Cappuccino          = 190
-- 1 x Fresh Orange Juice  =  70
-- Subtotal                = 260
-- Discount                =   0
-- Total                   = 260
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000018', 260.00, 0.00, 260.00, 'qr');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (18, 3, 2, 95.00, 190.00),
    (18, 5, 1, 70.00, 70.00);


-- ------------------------------------------------------------
-- Sale #19
-- Registered customer: Aung Min
-- 1 x Chicken Burger      = 150
-- 1 x Mocha               = 100
-- 1 x Chocolate Cake      =  80
-- Subtotal                = 330
-- Discount                =  30
-- Total                   = 300
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 1, 'BB-000019', 330.00, 30.00, 300.00, 'card');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (19, 10, 1, 150.00, 150.00),
    (19, 4, 1, 100.00, 100.00),
    (19, 13, 1, 80.00, 80.00);


-- ------------------------------------------------------------
-- Sale #20
-- Walk-in customer
-- 1 x Americano           =  80
-- 1 x Iced Lemon Tea      =  60
-- 1 x Butter Croissant    =  75
-- 1 x Coca-Cola           =  50
-- Subtotal                = 265
-- Discount                =   0
-- Total                   = 265
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000020', 265.00, 0.00, 265.00, 'cash');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (20, 1, 1, 80.00, 80.00),
    (20, 7, 1, 60.00, 60.00),
    (20, 14, 1, 75.00, 75.00),
    (20, 8, 1, 50.00, 50.00);


-- ------------------------------------------------------------
-- Sale #21
-- Registered customer: Su Su
-- 1 x Café Latte          =  90
-- 1 x Spaghetti Bolognese = 140
-- 1 x Thai Iced Tea       =  65
-- Subtotal                = 295
-- Discount                =   0
-- Total                   = 295
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 2, 'BB-000021', 295.00, 0.00, 295.00, 'cash');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (21, 2, 1, 90.00, 90.00),
    (21, 11, 1, 140.00, 140.00),
    (21, 6, 1, 65.00, 65.00);


-- ------------------------------------------------------------
-- Sale #22
-- Walk-in customer
-- 2 x Chicken Fried Rice  = 240
-- 1 x French Fries        =  70
-- Subtotal                = 310
-- Discount                =   0
-- Total                   = 310
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000022', 310.00, 0.00, 310.00, 'qr');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (22, 9, 2, 120.00, 240.00),
    (22, 12, 1, 70.00, 70.00);


-- ------------------------------------------------------------
-- Sale #23
-- Registered customer: David Chen
-- 1 x Mocha               = 100
-- 1 x Cappuccino          =  95
-- 1 x Chocolate Cake      =  80
-- Subtotal                = 275
-- Discount                =   0
-- Total                   = 275
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, 3, 'BB-000023', 275.00, 0.00, 275.00, 'card');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (23, 4, 1, 100.00, 100.00),
    (23, 3, 1, 95.00, 95.00),
    (23, 13, 1, 80.00, 80.00);


-- ------------------------------------------------------------
-- Sale #24
-- Walk-in customer
-- 1 x Fresh Orange Juice  =  70
-- 1 x Chicken Burger      = 150
-- 1 x Iced Lemon Tea      =  60
-- Subtotal                = 280
-- Discount                =   0
-- Total                   = 280
-- ------------------------------------------------------------
INSERT INTO vouchers
    (shop_id, customer_id, voucher_number, subtotal, discount, total, payment_method)
VALUES
    (1, NULL, 'BB-000024', 280.00, 0.00, 280.00, 'cash');

INSERT INTO voucher_items
    (voucher_id, menu_id, quantity, price, subtotal)
VALUES
    (24, 5, 1, 70.00, 70.00),
    (24, 10, 1, 150.00, 150.00),
    (24, 7, 1, 60.00, 60.00);
