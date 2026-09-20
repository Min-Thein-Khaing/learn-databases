← [3.14 Relationships in MongoDB](14-relationships-in-mongodb.md)

# 3.15 `$lookup` and `$unwind`

Use **`$lookup`** when one document needs information from another
collection. Use **`$unwind`** when an array needs to become separate
documents.

The short version is:

```text
$lookup  = find matching documents and place them in an array
$unwind  = create one output document for each item in an array
```

## Step 1 — Understand the starting data

Suppose `orders` contains:

```js
{
  _id: 1,
  customer_id: 101,
  order_date: "2026-03-01"
}
```

And `customers` contains:

```js
{
  _id: 101,
  name: "Alice Chen"
}
```

The order only knows the customer's ID. We want to attach the matching
customer document to the order.

## Step 2 — `$lookup` finds and attaches matches

```js
db.orders.aggregate([
  {
    $lookup: {
      from: "customers",
      localField: "customer_id",
      foreignField: "_id",
      as: "customer"
    }
  }
]);
```

Read the options like this:

| Option | Meaning |
|---|---|
| `from` | Search this collection |
| `localField` | Read this field from the current order |
| `foreignField` | Compare it with this field in `customers` |
| `as` | Store the matches under this new field |

MongoDB compares `orders.customer_id` with `customers._id`. The result is:

```js
{
  _id: 1,
  customer_id: 101,
  order_date: "2026-03-01",
  customer: [
    { _id: 101, name: "Alice Chen" }
  ]
}
```

The important detail is that **`$lookup` always creates an array**. There
may be zero, one, or many matching documents, so MongoDB always uses the
same result shape.

## Step 3 — `$unwind` opens the array

After `$lookup`, `customer` is an array containing one customer. This stage:

```js
{ $unwind: "$customer" }
```

### Why is `"$customer"` written as a string?

Inside an aggregation stage, a string beginning with `$` is a **field
path**. MongoDB reads `"$customer"` as “use the value stored in the
`customer` field.”

```js
"$customer"       // the customer field
"$customer.name"  // the name field inside customer
"customer"        // ordinary text, not a field path
```

The quotation marks are JavaScript/BSON syntax for a string. The `$` tells
the aggregation engine to interpret that string as a reference to a field.

There are two different uses of `$` in this stage:

```js
{ $unwind: "$customer" }
//  ^ operator   ^ field path
```

- `$unwind` is the name of an aggregation operator.
- `"$customer"` refers to the document's `customer` field.

If you genuinely need text that begins with `$`, use `$literal` in an
expression:

```js
{ $project: { message: { $literal: "$customer" } } }
```

That produces the text `$customer` instead of reading the field.

changes this:

```js
{ customer: [{ _id: 101, name: "Alice Chen" }] }
```

into this:

```js
{ customer: { _id: 101, name: "Alice Chen" } }
```

Now `customer.name` is easy to read. The full pipeline is:

```js
db.orders.aggregate([
  { $lookup: { from: "customers", localField: "customer_id", foreignField: "_id", as: "customer" } },
  { $unwind: "$customer" },
  { $project: { _id: 1, "customer.name": 1, order_date: 1 } }
]);
```
| _id | customer.name | order_date |
|---|---|---|
| 1 | Alice Chen | 2026-03-01 |
| 2 | Bob Diaz | 2026-03-02 |
| 3 | Alice Chen | 2026-03-05 |

Use `$unwind` after `$lookup` when you want to process each match separately.
Do not unwind when you want to keep all matches together as an array.

## What `$unwind` does with several items

Given one document:

```js
{ order_id: 1, items: ["iPhone", "AirPods"] }
```

this stage:

```js
{ $unwind: "$items" }
```

produces two documents:

```js
{ order_id: 1, items: "iPhone" }
{ order_id: 1, items: "AirPods" }
```

`$unwind` does not merely remove square brackets. It can turn **one input
document into many output documents**.

By default, `$unwind` removes a document when the array is empty or missing.
To keep that document, use:

```js
{
  $unwind: {
    path: "$customer",
    preserveNullAndEmptyArrays: true
  }
}
```

## Step 4 — Keep several matches as an array

```js
db.customers.aggregate([
  { $lookup: { from: "orders", localField: "_id", foreignField: "customer_id", as: "orders" } }
]);
```
| name | orders |
|---|---|
| Alice Chen | `[order 1, order 3]` |
| Bob Diaz | `[order 2]` |
| Carla Ruiz | `[]` (empty array) |

