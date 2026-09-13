← [2.5 Operators](05-operators.md)

# 2.6 Sort

Now that you can filter rows with [Operators](05-operators.md), let's control
the **order** they come back in. Before the syntax, 3 real-world situations.

## 3 real-world scenarios

**1. An online store's "Price: Low to High"** button — shoppers expect the
cheapest item first, not whatever order the database happens to store rows
in internally.

**2. A game leaderboard** — the highest scorer must appear at the very top,
every time, for every player who opens it.

**3. A news site's homepage** — articles must show newest first, so a
reader's most recent visit surfaces what actually changed since last time.

## Why sorting matters

None of these are about *which* rows come back — that's filtering
([Lesson 2.5](05-operators.md)). They're about the **order** those rows
appear in, and, often, only showing a *slice* of them (the top score, the
newest article). That's what this lesson covers.

## Step 0 — Same data as before

Continuing with the full `products` table exactly as it stood at the end of
[Lesson 2.5](05-operators.md) — 53 rows across 9 categories, after that
lesson's bulk insert grew the catalog well past the original 8 rows.

## Step 1 — `ORDER BY` (sorting)

```sql
SELECT name, price FROM products ORDER BY price ASC;
```
| name | price |
|---|---|
| 20W USB-C Power Adapter | 19.00 |
| USB-C to Lightning Cable | 19.00 |
| AirTag | 29.00 |
| Lightning to USB-C Adapter | 29.00 |
| MagSafe Charger | 39.00 |
| World Traveler Adapter Kit | 39.00 |
| Silicone Case for iPhone | 49.00 |
| Clear Case for iPhone | 49.00 |
| Beats Flex | 49.99 |
| Siri Remote | 59.00 |
| Thunderbolt 4 Pro Cable | 69.00 |
| Magic Mouse | 79.00 |
| Apple Pencil (USB-C) | 79.00 |
| Smart Folio for iPad | 79.00 |
| HomePod mini | 99.00 |
| AirPods 4 | 129.00 |
| Apple TV 4K | 129.00 |
| Magic Trackpad | 129.00 |
| Apple Pencil Pro | 129.00 |
| Magic Keyboard | 179.00 |
| Beats Fit Pro | 199.00 |
| Apple Watch SE | 249.00 |
| AirPods Pro 3 | 249.00 |
| Powerbeats Pro | 249.00 |
| HomePod | 299.00 |
| iPad | 349.00 |
| Beats Studio Pro | 349.00 |
| Apple Watch Series 11 | 399.00 |
| iPhone SE | 429.00 |
| iPad mini | 499.00 |
| AirPods Max | 549.00 |
| iPad Air | 599.00 |
| Mac Mini | 599.00 |
| iPhone 16 | 799.00 |
| Apple Watch Ultra 3 | 799.00 |
| iPhone 16 Plus | 899.00 |
| iPhone 17 Plus | 949.00 |
| MacBook Air | 989.10 |
| iPad Pro | 999.00 |
| iPhone 17 | 999.00 |
| iPhone 16 Pro | 1099.00 |
| iPhone 17 Pro | 1249.00 |
| MacBook Air 15 | 1299.00 |
| iPad Pro 13 | 1299.00 |
| iMac | 1299.00 |
| iPhone 17 Pro Max | 1479.00 |
| Studio Display | 1599.00 |
| MacBook Pro | 1799.10 |
| MacBook Pro 14 | 1999.00 |
| Mac Studio | 1999.00 |
| MacBook Pro 16 | 2499.00 |
| Pro Display XDR | 4999.00 |
| Mac Pro | 6999.00 |

All 53 rows, cheapest first — this doubles as a full price list of the
catalog. `ASC` (ascending, smallest first) is the default — you can leave it
off. `DESC` reverses it:

```sql
SELECT name, price FROM products ORDER BY price DESC;
```
Same rows, largest price first (Mac Pro at the top, the power adapter and
cable at the bottom).

## Step 2 — Rows can tie — sort by more than one column

Notice the repeated prices above — 19.00, 29.00, 39.00, 49.00, 129.00,
249.00, 349.00, 599.00, 799.00, 999.00, 1299.00, 1999.00 all appear more than
once. Every one of those is a **tie**, and PostgreSQL doesn't guarantee which
row comes first within a tie unless you tell it. Fix that by sorting on a
second column:

