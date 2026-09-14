← [2.21 Part 1 Conclusion](21-conclusion.md)

# Task 1: Write the Queries — Lessons 2.1–2.11

15 practice tasks covering [2.1 What Is SQL?](01-what-is-sql.md) through
[2.11 User & Permission Management](11-user-permission-management.md). Write
the SQL yourself first — the answer is hidden in each collapsed **Show
answer** section below it. All tasks use the `apple_store` schema built up
across those lessons: `products`, `customers`, `tasks`, `authors`/`posts`,
and the `app_user`/`read_only`/`analyst` roles. Tasks 11–15 are an extra
round, all against the 53-row `products` catalog from
[2.5 Operators](05-operators.md), combining searching, filtering, sorting,
and grouping in one query each — the way a real report actually looks.

---

### Task 1 — CRUD basics

Using the `products` table from [2.2 Your First Database](02-your-first-database-apple-example.md):

1. Insert a new product: `'iPhone Air'`, category `'smartphone'`, price `999.00`, stock `450`.
2. Select the `name` and `price` of every product in the `'audio'` category.
3. Raise the price of `product_id = 4` to `649.00`, remembering `updated_at`.
4. Delete the product with `product_id = 20`.

<details>
<summary>Show answer</summary>

```sql
-- 1. Insert
INSERT INTO products (name, category, price, stock)
VALUES ('iPhone Air', 'smartphone', 999.00, 450);

-- 2. Select
SELECT name, price FROM products WHERE category = 'audio';

-- 3. Update
UPDATE products
SET price = 649.00, updated_at = CURRENT_TIMESTAMP
WHERE product_id = 4;

-- 4. Delete
DELETE FROM products WHERE product_id = 20;
```

`INSERT`=Create, `SELECT`=Read, `UPDATE`=Update, `DELETE`=Delete — the 4
CRUD actions from [2.1 What Is SQL?](01-what-is-sql.md), all performed on
one table.
</details>

---

### Task 2 — Naming the command category

For each statement below, name its category (DDL, DML, DQL, or DCL) from
[2.3 Types of SQL Queries](03-types-of-sql-queries.md):

1. `ALTER TABLE products ADD COLUMN discount DECIMAL(5,2);`
2. `SELECT * FROM products WHERE stock = 0;`
3. `GRANT SELECT ON products TO analyst;`
4. `INSERT INTO products (name, category, price) VALUES ('Magic Mouse', 'accessory', 79.00);`

<details>
<summary>Show answer</summary>

1. **DDL** — `ALTER` changes structure, not data.
2. **DQL** — `SELECT` only reads, never changes anything.
3. **DCL** — `GRANT` controls permissions.
4. **DML** — `INSERT` changes the data itself.
</details>

---

### Task 3 — Choosing data types

Write a `CREATE TABLE customers` statement with: an auto-incrementing primary
key, a required name, a unique required email, an optional phone number, and
a boolean `is_verified` that defaults to `false`. Use the correct type for
each from [2.4 Data Types in PostgreSQL](04-postgresql-data-types.md).

<details>
<summary>Show answer</summary>

```sql
CREATE TABLE customers (
    customer_id  SERIAL PRIMARY KEY,
    name         TEXT NOT NULL,
    email        TEXT NOT NULL UNIQUE,
    phone        TEXT,
    is_verified  BOOLEAN NOT NULL DEFAULT FALSE
);
```

`SERIAL` auto-increments; `phone` has no `NOT NULL` since it's optional;
`BOOLEAN` only ever holds `TRUE`/`FALSE`, never text like `"yes"`.
</details>

---

### Task 4 — Filtering with operators

Against the 53-row `products` catalog from [2.5 Operators](05-operators.md),
write one query for each:

1. Every product priced between `100` and `500`, inclusive.
2. Every product whose category is `'laptop'` or `'tablet'`.
3. Every product whose name contains the word `"Pro"`.
4. Every laptop under `1000.00` **or** with stock over `300` — using explicit parentheses.

<details>
<summary>Show answer</summary>