Unlike SQL's `LEFT JOIN` ([Lesson 2.11](../02-sql/14-joins.md)), which fills
unmatched rows with `NULL` columns, `$lookup` keeps **every** customer and
gives Carla an **empty array**, not a missing/null field — worth remembering
since checking for "no match" looks different:

```js
db.customers.aggregate([
  { $lookup: { from: "orders", localField: "_id", foreignField: "customer_id", as: "orders" } },
  { $match: { orders: { $size: 0 } } }
]);
```
| name |
|---|
| Carla Ruiz |

`{ orders: { $size: 0 } }` is the MongoDB equivalent of SQL's
`WHERE o.order_id IS NULL` trick.

## Step 5 — No dedicated `RIGHT JOIN` or `FULL OUTER JOIN`

Same fix as SQL's `RIGHT JOIN` note ([Lesson 2.11](../02-sql/14-joins.md)) —
just start the pipeline from the other collection. A true `FULL OUTER JOIN`
equivalent exists (`$unionWith` combined with two opposite `$lookup`s), but
it's rare enough in practice that most teams restructure the question
instead of reaching for it.

## Step 6 — Joining 4 collections with references

```js
db.order_items.aggregate([
  { $lookup: { from: "orders", localField: "order_id", foreignField: "_id", as: "order" } },
  { $unwind: "$order" },
  { $lookup: { from: "customers", localField: "order.customer_id", foreignField: "_id", as: "customer" } },
  { $unwind: "$customer" },
  { $lookup: { from: "products", localField: "product_id", foreignField: "_id", as: "product" } },
  { $unwind: "$product" },
  { $project: {
      customer: "$customer.name",
      order_id: "$order_id",
      product: "$product.name",
      quantity: "$quantity",
      unit_price: "$unit_price",
      line_total: { $multiply: ["$quantity", "$unit_price"] }
  }},
  { $sort: { order_id: 1 } }
]);
```
| customer | order_id | product | quantity | unit_price | line_total |
|---|---|---|---|---|---|
| Alice Chen | 1 | iPhone 17 Pro | 1 | 1249.00 | 1249.00 |
| Alice Chen | 1 | AirPods Max | 1 | 549.00 | 549.00 |
| Bob Diaz | 2 | MacBook Air | 1 | 989.10 | 989.10 |
| Alice Chen | 3 | iPad Pro | 1 | 999.00 | 999.00 |
| Alice Chen | 3 | Mac Mini | 1 | 599.00 | 599.00 |

Same result as [Lesson 2.11](../02-sql/14-joins.md)'s SQL join. Each
`order_items` document already represents one line item, so the pipeline
joins it to its order, customer, and product.

## Step 7 — Bonus: total spent per customer

```js
db.customers.aggregate([
  { $lookup: { from: "orders", localField: "_id", foreignField: "customer_id", as: "orders" } },
  { $lookup: { from: "order_items", localField: "orders._id", foreignField: "order_id", as: "items" } },
  { $project: {
      name: 1,
      total_spent: {
        $sum: {
          $map: {
            input: "$items",
            as: "item",
            in: { $multiply: ["$$item.quantity", "$$item.unit_price"] }
          }
        }
      }
  }},
  { $sort: { total_spent: -1 } }
]);
```
| name | total_spent |
|---|---|
| Alice Chen | 3396.00 |
| Bob Diaz | 989.10 |
| Carla Ruiz | 0 |

Same numbers as [Lesson 2.11](../02-sql/14-joins.md)'s SQL version. The
first `$lookup` gets each customer's orders and the second gets their line
items. `$map` computes each line's value and `$sum` totals it.

## Recap

- `$lookup` searches another collection and adds the matches as an array.
- `localField` belongs to the documents entering the pipeline.
- `foreignField` belongs to the collection named by `from`.
- `$unwind` creates one output document per array element.
- An empty `$lookup` result is `[]`.
- `$unwind` drops empty arrays unless `preserveNullAndEmptyArrays` is `true`.
- Keep the array when the matches naturally belong together; unwind it when
  each match needs to be processed separately.

---
← [3.14 Relationships in MongoDB](14-relationships-in-mongodb.md) | Next: [3.16 Aggregation Pipelines →](16-aggregation-pipelines.md)
