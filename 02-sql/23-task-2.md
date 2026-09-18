← [Task 1](22-task-1.md)

# Task 2: Write the Queries — Lessons 2.12–2.21

2 practice tasks for each remaining Part 1 lesson — from
[2.12 Normalization](12-normalization.md) through
[2.20 Capstone](20-capstone.md), plus a closing pair tied to
[2.21 Part 1 Conclusion](21-conclusion.md) — 20 tasks total. Write the SQL
yourself first; each answer is hidden in a collapsed **Show answer** section.
Tasks build on the `customers` / `orders` / `order_items` / `products` /
`reviews` / `employees` schema from these lessons.

---

## 2.12 Normalization

**Task 1.** This flat table repeats customer info on every row:

| order_id | customer_name | customer_email | product_name | product_price |
|---|---|---|---|---|

Name which of the 3 anomalies (update, insertion, deletion) applies:
*"Deleting a customer's only order also erases every trace that the
customer exists."*

<details>
<summary>Show answer</summary>

This is a **deletion anomaly** — two unrelated facts (a customer's existence,
and one order they placed) are trapped in the same row, so deleting the
order destroys the customer record too.
</details>

**Task 2.** Split the flat table above into normalized tables satisfying 3NF
(one for customers, one for orders, one for products, one linking orders to
products). Write the `CREATE TABLE` statements, primary keys only (foreign
keys come in the next lesson).

<details>
<summary>Show answer</summary>

```sql
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    price      DECIMAL(10,2) NOT NULL
);

CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date  DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE order_items (
    order_id   INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity   INTEGER NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
```
</details>

---

## 2.13 Relationships & Foreign Keys

**Task 3.** Add the foreign keys to the `orders` and `order_items` tables
from Task 2, so an order must reference a real customer, and a line item
must reference a real order and a real product.

<details>
<summary>Show answer</summary>

```sql
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_items_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    ADD CONSTRAINT fk_items_product
    FOREIGN KEY (product_id) REFERENCES products(product_id);
```
</details>

**Task 4.** Write a version of the `orders.customer_id` foreign key that
automatically deletes a customer's orders when the customer is deleted.
Then explain why `RESTRICT` (the default) is usually the safer choice.

<details>
<summary>Show answer</summary>

```sql
customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE
```

`ON DELETE CASCADE` silently deletes every order (and, transitively, every
`order_items` row) belonging to that customer — convenient, but it can wipe
out far more data than intended in one command. `RESTRICT` forces you to
delete dependent rows on purpose, explicitly, first.
</details>

---

## 2.14 Joins

**Task 5.** Write a query returning every order's `order_id`, the
customer's `name`, and the `order_date` — only for customers who actually
have an order.

<details>
<summary>Show answer</summary>

```sql
SELECT o.order_id, c.name, o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;
```
</details>

**Task 6.** Write a query listing every customer's `name` and total number
of orders placed — including customers with **zero** orders, showing `0`
instead of blank.

<details>
<summary>Show answer</summary>

```sql
SELECT c.name, COUNT(o.order_id) AS num_orders
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name;
```

`LEFT JOIN` keeps every customer; `COUNT(o.order_id)` (not `COUNT(*)`)
naturally counts `0` for a customer with only `NULL` order columns.
</details>

---

## 2.15 Subqueries & CTEs

**Task 7.** Write a query returning every product priced above the overall
average price, using a subquery in `WHERE`.

<details>
<summary>Show answer</summary>

```sql
SELECT name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products);
```
</details>

**Task 8.** Rewrite this "average price per category, only categories above
700" query as a CTE instead of a `FROM`-subquery:

```sql
SELECT category, avg_price FROM (
    SELECT category, AVG(price) AS avg_price FROM products GROUP BY category
) AS stats
WHERE avg_price > 700;
```

<details>
<summary>Show answer</summary>

```sql
WITH category_stats AS (
    SELECT category, AVG(price) AS avg_price
    FROM products
    GROUP BY category
)
SELECT category, avg_price
FROM category_stats
WHERE avg_price > 700;
```
</details>

---

## 2.16 Constraints

**Task 9.** Add a `CHECK` constraint to an existing `products` table so
`price` must always be greater than `0`, and another so `stock` can never
go negative.

<details>
<summary>Show answer</summary>

```sql
ALTER TABLE products ADD CONSTRAINT price_positive CHECK (price > 0);
ALTER TABLE products ADD CONSTRAINT stock_non_negative CHECK (stock >= 0);
```
</details>

**Task 10.** Write the `order_items` table's composite primary key so that
the same product can never appear twice on the same order, and explain in
one sentence what that constraint enforces.

<details>
<summary>Show answer</summary>

```sql
PRIMARY KEY (order_id, product_id)
```

Neither `order_id` nor `product_id` is unique by itself, but the *pair*
must be — which enforces that a given order can't list the same product as
two separate line items.
</details>

---

## 2.17 Transactions

**Task 11.** Write a transaction that inserts a new order for
`customer_id = 3`, inserts one order item for `product_id = 4` with
`quantity = 2`, and reduces that product's stock by 2 — committing only if
every step succeeds.

<details>
<summary>Show answer</summary>