```sql
-- 1.
SELECT name, price FROM products WHERE price BETWEEN 100 AND 500;

-- 2.
SELECT name, category FROM products WHERE category IN ('laptop', 'tablet');

-- 3.
SELECT name FROM products WHERE name LIKE '%Pro%';

-- 4.
SELECT name FROM products
WHERE category = 'laptop' AND (price < 1000 OR stock > 300);
```

Parentheses in #4 matter — `AND` binds tighter than `OR`, so without them
the condition would be misread.
</details>

---

### Task 5 — Sorting and paging

From [2.6 Sort](06-sort.md):

1. List every product's `name` and `price`, most expensive first.
2. Return only the 5 cheapest products, breaking ties by `product_id ASC`.
3. Return "page 2" of the catalog sorted by price ascending, 10 rows per page.

<details>
<summary>Show answer</summary>

```sql
-- 1.
SELECT name, price FROM products ORDER BY price DESC;

-- 2.
SELECT name, price FROM products ORDER BY price ASC, product_id ASC LIMIT 5;

-- 3.
SELECT name, price FROM products ORDER BY price ASC LIMIT 10 OFFSET 10;
```

Page 2 means skipping page 1's 10 rows (`OFFSET 10`) before taking the next
10 (`LIMIT 10`).
</details>

---

### Task 6 — Functions

From [2.7 Functions](07-functions.md):

1. Count how many products exist in total, and find their average price, rounded to 2 decimal places.
2. Show every product's name in uppercase, alongside its category.
3. Build a single text label per product like `"iPhone 17 Pro (smartphone)"`.

<details>
<summary>Show answer</summary>

```sql
-- 1.
SELECT COUNT(*) AS num_products, ROUND(AVG(price), 2) AS avg_price
FROM products;

-- 2.
SELECT UPPER(name) AS name, category FROM products;

-- 3.
SELECT name || ' (' || category || ')' AS label FROM products;
```
</details>

---

### Task 7 — Group and having

From [2.8 Group](08-group.md):

1. Show the number of products and total stock, per category.
2. Show only the categories where the average price is above `700`.
3. Explain in one sentence why `SELECT category, product_id, COUNT(*) FROM products GROUP BY category;` fails.

<details>
<summary>Show answer</summary>

```sql
-- 1.
SELECT category, COUNT(*) AS num_products, SUM(stock) AS total_stock
FROM products
GROUP BY category;

-- 2.
SELECT category, ROUND(AVG(price), 2) AS avg_price
FROM products
GROUP BY category
HAVING AVG(price) > 700;
```

3. It fails because `product_id` is neither listed in `GROUP BY` nor wrapped
in an aggregate function — PostgreSQL can't decide which single
`product_id` to display for a group that contains multiple rows.
</details>

---

### Task 8 — Altering a table

From [2.9 Table Management](09-table-management.md), the `tasks` table already
exists. Write the statements to:

1. Add a nullable `assigned_to` text column.
2. Rename that column to `owner`.
3. Safely drop the whole table if it exists.

<details>
<summary>Show answer</summary>

```sql
-- 1.
ALTER TABLE tasks ADD COLUMN assigned_to TEXT;

-- 2.
ALTER TABLE tasks RENAME COLUMN assigned_to TO owner;

-- 3.
DROP TABLE IF EXISTS tasks;
```
</details>

---

### Task 9 — The `psql` CLI

From [2.10 The PostgreSQL CLI](10-postgres-cli.md), write the **meta-command**
(not SQL) to:

1. List every database on the server.
2. Switch your session to the `apple_store` database.
3. List every table in the current database.
4. Describe the `products` table's columns, types, and constraints.

<details>
<summary>Show answer</summary>

```
1. \l
2. \c apple_store
3. \dt
4. \d products
```

None of these end in `;` — they're `psql`-only shortcuts, not SQL sent to
PostgreSQL itself.
</details>

---

### Task 10 — Users and permissions

From [2.11 User & Permission Management](11-user-permission-management.md):

1. Create a login role named `app_user` with password `'change_me_123'`.
2. Grant it `SELECT`, `INSERT`, and `UPDATE` (but not `DELETE`) on `products`.
3. Later, take away just its `UPDATE` permission on `products`.
4. Create a `read_only` role granted `SELECT` on every table in the `public` schema, then make `app_user` inherit it.

