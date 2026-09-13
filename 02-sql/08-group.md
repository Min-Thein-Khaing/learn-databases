← [2.7 Functions](07-functions.md)

# 2.8 Group

Before any syntax, 3 real-world situations that need a summary *per group*,
not one summary for everything.

## 3 real-world scenarios

**1. A shop** doesn't just want total sales overall — it wants total sales
**per category**, to see which category is actually driving revenue.

**2. A university** wants the average GPA **per department**, not one
average across every student in the school — a single overall number would
hide which departments are actually struggling.

**3. A hospital** wants the number of patients **per doctor**, to see who's
overloaded and who has room for more appointments.

## Why `GROUP BY`

[Lesson 2.7](07-functions.md) used `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` to
collapse the **entire** table into one summary row — but none of the 3
scenarios above want *one* number; they want one number **per bucket**
(category, department, doctor). `GROUP BY` does exactly that: the same
aggregate functions, applied separately to each group instead of the whole
table at once.

## Step 0 — Same data as before

Continuing with the full 53-row `products` table from
[Lesson 2.5](05-operators.md) and [Lesson 2.6](06-sort.md) — now spread
across 9 categories: `smartphone` (8), `laptop` (5), `tablet` (5), `audio`
(9), `desktop` (4), `wearable` (3), `tv` (1), `display` (2), and `accessory`
(16).

## Step 1 — `GROUP BY` in practice

Take scenario 1: *"how many products do we have in each category?"* Without
`GROUP BY`, you'd have to run `SELECT * FROM products`, then count by eye,
category by category. `GROUP BY` does this in one statement:

```sql
SELECT category, COUNT(*) AS num_products
FROM products
GROUP BY category;
```
| category | num_products |
|---|---|
| smartphone | 8 |
| laptop | 5 |
| tablet | 5 |
| audio | 9 |
| desktop | 4 |
| wearable | 3 |
| tv | 1 |
| display | 2 |
| accessory | 16 |

`GROUP BY category` collapses all rows sharing the same `category` value into
one row, and `COUNT(*)` — from [Lesson 2.7](07-functions.md) — counts how many
original rows fed into each group.

## Step 2 — The same aggregate functions, now per group

```sql
SELECT category, SUM(price) AS total_value, ROUND(AVG(price), 2) AS avg_price
FROM products
GROUP BY category;
```
| category | total_value | avg_price |
|---|---|---|
| smartphone | 7902.00 | 987.75 |
| laptop | 8585.20 | 1717.04 |
| tablet | 3745.00 | 749.00 |
| audio | 2171.99 | 241.33 |
| desktop | 10896.00 | 2724.00 |
| wearable | 1447.00 | 482.33 |
| tv | 129.00 | 129.00 |
| display | 6598.00 | 3299.00 |
| accessory | 1074.00 | 67.13 |

`SUM` adds up every `price` in the group; `AVG` divides that sum by the
group's row count — and now that groups hold anywhere from 1 to 16 rows,
most of those divisions don't land on a clean 2-decimal number (`audio`'s raw
average is `241.332222...`). That's exactly the real-world case
[Lesson 2.7](07-functions.md) warned about — wrapping it in `ROUND(..., 2)`
keeps the output readable, same as it did there. `tv` has only 1 row (Apple
TV 4K), so its sum and average are naturally the same number.

```sql
SELECT category, MIN(price) AS cheapest, MAX(price) AS priciest
FROM products
GROUP BY category;
```
| category | cheapest | priciest |
|---|---|---|
| smartphone | 429.00 | 1479.00 |
| laptop | 989.10 | 2499.00 |
| tablet | 349.00 | 1299.00 |
| audio | 49.99 | 549.00 |
| desktop | 599.00 | 6999.00 |
| wearable | 249.00 | 799.00 |
| tv | 129.00 | 129.00 |
| display | 1599.00 | 4999.00 |
| accessory | 19.00 | 179.00 |

## Step 3 — The rule: every non-aggregated column must be in `GROUP BY`

```sql
-- ❌ Error: "product_id" is neither grouped nor aggregated
SELECT category, product_id, COUNT(*) FROM products GROUP BY category;
```