```sql
BEGIN;
INSERT INTO orders (customer_id, order_date) VALUES (3, CURRENT_DATE);
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (currval('orders_order_id_seq'), 4, 2, (SELECT price FROM products WHERE product_id = 4));
UPDATE products SET stock = stock - 2 WHERE product_id = 4;
COMMIT;
```
</details>

**Task 12.** Inside a transaction, you insert an order, then insert two
order items, then discover the second item was a mistake. Write the
statements needed to undo **only** that second item, using a `SAVEPOINT`,
while keeping the order and the first item.

<details>
<summary>Show answer</summary>

```sql
BEGIN;
INSERT INTO orders (customer_id, order_date) VALUES (2, CURRENT_DATE);
SAVEPOINT before_item_2;
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (6, 3, 1, 1799.10);
SAVEPOINT before_item_3;
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (6, 3, 1, 1799.10); -- mistake
ROLLBACK TO before_item_3;
COMMIT;
```
</details>

---

## 2.18 Indexes & Performance

**Task 13.** `order_items.product_id` is a foreign key that's frequently
joined against. Write the statement to index it, and explain why it isn't
indexed automatically.

<details>
<summary>Show answer</summary>

```sql
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
```

Unlike `PRIMARY KEY`/`UNIQUE` columns, PostgreSQL does **not** automatically
index foreign key columns — even though they're exactly the columns used to
`JOIN` back to the referenced table, so they need a manual `CREATE INDEX`.
</details>

**Task 14.** You create `CREATE INDEX idx_products_category_price ON
products(category, price);`. Which of these two queries can use it
efficiently, and which can't?

```sql
-- A
SELECT * FROM products WHERE category = 'laptop' AND price > 1000;
-- B
SELECT * FROM products WHERE price > 1000;
```

<details>
<summary>Show answer</summary>

Query **A** can use it efficiently — it filters on `category` (the leftmost
column) first, then `price`. Query **B** can't — the index is sorted by
`category` first, so without a `category` filter PostgreSQL can't jump
straight to a price range using this index.
</details>

---

## 2.19 Views

**Task 15.** Save this "total spent per customer" query as a view named
`customer_order_summary`:

```sql
SELECT c.customer_id, c.name AS customer,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent
FROM customers c
LEFT JOIN orders o       ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.name;
```

<details>
<summary>Show answer</summary>

```sql
CREATE VIEW customer_order_summary AS
SELECT c.customer_id, c.name AS customer,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent
FROM customers c
LEFT JOIN orders o       ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.name;
```
</details>

**Task 16.** Turn the same view into a **materialized** view named
`customer_order_summary_cached`, then write the command to refresh it.

<details>
<summary>Show answer</summary>

```sql
CREATE MATERIALIZED VIEW customer_order_summary_cached AS
SELECT c.customer_id, c.name AS customer,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent
FROM customers c
LEFT JOIN orders o       ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.name;

REFRESH MATERIALIZED VIEW customer_order_summary_cached;
```
</details>

---

## 2.20 Capstone

**Task 17.** Design and create a `reviews` table: each review belongs to one
customer and one product, has a rating from 1–5, an optional comment, a
timestamp, and a rule that a customer can only review a given product once.

<details>
<summary>Show answer</summary>

```sql
CREATE TABLE reviews (
    review_id   SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    product_id  INTEGER NOT NULL REFERENCES products(product_id),
    rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (customer_id, product_id)
);
```
</details>

**Task 18.** Write a query listing every product with its number of reviews
and average rating (rounded to 2 decimals), including products with zero
reviews, sorted best-rated first with unrated products last.

<details>
<summary>Show answer</summary>

```sql
SELECT p.product_id, p.name,
       COUNT(r.review_id) AS num_reviews,
       ROUND(AVG(r.rating), 2) AS avg_rating
FROM products p
LEFT JOIN reviews r ON r.product_id = p.product_id
GROUP BY p.product_id, p.name
ORDER BY avg_rating DESC NULLS LAST;
```
</details>

---

## 2.21 Part 1 Conclusion

**Task 19.** Using everything from Part 1, write one query that finds every
customer who has spent more than the *average* amount spent across all
customers — combining a `LEFT JOIN`, `GROUP BY`, and a subquery.

<details>
<summary>Show answer</summary>

```sql
WITH customer_totals AS (
    SELECT c.customer_id, c.name,
           COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o       ON o.customer_id = c.customer_id
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id, c.name
)
SELECT name, total_spent
FROM customer_totals
WHERE total_spent > (SELECT AVG(total_spent) FROM customer_totals);
```
</details>

**Task 20.** Write a role setup, following the principle of least privilege,
for a new `support_agent` role that can read every table but only update the
`reviews` table (e.g. to moderate comments) — nothing else.

<details>
<summary>Show answer</summary>

```sql
CREATE ROLE support_agent WITH LOGIN PASSWORD 'change_me_456';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO support_agent;
GRANT UPDATE ON reviews TO support_agent;
```

`support_agent` can read everything, but can only write to `reviews` — no
`INSERT`/`DELETE` anywhere, and no `UPDATE` on any other table.
</details>

---
← [Task 1](22-task-1.md) | Next: [3.1 What Is a Document Database? →](../03-document-db/01-what-is-a-document-database.md)
