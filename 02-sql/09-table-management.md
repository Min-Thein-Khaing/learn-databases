← [2.8 Group](08-group.md)

# 2.9 Table Management

[Lesson 2.2](02-your-first-database-apple-example.md) taught `CREATE TABLE`
with one example: `products`. Real projects need many different table
shapes, and tables keep changing after they're created — new columns,
renames, and eventually retirement. Let's practice creating several more
shapes, then cover the rest of a table's lifecycle: altering, dropping, and
choosing between the two.

## Step 1 — `IF NOT EXISTS`: safe to re-run

Setup scripts often get run more than once. Without `IF NOT EXISTS`, running
the same `CREATE TABLE` twice errors out the second time:

```sql
CREATE TABLE IF NOT EXISTS tasks (
    task_id     SERIAL PRIMARY KEY,
    title       TEXT NOT NULL,
    is_done     BOOLEAN NOT NULL DEFAULT FALSE,
    due_date    DATE,
    priority    TEXT NOT NULL DEFAULT 'medium'
                CHECK (priority IN ('low', 'medium', 'high'))
);
```

`CHECK (priority IN (...))` is a lightweight stand-in for a proper `ENUM`
type — restricting `priority` to exactly 3 allowed values, no misspellings.

```sql
INSERT INTO tasks (title, due_date, priority) VALUES
    ('Restock AirPods Max', '2026-04-01', 'high'),
    ('Update store hours page', NULL, 'low');
```

## Step 2 — A fresh domain: a small blog

A new domain, with one new wrinkle — `author_id` below points at another
table's primary key. That's a **foreign key**, formally covered soon in
[Lesson 2.13](13-relationships-and-foreign-keys.md); for now, just read
`REFERENCES authors(author_id)` as "this column's value must match a real
row over in `authors`":

```sql
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    name      TEXT NOT NULL
);

CREATE TABLE posts (
    post_id       SERIAL PRIMARY KEY,
    author_id     INTEGER NOT NULL REFERENCES authors(author_id),
    title         TEXT NOT NULL,
    slug          TEXT NOT NULL UNIQUE,   -- URL-friendly identifier, e.g. "hello-world"
    body          TEXT NOT NULL,
    published_at  TIMESTAMP    -- NULL means "still a draft"
);
```

`published_at` being nullable is a deliberate design choice: `NULL` means
"not published yet," rather than adding a separate `is_published BOOLEAN`
column that could disagree with the actual publish date.

```sql
INSERT INTO authors (name) VALUES ('Priya Patel');
INSERT INTO posts (author_id, title, slug, body, published_at) VALUES
    (1, 'Hello World', 'hello-world', 'Our first post!', '2026-03-01 09:00:00'),
    (1, 'Upcoming Sale', 'upcoming-sale', 'Draft — details TBD', NULL);
```

## Step 3 — Referencing a table from an earlier lesson

New tables don't have to stand alone — `warehouses` and `inventory` here
track *where* our existing `products` (from Part 1) are physically stocked:

```sql
CREATE TABLE warehouses (
    warehouse_id SERIAL PRIMARY KEY,
    city         TEXT NOT NULL
);

CREATE TABLE inventory (
    warehouse_id INTEGER REFERENCES warehouses(warehouse_id),
    product_id   INTEGER REFERENCES products(product_id),  -- reuses Lesson 2.2's table
    quantity     INTEGER NOT NULL CHECK (quantity >= 0),
    PRIMARY KEY (warehouse_id, product_id)   -- a composite key: two columns, together, as the key
);
```

```sql
INSERT INTO warehouses (city) VALUES ('Austin'), ('Newark');
INSERT INTO inventory (warehouse_id, product_id, quantity) VALUES
    (1, 1, 120),   -- 120 iPhone 17 Pro in Austin
    (2, 1, 80);    -- 80 iPhone 17 Pro in Newark
```

## Step 4 — `CREATE TABLE AS`: snapshot a query into a real table

`CREATE TABLE ... AS` runs a `SELECT`, then **freezes** its result into a
brand new, independent table, as of right now:

```sql
CREATE TABLE products_snapshot_2026_q1 AS
SELECT * FROM products;
```

Later changes to `products` — a price update, a new product — **never**
touch `products_snapshot_2026_q1` again; it's a genuine copy, not a saved
query. Useful for "what did our catalog look like at the end of Q1?"
reporting, where you specifically want the past preserved, not the present.
([Lesson 2.19](19-views.md) covers the opposite idea — a `VIEW`, which
stays **live** and re-runs its query every time instead of freezing it.)

## Step 5 — Temporary tables: scratch work that cleans itself up

```sql
CREATE TEMP TABLE price_check AS
SELECT product_id, name, price FROM products WHERE price > 1000;

SELECT * FROM price_check;   -- use it like any table, for the rest of this session
```

A `TEMP` table exists only for your current database session — close the
connection, and PostgreSQL drops it automatically. Handy for a multi-step
script's intermediate results, without leaving cleanup tables behind in your
real schema.

## Step 6 — `ALTER TABLE`: updating a table's structure

`CREATE TABLE` only gets you the starting shape. Real tables change over
time — a new feature needs a new column, a column gets renamed, a type
turns out to be wrong. `ALTER TABLE` edits an existing table **in place**,
without touching the rows already in it:

