← [2.4 Data Types in PostgreSQL](04-postgresql-data-types.md)

# 2.5 Operators

Every query so far has either grabbed *everything* or matched one exact row.
Before the syntax, 3 real-world situations that need something in between.

## 3 real-world scenarios

**1. An online store's "Under $50" filter** — a shopper doesn't want every
product, just the ones cheap enough to qualify. Someone has to narrow down
the full catalog to exactly that subset.

**2. A university directory search** — typing "Al" should surface every
student whose name starts with those letters, without knowing the exact
full name in advance.

**3. A hospital follow-up list** — find every patient record that's missing
a recorded blood type, so staff can reach out and fill the gap. There's no
exact value to match against here — you're looking for what's *absent*.

## Why filtering matters

Each scenario needs to narrow a full table down to just the rows that matter
for one specific question — "cheap enough," "starts with these letters,"
"missing this value." That's exactly what filtering is for — the thing
you'll do in almost every query you ever write.

## Step 0 — Where our data stands right now

After every insert/update/delete from [Lesson 2.2](02-your-first-database-apple-example.md),
here's what `SELECT * FROM products;` returned — 8 rows (IDs 6, 8, 9 are gone —
those were the rows we deleted):

| product_id | name | category | price | stock |
|---|---|---|---|---|
| 1 | iPhone 17 Pro | smartphone | 1249.00 | 500 |
| 2 | MacBook Air | laptop | 989.10 | 300 |
| 3 | MacBook Pro | laptop | 1799.10 | 200 |
| 4 | iPad Air | tablet | 599.00 | 400 |
| 5 | iPad Pro | tablet | 999.00 | 350 |
| 7 | AirPods Max | audio | 549.00 | 250 |
| 10 | Mac Mini | desktop | 599.00 | 450 |
| 11 | iPhone 17 | smartphone | 999.00 | 600 |