```sql
SELECT name, category, price FROM products ORDER BY category ASC, price DESC;
```
| name | category | price |
|---|---|---|
| Magic Keyboard | accessory | 179.00 |
| Magic Trackpad | accessory | 129.00 |
| Apple Pencil Pro | accessory | 129.00 |
| Magic Mouse | accessory | 79.00 |
| Apple Pencil (USB-C) | accessory | 79.00 |
| Smart Folio for iPad | accessory | 79.00 |
| Thunderbolt 4 Pro Cable | accessory | 69.00 |
| Siri Remote | accessory | 59.00 |
| Silicone Case for iPhone | accessory | 49.00 |
| Clear Case for iPhone | accessory | 49.00 |
| MagSafe Charger | accessory | 39.00 |
| World Traveler Adapter Kit | accessory | 39.00 |
| AirTag | accessory | 29.00 |
| Lightning to USB-C Adapter | accessory | 29.00 |
| 20W USB-C Power Adapter | accessory | 19.00 |
| USB-C to Lightning Cable | accessory | 19.00 |
| AirPods Max | audio | 549.00 |
| Beats Studio Pro | audio | 349.00 |
| HomePod | audio | 299.00 |
| AirPods Pro 3 | audio | 249.00 |
| Powerbeats Pro | audio | 249.00 |
| Beats Fit Pro | audio | 199.00 |
| AirPods 4 | audio | 129.00 |
| HomePod mini | audio | 99.00 |
| Beats Flex | audio | 49.99 |
| Mac Pro | desktop | 6999.00 |
| Mac Studio | desktop | 1999.00 |
| iMac | desktop | 1299.00 |
| Mac Mini | desktop | 599.00 |
| Pro Display XDR | display | 4999.00 |
| Studio Display | display | 1599.00 |
| MacBook Pro 16 | laptop | 2499.00 |
| MacBook Pro 14 | laptop | 1999.00 |
| MacBook Pro | laptop | 1799.10 |
| MacBook Air 15 | laptop | 1299.00 |
| MacBook Air | laptop | 989.10 |
| iPhone 17 Pro Max | smartphone | 1479.00 |
| iPhone 17 Pro | smartphone | 1249.00 |
| iPhone 16 Pro | smartphone | 1099.00 |
| iPhone 17 | smartphone | 999.00 |
| iPhone 17 Plus | smartphone | 949.00 |
| iPhone 16 Plus | smartphone | 899.00 |
| iPhone 16 | smartphone | 799.00 |
| iPhone SE | smartphone | 429.00 |
| iPad Pro 13 | tablet | 1299.00 |
| iPad Pro | tablet | 999.00 |
| iPad Air | tablet | 599.00 |
| iPad mini | tablet | 499.00 |
| iPad | tablet | 349.00 |
| Apple TV 4K | tv | 129.00 |
| Apple Watch Ultra 3 | wearable | 799.00 |
| Apple Watch Series 11 | wearable | 399.00 |
| Apple Watch SE | wearable | 249.00 |

Read this as: *"group by category alphabetically, and within each category,
show the most expensive first."* Ties within a category (like the two 129.00
accessories, or the two 249.00 audio products) are still unresolved here —
that needs a third sort column, same idea as Step 3 below.

## Step 3 — `LIMIT` and `OFFSET` (paging results)

```sql
SELECT name, price FROM products ORDER BY price DESC LIMIT 3;
```
| name | price |
|---|---|
| Mac Pro | 6999.00 |
| Pro Display XDR | 4999.00 |
| MacBook Pro 16 | 2499.00 |

No tie right at the cutoff this time — but push it one further and there is
one: `LIMIT 5` puts MacBook Pro 14 and Mac Studio (both 1999.00) in a tie for
4th/5th place. Exactly why real applications usually add `, product_id` as a
tiebreaker in `ORDER BY` whenever `LIMIT` is involved, so "the top N" is
always the same rows in the same order:

```sql
SELECT name, price FROM products ORDER BY price DESC, product_id ASC LIMIT 5;
```
| name | price |
|---|---|
| Mac Pro | 6999.00 |
| Pro Display XDR | 4999.00 |
| MacBook Pro 16 | 2499.00 |
| MacBook Pro 14 | 1999.00 |
| Mac Studio | 1999.00 |

`product_id ASC` breaks the 1999.00 tie deterministically (MacBook Pro 14 is
`product_id` 18, Mac Studio is 25 — 18 comes first).

```sql
SELECT name, price FROM products ORDER BY price DESC LIMIT 3 OFFSET 3;
```
Skips the first 3 results and returns the next 3 — this is how "page 2" of a
paginated list works.

## Step 4 — Putting `WHERE` and `ORDER BY` together

```sql
SELECT name, category, price
FROM products
WHERE category <> 'smartphone'
ORDER BY price ASC, product_id ASC
LIMIT 3;
```
| name | category | price |
|---|---|---|
| 20W USB-C Power Adapter | accessory | 19.00 |
| USB-C to Lightning Cable | accessory | 19.00 |
| AirTag | accessory | 29.00 |

The tiebreaker from Step 3 shows up again here — two accessories are tied at
19.00, so `ORDER BY price ASC` alone wouldn't guarantee which lands in the
top 3. Read the whole query top to bottom: *"take every non-smartphone
product, sort cheapest first (ties broken by ID), and show me just the top
3."* This is the logical order PostgreSQL actually processes a query in,
even though you type `SELECT` first:

```mermaid
flowchart LR
    A[FROM products] --> B[WHERE category <> 'smartphone']
    B --> C[ORDER BY price ASC]
    C --> D[LIMIT 3]
    D --> E[SELECT name, category, price]
```

## Step 5 — Recap

| Clause | Purpose | Example |
|---|---|---|
| `ORDER BY ... ASC/DESC` | Sort results | `ORDER BY price DESC` |
| Multi-column `ORDER BY` | Break ties deterministically | `ORDER BY category ASC, price DESC` |
| `LIMIT` | Take only the first N rows | `LIMIT 3` |
| `OFFSET` | Skip the first N rows (paging) | `LIMIT 3 OFFSET 3` |

---
← [2.5 Operators](05-operators.md) | Next: [2.7 Functions →](07-functions.md)
