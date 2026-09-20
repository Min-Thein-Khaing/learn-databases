← [3.10 Sort, Limit, Skip](10-sort-limit-skip.md)

# 3.11 Aggregation Functions

Same idea as [Lesson 2.7](../02-sql/07-functions.md) — computing something
from stored data, not just retrieving it as-is. In MongoDB, these live
inside an **aggregation pipeline** — a list of processing stages a
collection's documents flow through.

## Before starting: `$match`, `$group`, and `$project`

These are **aggregation pipeline stages**:

```text
documents → $match → $group → $project → result
```

- **`$match`** filters documents. Only matching documents continue.
- **`$group`** combines several input documents and calculates values such
  as a count, total, or average.
- **`$project`** chooses, removes, renames, or calculates fields in each
  output document.

For example:

```js
{ $match: { category: "laptop" } }
```

keeps laptop documents and removes all other documents from the pipeline.
Stages are optional: a pipeline uses only the stages needed for its task.

Consider this pipeline:

```js
db.products.aggregate([
  { $group: { _id: null, avgPrice: { $avg: "$price" } } },
  { $project: { _id: 0, average_price: { $round: ["$avgPrice", 2] } } }
])
```

Read the `$group` stage from the inside out:

```js
{
  $group: {                       // combine documents into groups
    _id: null,                    // put every document in one group
    avgPrice: {                   // name the calculated result avgPrice
      $avg: "$price"              // average the price field
    }
  }
}
```

If the input is:

```js
{ name: "Mouse", price: 20 }
{ name: "Keyboard", price: 40 }
{ name: "Monitor", price: 300 }
```

the `$group` stage produces one document:

```js
{ _id: null, avgPrice: 120 }
```

Then `$project` reshapes that document:

```js
{
  $project: {
    _id: 0,                                   // hide the _id field
    average_price: { $round: ["$avgPrice", 2] } // calculate and rename
  }
}
```

The final result is:

```js
{ average_price: 120 }
```

### What does `_id` mean inside `$group`?

Inside `$group`, `_id` defines the **grouping key**:

```js
_id: null         // one group containing every document
_id: "$category"  // one group for each category
_id: "$brand"     // one group for each brand
```

It does not mean the original document ID in this context.

### Why are field names written as strings with `$`?

```js
"$price"     // read the price field from each input document
"$avgPrice"  // read avgPrice from the previous stage's output
```

A quoted value beginning with `$` is a field path. Without `$`, `"price"`
would be ordinary text.

### Common `$project` forms

```js
{ $project: { name: 1, price: 1 } }                 // keep fields
{ $project: { password: 0 } }                       // remove a field
{ $project: { productName: "$name", price: 1 } }   // rename a field
{ $project: { total: { $multiply: ["$price", "$stock"] } } } // calculate
```

`_id` is included by default. Add `_id: 0` when you do not want it in the
result.

## Step 1 — Aggregate functions, summarizing the whole collection

```js
db.products.aggregate([
  { $group: {
      _id: null,
      count: { $sum: 1 },
      totalStock: { $sum: "$stock" },
      avgPrice: { $avg: "$price" }
  }}
]);
```
```
{ _id: null, count: 8, totalStock: 3050, avgPrice: 972.775 }
```

`_id: null` means "one group containing everything" — the MongoDB way of
saying "no `GROUP BY`, just summarize the whole collection," matching
[Lesson 2.7](../02-sql/07-functions.md)'s `SELECT COUNT(*), SUM(stock),
AVG(price) FROM products;` exactly, down to the same numbers.

| Accumulator | Does |
|---|---|
| `$sum: 1` | Counts documents |
| `$sum: "$field"` | Totals a numeric field |
| `$avg: "$field"` | Averages a numeric field |
| `$min` / `$max` | Smallest / largest value |

## Step 2 — Rounding: `$round`

```js
db.products.aggregate([
  { $group: { _id: null, avgPrice: { $avg: "$price" } } },
  { $project: { _id: 0, avgPrice: { $round: ["$avgPrice", 2] } } }
]);
```
```
{ avgPrice: 972.78 }
```

Same fix as [Lesson 2.7](../02-sql/07-functions.md)'s `ROUND(AVG(price), 2)`
— MongoDB just needs a second pipeline stage (`$project`) to reshape the
result, since `$round` isn't itself an accumulator.

Other math operators work the same way: `$ceil`, `$floor`, `$abs`.

## Step 3 — String operators

```js
db.products.aggregate([
  { $match: { _id: 1 } },
  { $project: { upper: { $toUpper: "$name" } } }
]);
```
```
{ upper: "IPHONE 17 PRO" }
```

| Operator | Does |
|---|---|
| `$toUpper` / `$toLower` | Case conversion |
| `$strLenCP` | String length |
| `$concat: ["$name", " (", "$category", ")"]` | Glue text together |
| `$substrCP` | Extract a substring |

`$match` here is the pipeline's equivalent of `WHERE` — filters *which*
documents enter the pipeline, always placed as early as possible.

## Step 4 — Date operators

```js
db.products.aggregate([
  { $match: { _id: 1 } },
  { $project: { year: { $year: "$created_at" } } }
]);
```
```
{ year: 2026 }
```

`$year`, `$month`, `$dayOfMonth`, and friends extract one part of a date —
the direct equivalent of SQL's `EXTRACT(YEAR FROM created_at)` from
[Lesson 2.7](../02-sql/07-functions.md).

## Step 5 — `$ifNull`: a default value for missing data

```js
db.customers.aggregate([
  { $project: { name: 1, phone: { $ifNull: ["$phone", "no phone provided"] } } }
]);
```

Direct equivalent of SQL's `COALESCE(phone, 'no phone provided')` — returns
the first non-null/non-missing value.

## Recap

| SQL ([Lesson 2.7](../02-sql/07-functions.md)) | MongoDB |
|---|---|
| `COUNT(*)`, `SUM`, `AVG`, `MIN`, `MAX` | `$sum`, `$avg`, `$min`, `$max` inside `$group` |
| `ROUND` | `$round` |
| `UPPER`/`LOWER`/`\|\|`/`LENGTH` | `$toUpper`/`$toLower`/`$concat`/`$strLenCP` |
| `EXTRACT(YEAR FROM ...)` | `$year` |
| `COALESCE` | `$ifNull` |

---
← [3.10 Sort, Limit, Skip](10-sort-limit-skip.md) | Next: [3.12 The `$group` Stage →](12-group-stage.md)