Apple's lineup didn't stop growing there. `WHERE`, `BETWEEN`, `IN`, and `LIKE`
only really prove their worth once there's enough variety to filter through —
so let's bulk-insert the rest of the real-world catalog in one statement,
the same way [Lesson 2.2's Step 3b](02-your-first-database-apple-example.md)
added 10 rows at once:

```sql
INSERT INTO products (name, category, price, stock) VALUES
    -- more iPhones
    ('iPhone 17 Pro Max',        'smartphone', 1479.00,  400),
    ('iPhone 17 Plus',           'smartphone',  949.00,  550),
    ('iPhone 16',                'smartphone',  799.00,  700),
    ('iPhone 16 Plus',           'smartphone',  899.00,  500),
    ('iPhone 16 Pro',            'smartphone', 1099.00,  450),
    ('iPhone SE',                'smartphone',  429.00,  900),
    -- more laptops
    ('MacBook Pro 14',           'laptop',     1999.00,  250),
    ('MacBook Pro 16',           'laptop',     2499.00,  180),
    ('MacBook Air 15',           'laptop',     1299.00,  320),
    -- more tablets
    ('iPad mini',                'tablet',      499.00,  500),
    ('iPad',                     'tablet',      349.00,  800),
    ('iPad Pro 13',              'tablet',     1299.00,  300),
    -- more desktops
    ('iMac',                     'desktop',    1299.00,  260),
    ('Mac Studio',               'desktop',    1999.00,  150),
    ('Mac Pro',                  'desktop',    6999.00,   40),
    -- wearables
    ('Apple Watch Series 11',    'wearable',    399.00,  700),
    ('Apple Watch Ultra 3',      'wearable',    799.00,  260),
    ('Apple Watch SE',           'wearable',    249.00,  850),
    -- more audio
    ('AirPods Pro 3',            'audio',       249.00, 1000),
    ('AirPods 4',                'audio',       129.00, 1200),
    ('HomePod',                  'audio',       299.00,  300),
    ('HomePod mini',             'audio',        99.00,  900),
    ('Beats Studio Pro',         'audio',       349.00,  220),
    ('Beats Flex',               'audio',        49.99,  700),
    -- TV and displays
    ('Apple TV 4K',              'tv',          129.00,  800),
    ('Studio Display',           'display',    1599.00,  120),
    ('Pro Display XDR',          'display',    4999.00,   60),
    -- accessories
    ('Magic Keyboard',           'accessory',   179.00,  300),
    ('Magic Mouse',              'accessory',    79.00,  400),
    ('Magic Trackpad',           'accessory',   129.00,  350),
    ('Apple Pencil Pro',         'accessory',   129.00,  500),
    ('Apple Pencil (USB-C)',     'accessory',    79.00,  600),
    ('MagSafe Charger',          'accessory',    39.00,  900),
    ('20W USB-C Power Adapter',  'accessory',    19.00, 1500),
    ('USB-C to Lightning Cable', 'accessory',    19.00, 1400),
    ('Smart Folio for iPad',     'accessory',    79.00,  450),
    ('AirTag',                   'accessory',    29.00, 2000),
    ('Siri Remote',              'accessory',    59.00,  600),
    ('Silicone Case for iPhone', 'accessory',    49.00,  800),
    ('Clear Case for iPhone',    'accessory',    49.00,  750),
    ('Lightning to USB-C Adapter','accessory',   29.00, 1000),
    ('Thunderbolt 4 Pro Cable',  'accessory',    69.00,  500),
    ('World Traveler Adapter Kit','accessory',   39.00,  300),
    ('Beats Fit Pro',            'audio',       199.00,  400),
    ('Powerbeats Pro',           'audio',       249.00,  350);
```

That's 45 more rows (IDs 12–56), for **53 rows total**. Every example from
here on runs against this full 53-row catalog, so you can check every result
by eye.

## Step 1 — `WHERE` with comparison operators

```sql
SELECT name, price FROM products WHERE category = 'tablet';
```
| name | price |
|---|---|
| iPad Air | 599.00 |
| iPad Pro | 999.00 |
| iPad mini | 499.00 |
| iPad | 349.00 |
| iPad Pro 13 | 1299.00 |

```sql
SELECT name, price FROM products WHERE price > 1000;
```
| name | price |
|---|---|
| iPhone 17 Pro | 1249.00 |
| MacBook Pro | 1799.10 |
| iPhone 17 Pro Max | 1479.00 |
| iPhone 16 Pro | 1099.00 |
| MacBook Pro 14 | 1999.00 |
| MacBook Pro 16 | 2499.00 |
| MacBook Air 15 | 1299.00 |
| iPad Pro 13 | 1299.00 |
| iMac | 1299.00 |
| Mac Studio | 1999.00 |
| Mac Pro | 6999.00 |
| Studio Display | 1599.00 |
| Pro Display XDR | 4999.00 |

```sql
SELECT name FROM products WHERE category <> 'smartphone';
```
Returns every row **except** the 8 smartphones (`<>` means "not equal to") —
45 rows out of the 53.

| Operator | Meaning |
|---|---|
| `=` | equal to |
| `<>` or `!=` | not equal to |
| `<` / `<=` | less than / less than or equal |
| `>` / `>=` | greater than / greater than or equal |

## Step 2 — `BETWEEN` (inclusive range)

```sql
SELECT name, price FROM products WHERE price BETWEEN 500 AND 1000;
```
| name | price |
|---|---|
| MacBook Air | 989.10 |
| iPad Air | 599.00 |
| iPad Pro | 999.00 |
| AirPods Max | 549.00 |
| Mac Mini | 599.00 |
| iPhone 17 | 999.00 |
| iPhone 17 Plus | 949.00 |
| iPhone 16 | 799.00 |
| iPhone 16 Plus | 899.00 |
| Apple Watch Ultra 3 | 799.00 |

`BETWEEN 500 AND 1000` includes both endpoints — it's shorthand for
`price >= 500 AND price <= 1000`.

## Step 3 — `IN` (match any value in a list)

```sql
SELECT name, category FROM products WHERE category IN ('laptop', 'tablet');
```
| name | category |
|---|---|
| MacBook Air | laptop |
| MacBook Pro | laptop |
| iPad Air | tablet |
| iPad Pro | tablet |
| MacBook Pro 14 | laptop |
| MacBook Pro 16 | laptop |
| MacBook Air 15 | laptop |
| iPad mini | tablet |
| iPad | tablet |
| iPad Pro 13 | tablet |

Without `IN`, you'd need `WHERE category = 'laptop' OR category = 'tablet'` —
`IN` is just a cleaner way to write "matches any of these."

## Step 4 — `LIKE` (pattern matching on text)

```sql
SELECT name FROM products WHERE name LIKE 'iPhone%';
```
| name |
|---|
| iPhone 17 Pro |
| iPhone 17 |
| iPhone 17 Pro Max |
| iPhone 17 Plus |
| iPhone 16 |
| iPhone 16 Plus |
| iPhone 16 Pro |
| iPhone SE |

```sql
SELECT name FROM products WHERE name LIKE '%Pro%';
```
| name |
|---|
| iPhone 17 Pro |
| MacBook Pro |
| iPad Pro |
| iPhone 17 Pro Max |
| iPhone 16 Pro |
| MacBook Pro 14 |
| MacBook Pro 16 |
| iPad Pro 13 |
| Mac Pro |
| AirPods Pro 3 |
| Beats Studio Pro |
| Pro Display XDR |
| Apple Pencil Pro |
| Thunderbolt 4 Pro Cable |
| Beats Fit Pro |
| Powerbeats Pro |

`%` matches *any number* of characters. `'iPhone%'` means "starts with
iPhone"; `'%Pro%'` means "contains Pro anywhere."

## Step 5 — `IS NULL` / `IS NOT NULL`

None of our `products` columns allow `NULL` (they're all `NOT NULL`), so
there's nothing to demonstrate on this table. To see it clearly, imagine a
separate `customers` table where `phone` is optional:

```sql
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    phone       TEXT          -- allowed to be NULL: not every customer gives one
);

SELECT name FROM customers WHERE phone IS NULL;
```

⚠️ Never write `WHERE phone = NULL` — in SQL, `NULL` means "unknown," and
"unknown equals unknown" is itself unknown, not true. `= NULL` matches
**nothing**, silently. Always use `IS NULL` / `IS NOT NULL`.

## Step 6 — Combining conditions: `AND`, `OR`, `NOT`

```sql
SELECT name, price FROM products WHERE category = 'laptop' AND price < 1000;
```
| name | price |
|---|---|
| MacBook Air | 989.10 |

(The catalog has 5 laptops now, but only MacBook Air is under $1000 — MacBook
Pro at 1799.10, and the newer MacBook Pro 14/16 and MacBook Air 15 at
1999.00, 2499.00, and 1299.00, all fail the second condition, so `AND`
excludes them.)

```sql
SELECT name FROM products WHERE category = 'tablet' OR category = 'audio';
```
| name |
|---|
| iPad Air |
| iPad Pro |
| AirPods Max |
| iPad mini |
| iPad |
| iPad Pro 13 |
| AirPods Pro 3 |
| AirPods 4 |
| HomePod |
| HomePod mini |
| Beats Studio Pro |
| Beats Flex |
| Beats Fit Pro |
| Powerbeats Pro |

```sql
SELECT name FROM products WHERE NOT category = 'smartphone';
```
Same result as Step 1's `<>` example — `NOT` negates whatever condition
follows it.

> **Precedence trap**: `AND` binds tighter than `OR`. When mixing them, always
> add parentheses to be explicit:
> `WHERE category = 'laptop' AND (price < 1000 OR stock > 300)`

## Step 7 — Recap

| Operator | Purpose | Example |
|---|---|---|
| `=`, `<>`, `<`, `>`, `<=`, `>=` | Basic comparisons | `WHERE price > 1000` |
| `BETWEEN` | Inclusive range | `WHERE price BETWEEN 500 AND 1000` |
| `IN` | Match any of a list | `WHERE category IN ('laptop','tablet')` |
| `LIKE` | Text pattern match | `WHERE name LIKE 'iPhone%'` |
| `IS NULL` / `IS NOT NULL` | Check for missing values | `WHERE phone IS NULL` |
| `AND` / `OR` / `NOT` | Combine conditions | `WHERE category='laptop' AND price<1000` |

---
← [2.4 Data Types in PostgreSQL](04-postgresql-data-types.md) | Next: [2.6 Sort →](06-sort.md)
