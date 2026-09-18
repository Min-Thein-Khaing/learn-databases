← [Task 1](24-task-1.md)

# Task 2: Write the Queries — Lessons 3.15–3.23

2 practice tasks for each remaining Part 2 lesson — from
[3.15 Aggregation Pipelines](15-aggregation-pipelines.md) through
[3.22 Capstone](22-capstone.md), plus a closing pair tied to
[3.23 Part 2 Conclusion](23-conclusion.md) — 18 tasks total. Write the
MongoDB shell code yourself first; each answer is hidden in a collapsed
**Show answer** section. Tasks build on the `customers` / `orders` /
`products` / `reviews` collections from these lessons.

---

## 3.15 Aggregation Pipelines

**Task 1.** SQL can answer "find every product priced above the overall
average" with a single self-contained subquery. Write the two-step MongoDB
equivalent — one aggregation to compute the average price, and one `find()`
using that value — and explain why MongoDB usually needs two steps here.

<details>
<summary>Show answer</summary>

```js
// Step 1: compute the average
const avgResult = db.products.aggregate([
  { $group: { _id: null, avgPrice: { $avg: "$price" } } }
]).toArray();
const avgPrice = avgResult[0].avgPrice;

// Step 2: use it in a plain query
db.products.find({ price: { $gt: avgPrice } });
```

Unlike SQL, a plain `find()` has no way to reference "the result of a
previous aggregation" inline — the two steps run separately in your
application code, or you reach for `$facet` (as in
[3.22 Capstone, Step 7](22-capstone.md)) to do it in a single round trip.
</details>

**Task 2.** Write a pipeline that computes total inventory value
(`price * stock`) per category, keeping only categories whose total exceeds
`500000` — as two named pipeline stages, the way
[3.15, Step 1](15-aggregation-pipelines.md) showed a `$group` followed by a
`$match` acts exactly like a CTE followed by a `WHERE` filter.

<details>
<summary>Show answer</summary>

```js
db.products.aggregate([
  { $group: { _id: "$category", inventoryValue: { $sum: { $multiply: ["$price", "$stock"] } } } },
  { $match: { inventoryValue: { $gt: 500000 } } }
]);
```

Returns `smartphone` (1,223,900), `laptop` (656,550), and `tablet`
(589,250) — `desktop` (269,550) and `audio` (137,250) are filtered out.
</details>

---

## 3.16 Schema Validation

**Task 3.** Add `$jsonSchema` rules to an existing `products` collection so
`price` must always be strictly greater than `0`, and `stock` can never go
negative.

<details>
<summary>Show answer</summary>

```js
db.runCommand({
  collMod: "products",
  validator: {
    $jsonSchema: {
      bsonType: "object",
      properties: {
        price: { bsonType: ["double", "decimal"], minimum: 0, exclusiveMinimum: true },
        stock: { bsonType: "int", minimum: 0 }
      }
    }
  },
  validationLevel: "moderate"
});
```

`exclusiveMinimum: true` makes `price`'s `minimum: 0` a strict `> 0`;
`stock`'s plain `minimum: 0` allows exactly `0`.
</details>

**Task 4.** Write a compound unique index on a `reviews` collection so the
same customer can never leave more than one review for the same product —
and explain in one sentence why a single-field unique index on
`customer_id` alone wouldn't work.

<details>
<summary>Show answer</summary>

```js
db.reviews.createIndex({ customer_id: 1, product_id: 1 }, { unique: true });
```

A single-field unique index on `customer_id` alone would allow only **one
review total** per customer, across every product — the compound index
makes the *pair* unique instead, the direct equivalent of SQL's composite
`PRIMARY KEY (order_id, product_id)`.
</details>

---

## 3.17 Transactions

**Task 5.** Write a transaction that inserts a new order for
`customer_id = 3`, with one item for `product_id = 4` and `quantity = 2`,
and reduces that product's stock by 2 — committing only if every step
succeeds.

<details>
<summary>Show answer</summary>

```js
const session = db.getMongo().startSession();
session.startTransaction();
try {
  db.orders.insertOne(
    { _id: 7, customer_id: 3, order_date: new Date(),
      items: [{ product_id: 4, quantity: 2, unit_price: 599.00 }] },
    { session }
  );
  db.products.updateOne({ _id: 4 }, { $inc: { stock: -2 } }, { session });
  session.commitTransaction();
} catch (e) {
  session.abortTransaction();
}
```
</details>

**Task 6.** A 5-step MongoDB transaction's 4th step fails. What happens to
steps 1–3? Then explain what you'd have to do differently than SQL if you
wanted to keep an order insert but discard just one mistaken item insert
from the same transaction.

<details>
<summary>Show answer</summary>

All 5 steps abort — MongoDB transactions are all-or-nothing, with **no
`SAVEPOINT`** equivalent ([3.17, Step 6](17-transactions.md)). To "keep the
order but discard the item," you'd have to abort the whole transaction and
restart it from scratch without the mistaken item — there's no partial
rollback point to return to mid-transaction, unlike SQL.
</details>