PostgreSQL can't decide *which* `product_id` to show for a group containing
multiple rows — so it refuses. Every column in `SELECT` must either be:
1. Listed in `GROUP BY`, or
2. Wrapped in an aggregate function ([Lesson 2.7](07-functions.md)'s
   `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`).

## Step 4 — `HAVING`: filtering *groups*, not rows

`WHERE` filters individual rows **before** grouping happens. `HAVING` filters
**groups**, after they've been formed — and it's the only place you're
allowed to filter by an aggregate result:

```sql
SELECT category, COUNT(*) AS num_products
FROM products
GROUP BY category
HAVING COUNT(*) > 1;
```
| category | num_products |
|---|---|
| smartphone | 8 |
| laptop | 5 |
| tablet | 5 |
| audio | 9 |
| desktop | 4 |
| wearable | 3 |
| display | 2 |
| accessory | 16 |

Only `tv` (1 product — just Apple TV 4K) is filtered out — `HAVING` kept
every category with more than one product. You **cannot** write
`WHERE COUNT(*) > 1` — `WHERE` runs before grouping even exists yet, so it has
no groups to check a count against.

## Step 5 — `WHERE` and `HAVING` together

```sql
SELECT category, ROUND(AVG(price), 2) AS avg_price
FROM products
WHERE stock > 300
GROUP BY category
HAVING AVG(price) > 700;
```
| category | avg_price |
|---|---|
| smartphone | 987.75 |
| laptop | 1299.00 |

Walk through it in order:
1. **`WHERE stock > 300`** removes individual rows first, across every
   category. Some categories lose almost everything: `laptop` drops to just
   MacBook Air 15 (the only laptop with stock over 300), `desktop` drops to
   just Mac Mini, and `display` loses **both** its rows (Studio Display at
   120, Pro Display XDR at 60) — that category disappears from the result
   entirely, not even as a zero.
2. **`GROUP BY category`** buckets whatever survived step 1: all 8
   smartphones survive (every one has stock over 300), 4 of 5 tablets, 6 of 9
   audio products, 2 of 3 wearables, 1 of 4 desktops, 1 of 5 laptops, 1 of 1
   tv products, and 14 of 16 accessories — but 0 of 2 displays, so `display`
   has no group at all.
3. **`HAVING AVG(price) > 700`** checks each remaining group's average:
   `smartphone` = 987.75 ✅ and `laptop` = 1299.00 ✅ (its only surviving row,
   MacBook Air 15, easily clears 700 on its own) both pass. Every other
   surviving category falls short — `tablet` averages 611.50, `desktop` (Mac
   Mini alone) is 599.00, `audio` is about 162.50, `wearable` is 324.00, `tv`
   is 129.00, and `accessory` is about 61.14 — so all of them are dropped,
   leaving exactly the 2 rows shown above.

## Step 6 — The full logical order

```mermaid
flowchart LR
    A[FROM products] --> B[WHERE: filter rows]
    B --> C[GROUP BY: bucket rows]
    C --> D[HAVING: filter groups]
    D --> E[ORDER BY / LIMIT]
    E --> F[SELECT: choose columns]
```

`WHERE` only ever sees individual rows; `HAVING` only ever sees already-formed
groups. Mixing up which one you need is the most common `GROUP BY` mistake —
if your condition uses an aggregate function from
[Lesson 2.7](07-functions.md), it belongs in `HAVING`, never `WHERE`.

## Step 7 — Recap

| Clause | Filters | Can use aggregate functions? |
|---|---|---|
| `WHERE` | Individual rows, before grouping | No |
| `GROUP BY` | (buckets rows, doesn't filter) | — |
| `HAVING` | Groups, after grouping | Yes |

That wraps up the core query-building toolkit: operators to filter, `ORDER
BY`/`LIMIT` to sort and page, functions to reshape and summarize values, and
`GROUP BY`/`HAVING` to summarize per category.

---
← [2.7 Functions](07-functions.md) | Next: [2.9 Normalization →](09-normalization.md)