<details>
<summary>Show answer</summary>

```sql
-- 1.
CREATE ROLE app_user WITH LOGIN PASSWORD 'change_me_123';

-- 2.
GRANT SELECT, INSERT, UPDATE ON products TO app_user;

-- 3.
REVOKE UPDATE ON products FROM app_user;

-- 4.
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;
GRANT read_only TO app_user;
```

`app_user` can now `SELECT`/`INSERT` on `products` (its own `UPDATE` was
revoked in step 3) and inherits read access to every other table via
`read_only` — least privilege, not `GRANT ALL PRIVILEGES`.
</details>

---

### Task 11 — Search + filter + sort together

Find every product whose name contains `"iPhone"` (search), priced under
`1000.00` (filter), cheapest first, breaking any tie by `product_id` (sort).

<details>
<summary>Show answer</summary>

```sql
SELECT name, price
FROM products
WHERE name LIKE '%iPhone%' AND price < 1000.00
ORDER BY price ASC, product_id ASC;
```

`LIKE` searches the name, `WHERE ... AND` narrows by price, and the
2-column `ORDER BY` sorts cheapest first with a deterministic tiebreaker —
exactly the 3 skills from [2.5 Operators](05-operators.md) and
[2.6 Sort](06-sort.md), combined in one query.
</details>

---

### Task 12 — Filter + sort + limit ("top N" report)

Excluding the `'smartphone'` category (filter), return the 5 most expensive
remaining products (sort + limit), showing `name`, `category`, and `price`.

<details>
<summary>Show answer</summary>

```sql
SELECT name, category, price
FROM products
WHERE category <> 'smartphone'
ORDER BY price DESC, product_id ASC
LIMIT 5;
```

This is the same logical pipeline as
[2.6 Sort, Step 4](06-sort.md): `WHERE` filters first, `ORDER BY` sorts
what's left, then `LIMIT` takes just the top slice.
</details>

---

### Task 13 — Filter + group + having

Among products with `stock` over `300` (filter), show each category's
average price rounded to 2 decimals (group), but only for categories
averaging above `700` (having).

<details>
<summary>Show answer</summary>

```sql
SELECT category, ROUND(AVG(price), 2) AS avg_price
FROM products
WHERE stock > 300
GROUP BY category
HAVING AVG(price) > 700;
```

`WHERE` removes individual rows before grouping ever happens;
`HAVING` then filters the *groups* by their computed average — mixing the
two up is the most common `GROUP BY` mistake, per
[2.8 Group, Step 5](08-group.md).
</details>

---

### Task 14 — Group + sort + limit (a ranked summary)

Show the **top 3 categories** by total inventory value
(`price * stock`, summed per category), highest value first.

<details>
<summary>Show answer</summary>

```sql
SELECT category, SUM(price * stock) AS inventory_value
FROM products
GROUP BY category
ORDER BY inventory_value DESC
LIMIT 3;
```

Grouping happens first (one row per category), then the group-level totals
are sorted and trimmed down to the top 3 — sort/limit work identically on
grouped rows as they do on plain ones.
</details>

---

### Task 15 — Search + filter + group + having + sort, all at once

Among products whose name contains `"Pro"` (search) and are priced above
`200` (filter), group by category and show the count and average price per
category (group), keeping only categories with **more than 1** matching
product (having), ordered by average price descending (sort).

<details>
<summary>Show answer</summary>

```sql
SELECT category,
       COUNT(*) AS num_products,
       ROUND(AVG(price), 2) AS avg_price
FROM products
WHERE name LIKE '%Pro%' AND price > 200
GROUP BY category
HAVING COUNT(*) > 1
ORDER BY avg_price DESC;
```

Read it in PostgreSQL's real execution order, from
[2.6 Sort, Step 4](06-sort.md) and [2.8 Group, Step 6](08-group.md):
`FROM` → `WHERE` (search + filter) → `GROUP BY` → `HAVING` → `ORDER BY` →
`SELECT`. Every clause from this lesson block, in one query.
</details>

---
← [2.21 Part 1 Conclusion](21-conclusion.md) | Next: [Task 2 →](23-task-2.md)