---

## 3.18 Indexes & Performance

**Task 7.** `orders.customer_id` is referenced constantly via `$lookup`.
Write the statement to index it, and explain why MongoDB doesn't index it
automatically.

<details>
<summary>Show answer</summary>

```js
db.orders.createIndex({ customer_id: 1 });
```

Only `_id` is automatically indexed on every collection — same as SQL's
`PRIMARY KEY`. Reference fields like `customer_id` (even nested ones like
`items.product_id`) need a manual `createIndex()` call, the same gap as SQL
not auto-indexing foreign key columns.
</details>

**Task 8.** You create `db.products.createIndex({ category: 1, price: 1 })`.
Which of these two queries can use it efficiently, and which can't?

```js
// A
db.products.find({ category: "laptop", price: { $gt: 1000 } });
// B
db.products.find({ price: { $gt: 1000 } });
```

<details>
<summary>Show answer</summary>

Query **A** can use it efficiently — it filters on `category` (the leftmost
field) first, then `price`. Query **B** can't — the index is sorted by
`category` first, so without a `category` filter MongoDB can't jump
straight to a price range using this index. Identical rule to SQL's
composite index in [2.18](../02-sql/18-indexes-and-performance.md).
</details>

---

## 3.19 Views

**Task 9.** Save the category → inventory-value aggregation from Task 2 as
a view named `category_inventory_value`, without the filtering stage this
time (so every category shows up).

<details>
<summary>Show answer</summary>

```js
db.createView("category_inventory_value", "products", [
  { $group: { _id: "$category", inventoryValue: { $sum: { $multiply: ["$price", "$stock"] } } } }
]);
```
</details>

**Task 10.** Turn that same aggregation into a materialized snapshot named
`category_inventory_value_cached` instead of a live view, and explain the
one way a MongoDB view can never be used, unlike a simple SQL view.

<details>
<summary>Show answer</summary>

```js
db.products.aggregate([
  { $group: { _id: "$category", inventoryValue: { $sum: { $multiply: ["$price", "$stock"] } } } },
  { $merge: { into: "category_inventory_value_cached" } }
]);
```

Unlike SQL, where a simple, single-table view can sometimes be updated
directly ([2.19 Views](../02-sql/19-views.md)), a MongoDB view is **always**
read-only, no exceptions — you can never `updateOne`/`insertOne` into
`category_inventory_value` directly, only into the real underlying
collection.
</details>

---

## 3.20 Create Collections: More Examples

**Task 11.** Using the capped-collection and TTL-index tools from
[3.20](20-create-collections-examples.md) — both things SQL has no
equivalent for — write the statements to: 1) create a capped collection
named `error_log` holding at most 500 documents within 5MB, and 2) make
documents in a `page_views` collection expire automatically 24 hours after
their `created_at` field.

<details>
<summary>Show answer</summary>

```js
// 1.
db.createCollection("error_log", { capped: true, size: 5242880, max: 500 });

// 2.
db.page_views.createIndex({ created_at: 1 }, { expireAfterSeconds: 86400 });
```
</details>

**Task 12.** Write the schema-validated `createCollection` call for a
`tasks` collection requiring `title` and `priority`, where `priority` is
restricted to `'low'`/`'medium'`/`'high'` — then insert one valid task, and
explain what happens if you try to insert one with `priority: "urgent"`.

<details>
<summary>Show answer</summary>

```js
db.createCollection("tasks", {
  validator: {
    $jsonSchema: {
      required: ["title", "priority"],
      properties: { priority: { enum: ["low", "medium", "high"] } }
    }
  }
});

db.tasks.insertOne({ title: "Ship the release", priority: "high" });

db.tasks.insertOne({ title: "Bad task", priority: "urgent" });
// Document failed validation — "urgent" isn't one of the enum's allowed values
```
</details>

---

## 3.21 User & Access Management

**Task 13.** Create a custom role named `reviewModerator` granting `find`
and `update` (but not `insert`/`remove`) on just the `reviews` collection in
`apple_store`, then create a user named `mod_bot` with that role.

<details>
<summary>Show answer</summary>

```js
db.createRole({
  role: "reviewModerator",
  privileges: [
    { resource: { db: "apple_store", collection: "reviews" }, actions: ["find", "update"] }
  ],
  roles: []
});

db.createUser({
  user: "mod_bot",
  pwd: "change_me_789",
  roles: ["reviewModerator"]
});
```
</details>

**Task 14.** A user currently has the `readOnly` role. Write the commands
to grant it `readWrite` scoped to just `apple_store`, then remove the
original `readOnly` role, and finally change that user's password.

<details>
<summary>Show answer</summary>