```sql
-- Add a column (existing rows get the DEFAULT, or NULL if you don't give one)
ALTER TABLE tasks ADD COLUMN assigned_to TEXT;

-- Rename a column
ALTER TABLE tasks RENAME COLUMN assigned_to TO owner;

-- Change a column's type
ALTER TABLE tasks ALTER COLUMN owner TYPE VARCHAR(100);

-- Drop a column entirely — the data in it is gone, permanently
ALTER TABLE tasks DROP COLUMN owner;

-- Rename the whole table
ALTER TABLE tasks RENAME TO todo_items;
```

The same command family also bolts a rule onto an existing table instead of
a column — `ALTER TABLE ... ADD CONSTRAINT` — which
[Lesson 2.16](16-constraints.md) covers properly alongside every other
constraint type.

⚠️ Adding a column with `NOT NULL` and no `DEFAULT` fails immediately on a
table that already has rows — Postgres has no value to backfill existing
rows with. Give it a `DEFAULT`, or add the column first and fill it in with
an `UPDATE` before adding the `NOT NULL` constraint separately.

## Step 7 — `DROP TABLE` and `TRUNCATE`: deleting tables and their data

Three commands remove data, but at very different scopes:

```sql
-- Remove specific rows, structure stays (this is DML — see Lesson 2.3)
DELETE FROM tasks WHERE is_done = TRUE;

-- Remove ALL rows, structure stays — faster than DELETE, resets any SERIAL counter
TRUNCATE TABLE tasks;

-- Remove the table itself: structure AND data, gone
DROP TABLE IF EXISTS tasks;
```

`IF EXISTS` on `DROP TABLE` mirrors `IF NOT EXISTS` from Step 1 — safe to
re-run a teardown script without erroring if the table's already gone.

If another table references this one with `REFERENCES` (like `inventory`
references `products` in Step 3), a plain `DROP TABLE` refuses to run —
PostgreSQL won't silently break a foreign key. Add `CASCADE` to drop the
dependent data too, or `RESTRICT` (the default) to keep that safety net:

```sql
DROP TABLE warehouses CASCADE;   -- also drops rows/constraints in inventory that depend on it
```

| Command | Removes | Structure survives? | Rollback in a transaction? | Resets `SERIAL`? |
|---|---|---|---|---|
| `DELETE ... WHERE` | Matching rows | Yes | Yes | No |
| `TRUNCATE` | All rows | Yes | Yes | Yes |
| `DROP TABLE` | Everything — table, data, indexes | No | Yes | N/A — table's gone |

## Step 8 — Pros and cons: evolving a table in place vs. rebuilding it

Once a table has real data and other tables depending on it, "just change
it" has more than one meaning. Three common strategies, and their trade-offs:

| Approach | Pros | Cons |
|---|---|---|
| `ALTER TABLE` in place (Step 6) | Data, foreign keys, and permissions stay intact; simplest to write | On a huge table, some alterations (e.g. adding a `NOT NULL` column with no default, pre-Postgres 11) can lock the table and rewrite every row |
| `DROP TABLE` + `CREATE TABLE` from scratch | Clean slate, no leftover legacy columns or constraints | **All data is lost** unless you exported it first; every foreign key pointing at it breaks until recreated |
| `CREATE TABLE ... AS` a new table, then swap names (Step 4's technique) | Old table stays untouched and queryable until the swap; easy to abandon if something looks wrong | Temporarily doubles storage; dependent views/foreign keys need to be pointed at the new table manually |

Rule of thumb: reach for `ALTER TABLE` for routine changes (new column,
rename, new constraint). Reach for the rebuild-and-swap pattern only for
a structural overhaul you want to verify before committing to — and always
inside a transaction ([Lesson 2.17](17-transactions.md)) so a bad swap can
be rolled back.

## Step 9 — Recap: every table-management technique so far

| Technique | Where it's covered |
|---|---|
| Basic columns + types | [Lesson 2.2](02-your-first-database-apple-example.md) |
| `PRIMARY KEY`, `REFERENCES`, `CHECK`, `UNIQUE`, `DEFAULT` (in depth) | [Lesson 2.16](16-constraints.md) |
| Composite `PRIMARY KEY` (in depth) | [Lesson 2.13](13-relationships-and-foreign-keys.md); previewed in Step 3 above |
| `IF NOT EXISTS` | Step 1 above |
| Nullable column as a meaningful state (not just "missing data") | Step 2 above |
| Referencing a table from a different lesson/domain | Step 3 above |
| `CREATE TABLE ... AS` (snapshot, not live) | Step 4 above |
| `CREATE TEMP TABLE` (session-scoped) | Step 5 above |
| `ALTER TABLE` — add/rename/retype/drop a column, rename a table | Step 6 above |
| `DROP TABLE` / `TRUNCATE` — deleting tables and data, with `CASCADE` / `IF EXISTS` | Step 7 above |
| Choosing `ALTER` vs. rebuild-and-swap | Step 8 above |

---
← [2.8 Group](08-group.md) | Next: [2.10 The PostgreSQL CLI →](10-postgres-cli.md)
