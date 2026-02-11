
   -- Project: FinPayConnect Analytics
   -- Course: Database Development with PL/SQL (INSY 8311)
   -- Description: SQL JOINs and Window Functions Implementation
   -- Student: KABANO Festo


-- This is for delete table if exist

DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;


-- table queries i used postgres

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(100),
    phone_number VARCHAR(20),
    region VARCHAR(50),
    registration_date DATE
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price NUMERIC(10,2)
);

CREATE TABLE transactions (
    transaction_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER,
    transaction_date DATE,
    payment_method VARCHAR(50)
);


-- sample data for customers, products and transactions tables

-- Customers
INSERT INTO customers VALUES
(1, 'keza', '07885206983', 'Kigali', '2026-03-01'),
(2, 'kabano', '0788595454', 'Kigali', '2026-02-05'),
(3, 'cyiza lucie', '0785206973', 'Huye', '2026-01-12'),
(4, 'uwinea', '0788680640', 'Musanze', '2026-01-1'),
(5, 'Eric', '0780026640', 'Huye', '2025-04-10');

-- Products
INSERT INTO products VALUES
(1, 'Rice', 'Food', 1000),
(2, 'Sugar', 'Food', 800),
(3, 'Soap', 'Hygiene', 500),
(4, 'Cooking Oil', 'Food', 3000),
(5, 'Milk', 'Dairy', 1200);

-- Transactions
INSERT INTO transactions VALUES
(1, 1, 1, 5, '2025-01-10', 'Mobile Money'),
(2, 2, 2, 3, '2025-01-15', 'Mobile Money'),
(3, 1, 3, 4, '2025-02-01', 'Cash'),
(4, 3, 4, 2, '2025-02-10', 'Mobile Money'),
(5, 4, 1, 6, '2025-03-05', 'Bank'),
(6, 2, 4, 1, '2025-03-10', 'Mobile Money');


-- SQL queries for JOINs and Window Functions

-- 1. INNER JOIN
SELECT c.customer_name,
       p.product_name,
       t.quantity,
       t.transaction_date
FROM transactions t
INNER JOIN customers c ON t.customer_id = c.customer_id
INNER JOIN products p ON t.product_id = p.product_id;


-- 2. LEFT JOIN (Customers with no transactions)
SELECT c.customer_name
FROM customers c
LEFT JOIN transactions t ON c.customer_id = t.customer_id
WHERE t.transaction_id IS NULL;


-- 3. RIGHT JOIN (Products with no sales)
SELECT p.product_name
FROM transactions t
RIGHT JOIN products p ON t.product_id = p.product_id
WHERE t.transaction_id IS NULL;


-- 4. FULL OUTER JOIN
SELECT c.customer_name,
       p.product_name
FROM customers c
FULL OUTER JOIN transactions t ON c.customer_id = t.customer_id
FULL OUTER JOIN products p ON t.product_id = p.product_id;


-- 5. SELF JOIN (Customers in same region)
SELECT c1.customer_name AS customer1,
       c2.customer_name AS customer2,
       c1.region
FROM customers c1
JOIN customers c2
ON c1.region = c2.region
AND c1.customer_id <> c2.customer_id;


-- Window Functions

-- 1. Ranking Function (Top products per region)

SELECT region,
       product_name,
       total_revenue,
       RANK() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS rank_position
FROM (
    SELECT c.region,
           p.product_name,
           SUM(t.quantity * p.unit_price) AS total_revenue
    FROM transactions t
    JOIN customers c ON t.customer_id = c.customer_id
    JOIN products p ON t.product_id = p.product_id
    GROUP BY c.region, p.product_name
) AS ranked_data;


-- 2. Running Monthly Revenue

SELECT month,
       monthly_revenue,
       SUM(monthly_revenue)
           OVER (ORDER BY month
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
           AS running_total
FROM (
    SELECT DATE_TRUNC('month', transaction_date) AS month,
           SUM(t.quantity * p.unit_price) AS monthly_revenue
    FROM transactions t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY DATE_TRUNC('month', transaction_date)
) AS monthly_data
ORDER BY month;


-- 3. Month-over-Month Growth

SELECT month,
       monthly_revenue,
       monthly_revenue -
       LAG(monthly_revenue) OVER (ORDER BY month) AS revenue_growth
FROM (
    SELECT DATE_TRUNC('month', transaction_date) AS month,
           SUM(t.quantity * p.unit_price) AS monthly_revenue
    FROM transactions t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY DATE_TRUNC('month', transaction_date)
) AS monthly_data
ORDER BY month;


-- 4. Customer Segmentation (Spending Quartiles)

SELECT customer_id,
       total_spent,
       NTILE(4) OVER (ORDER BY total_spent DESC) AS spending_quartile
FROM (
    SELECT t.customer_id,
           SUM(t.quantity * p.unit_price) AS total_spent
    FROM transactions t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY t.customer_id
) AS customer_spending;