```js
db.grantRolesToUser("app_user", [{ role: "readWrite", db: "apple_store" }]);
db.revokeRolesFromUser("app_user", ["readOnly"]);
db.updateUser("app_user", { pwd: "a_much_better_password_789" });
```
</details>

---

## 3.22 Capstone

**Task 15.** Create the `reviews` collection with schema validation
requiring `customer_id`, `product_id`, and `rating` (1–5), plus a unique
index guaranteeing one review per customer per product. Then write the
`$lookup` + `$project` aggregation returning each product's `name`, review
count, and average rating.

<details>
<summary>Show answer</summary>

```js
db.createCollection("reviews", {
  validator: {
    $jsonSchema: {
      required: ["customer_id", "product_id", "rating"],
      properties: {
        rating:  { bsonType: "int", minimum: 1, maximum: 5 },
        comment: { bsonType: "string" }
      }
    }
  }
});

db.reviews.createIndex({ customer_id: 1, product_id: 1 }, { unique: true });

db.products.aggregate([
  { $lookup: { from: "reviews", localField: "_id", foreignField: "product_id", as: "productReviews" } },
  { $project: {
      name: 1,
      num_reviews: { $size: "$productReviews" },
      avg_rating: { $avg: "$productReviews.rating" }
  }},
  { $sort: { avg_rating: -1 } }
]);
```
</details>

**Task 16.** Write a pipeline finding every product whose average rating is
above the overall average rating across all reviewed products — using
`$facet` the way [3.22, Step 7](22-capstone.md) combined a per-product list
with an overall average in one round trip.

<details>
<summary>Show answer</summary>

```js
db.products.aggregate([
  { $lookup: { from: "reviews", localField: "_id", foreignField: "product_id", as: "productReviews" } },
  { $addFields: { avgRating: { $avg: "$productReviews.rating" } } },
  { $facet: {
      products: [{ $match: { avgRating: { $ne: null } } }],
      overallAvg: [
        { $match: { avgRating: { $ne: null } } },
        { $group: { _id: null, avg: { $avg: "$avgRating" } } }
      ]
  }},
  { $project: {
      result: { $filter: {
          input: "$products", as: "p",
          cond: { $gt: ["$$p.avgRating", { $arrayElemAt: ["$overallAvg.avg", 0] }] }
      }}
  }}
]);
```

Using [3.22](22-capstone.md)'s review data (iPhone 17 Pro 5.00, MacBook Air
5.00, AirPods Max 4.00, iPad Air 3.00 — overall average 4.25): the result
is **iPhone 17 Pro** and **MacBook Air**, the only two above 4.25.
</details>

---

## 3.23 Part 2 Conclusion

**Task 17.** Using everything from Part 2, write one aggregation finding
every customer who has spent more than the *average* amount spent across
all customers — combining `$lookup`, the array-flattening pattern from
[3.14's bonus step](14-lookup-joins.md), and `$facet`.

<details>
<summary>Show answer</summary>

```js
db.customers.aggregate([
  { $lookup: { from: "orders", localField: "_id", foreignField: "customer_id", as: "orders" } },
  { $addFields: {
      total_spent: { $sum: { $map: {
          input: { $reduce: { input: "$orders.items", initialValue: [], in: { $concatArrays: ["$$value", "$$this"] } } },
          as: "item",
          in: { $multiply: ["$$item.quantity", "$$item.unit_price"] }
      }}}
  }},
  { $facet: {
      customers: [{ $match: {} }],
      overallAvg: [{ $group: { _id: null, avg: { $avg: "$total_spent" } } }]
  }},
  { $project: {
      result: { $filter: {
          input: "$customers", as: "c",
          cond: { $gt: ["$$c.total_spent", { $arrayElemAt: ["$overallAvg.avg", 0] }] }
      }}
  }}
]);
```

Using [3.19 Views](19-views.md)'s totals (Alice 3396.00, Bob 2788.20, Carla
1198.00 — overall average 2460.73): **Alice Chen** and **Bob Diaz** both
spent above average; only Carla falls below it.
</details>

**Task 18.** Design a role named `support_agent`, following least
privilege, that can read every collection but only update the `reviews`
collection (e.g. to moderate comments) — nothing else.

<details>
<summary>Show answer</summary>

```js
db.createRole({
  role: "support_agent",
  privileges: [
    { resource: { db: "apple_store", collection: "" }, actions: ["find"] },
    { resource: { db: "apple_store", collection: "reviews" }, actions: ["update"] }
  ],
  roles: []
});

db.createUser({
  user: "support_agent_bot",
  pwd: "change_me_456",
  roles: ["support_agent"]
});
```

`collection: ""` means "every collection" — `support_agent` can read
everything, but can only write to `reviews`: no `insert`/`remove` anywhere,
and no `update` on any other collection.
</details>

---
← [Task 1](24-task-1.md) | Next: [Chapter 4 — Comparison →](../04-comparison/01-same-data-two-ways.md)
