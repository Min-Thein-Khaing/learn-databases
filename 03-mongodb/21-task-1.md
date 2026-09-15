← [3.20 Part 2 Conclusion](20-conclusion.md)

# Task 1: Write the Queries — Lessons 3.1–3.11

15 practice tasks covering [3.1 What Is MongoDB?](01-what-is-mongodb.md)
through [3.11 `$lookup` (Joining Collections)](11-lookup-joins.md). Write the
MongoDB shell code yourself first — the answer is hidden in each collapsed
**Show answer** section below it. All tasks use the `apple_store` database
built up across those lessons: the `products` collection (ending at 8
documents after Lesson 3.2's deletes), plus `customers` and `orders` from
Lessons 3.9–3.11. Tasks 11–15 are an extra round, all against the 8-document
`products` collection, combining searching, filtering, sorting, and grouping
in one pipeline each — the way a real report actually looks.

---

### Task 1 — CRUD basics

Using the `products` collection from
[3.2 Your First Database](02-your-first-database-apple-example.md):

1. Insert a new product: `_id: 12`, `'iPhone Air'`, category `'smartphone'`, price `999.00`, stock `450`.
2. Find the `name` and `price` of every product in the `'audio'` category.
3. Raise the price of `_id: 4` to `649.00`, remembering `updated_at`.
4. Delete the product with `_id: 10`.

<details>
<summary>Show answer</summary>

```js
// 1. Insert
db.products.insertOne({
  _id: 12, name: "iPhone Air", category: "smartphone",
  price: 999.00, stock: 450, created_at: new Date(), updated_at: new Date()
});

// 2. Find
db.products.find({ category: "audio" }, { name: 1, price: 1, _id: 0 });

// 3. Update
db.products.updateOne(
  { _id: 4 },
  { $set: { price: 649.00 }, $currentDate: { updated_at: true } }
);

// 4. Delete
db.products.deleteOne({ _id: 10 });
```

`insertOne`=Create, `find`=Read, `updateOne`=Update, `deleteOne`=Delete — the
4 CRUD actions from [3.1 What Is MongoDB?](01-what-is-mongodb.md), all
performed on one collection. Every update needs `$set` (or another update
operator) — MongoDB never lets you just assign a field directly.
</details>

---

### Task 2 — Naming the operation category

For each line below, name which of the 5 categories from
[3.3 Types of MongoDB Operations](03-types-of-mongodb-operations.md) it
belongs to (collection/index management, CRUD write, query/aggregation,
user/role management, or transaction):

1. `db.orders.createIndex({ customer_id: 1 });`
2. `db.products.find({ stock: 0 });`
3. `db.createUser({ user: "analyst", pwd: "...", roles: [{ role: "read", db: "apple_store" }] });`
4. `db.products.insertOne({ name: "Magic Mouse", category: "accessory", price: 79.00 });`

<details>
<summary>Show answer</summary>

1. **Collection & index management** — the MongoDB equivalent of DDL.
2. **Query/read** — `find()` only reads, never changes anything (DQL).
3. **User & role management** — the MongoDB equivalent of DCL.
4. **CRUD write** — `insertOne` changes the data itself (DML).
</details>

---

### Task 3 — Choosing BSON types

Write an `insertOne` for a `customers` collection with: an auto-generated
unique id, a required `name`, a unique required `email` (backed by an
index), an optional `phone`, and a boolean `is_verified` set to `false`.
Use the right BSON approach for each, from
[3.4 Data Types in MongoDB](04-data-types.md).

<details>
<summary>Show answer</summary>

```js
db.customers.insertOne({
  name: "Jordan Lee",
  email: "jordan@mail.com",
  is_verified: false
  // phone intentionally omitted — it's optional
});

db.customers.createIndex({ email: 1 }, { unique: true });
```

`_id` is left out entirely so MongoDB auto-generates a unique `ObjectId` —
the `ObjectId` equivalent of SQL's `SERIAL`; `phone` is simply omitted, not
set to `null`; and since MongoDB has no `DEFAULT` the way SQL does,
`is_verified` must be supplied explicitly by the application, exactly like
`created_at` was in [3.2 Your First Database](02-your-first-database-apple-example.md).
</details>

---

### Task 4 — Filtering with query operators

Against the 8-document `products` collection from
[3.5 Query Operators](05-query-operators.md), write one query for each:

1. Every product priced between `500` and `1000`, inclusive.
2. Every product whose category is `'laptop'` or `'tablet'`.
3. Every product whose name contains `"Pro"`.
4. Every laptop under `1200.00` **or** with stock over `250`.

<details>
<summary>Show answer</summary>

```js
// 1.
db.products.find({ price: { $gte: 500, $lte: 1000 } });

// 2.
db.products.find({ category: { $in: ["laptop", "tablet"] } });

// 3.
db.products.find({ name: { $regex: "Pro" } });

// 4.
db.products.find({
  category: "laptop",
  $or: [{ price: { $lt: 1200 } }, { stock: { $gt: 250 } }]
});
```

Listing multiple fields in one object (like `category` above) is an
**implicit `$and`** — combined here with an explicit `$or` for #4, the same
mixed-operator care SQL's parentheses required.
</details>

---

### Task 5 — Sort, limit, skip

From [3.6 Sort, Limit, Skip](06-sort-limit-skip.md):

1. List every product's `name` and `price`, most expensive first.
2. Return only the 3 cheapest products, breaking ties by `_id` ascending.
3. Return "page 2" of the catalog sorted by price ascending, 3 documents per page.

<details>
<summary>Show answer</summary>

```js
// 1.
db.products.find({}, { name: 1, price: 1, _id: 0 }).sort({ price: -1 });

// 2.
db.products.find({}, { name: 1, price: 1 }).sort({ price: 1, _id: 1 }).limit(3);

// 3.
db.products.find().sort({ price: 1 }).limit(3).skip(3);
```

Page 2 means skipping page 1's 3 documents (`.skip(3)`) before taking the
next 3 (`.limit(3)`).
</details>

---

### Task 6 — Aggregation functions

From [3.7 Aggregation Functions](07-aggregation-functions.md):

1. Count how many products exist in total, and find their average price, rounded to 2 decimal places.
2. Show every product's name in uppercase, alongside its category.
3. Build a single text label per product like `"iPhone 17 Pro (smartphone)"`.

<details>
<summary>Show answer</summary>

```js
// 1.
db.products.aggregate([
  { $group: { _id: null, numProducts: { $sum: 1 }, avgPrice: { $avg: "$price" } } },
  { $project: { _id: 0, numProducts: 1, avgPrice: { $round: ["$avgPrice", 2] } } }
]);

// 2.
db.products.aggregate([
  { $project: { _id: 0, name: { $toUpper: "$name" }, category: 1 } }
]);

// 3.
db.products.aggregate([
  { $project: { _id: 0, label: { $concat: ["$name", " (", "$category", ")"] } } }
]);
```
</details>

---

### Task 7 — The `$group` stage

From [3.8 The `$group` Stage](08-group-stage.md):

1. Show the number of products and total stock, per category.
2. Show only the categories where the average price is above `700`.
3. Explain in one sentence why a `$group` stage's output can never "forget" a field the way a bad SQL `GROUP BY` can.

<details>
<summary>Show answer</summary>

```js
// 1.
db.products.aggregate([
  { $group: { _id: "$category", numProducts: { $sum: 1 }, totalStock: { $sum: "$stock" } } }
]);

// 2.
db.products.aggregate([
  { $group: { _id: "$category", avgPrice: { $avg: "$price" } } },
  { $match: { avgPrice: { $gt: 700 } } }
]);
```

3. A `$group` stage's output documents only ever contain `_id` plus whatever
accumulators you defined — there's no third, unaggregated field that could
sneak through undecided, unlike SQL where a stray `SELECT`ed column not
listed in `GROUP BY` (and not wrapped in an aggregate) causes an error.
</details>

---

### Task 8 — Embed or reference?

Using the decision rule from
[3.9 Embedding vs. Referencing](09-embedding-vs-referencing.md), decide
**embed** or **reference** for each, and justify it with the 3-question rule:

1. An order's line items (`items: [...]`).
2. A product's reviews, where a popular product could have thousands, and reviews are often queried independently (e.g. "show all of Alice's reviews").

<details>
<summary>Show answer</summary>

1. **Embed.** Line items are always fetched together with their order,
bounded (an order never has millions of items), and never reused by any
other order.
2. **Reference** — a separate `reviews` collection. Reviews are **not**
bounded (a popular product could have thousands) and are frequently queried
**independently** of any one product — both answers point away from
embedding, the same conclusion [3.19 Capstone](19-capstone.md) reaches.
</details>

---

### Task 9 — Relationships without enforcement

From [3.10 Relationships in MongoDB](10-relationships-in-mongodb.md):

1. Insert an order referencing `customer_id: 9999`, a customer that doesn't exist, and show that it succeeds.
2. Delete a customer who still has orders referencing them, and show that this succeeds too.
3. Name 2 ways to guard against this, since MongoDB itself won't.

<details>
<summary>Show answer</summary>

```js
// 1.
db.orders.insertOne({
  _id: 99, customer_id: 9999, order_date: new Date(), items: []
});
// Succeeds. No error — MongoDB has no idea customer_id 9999 doesn't exist.

// 2.
db.customers.deleteOne({ _id: 1 });
// Also succeeds, even if orders still reference customer_id: 1.
```

3. **Application-level checks** — look up the customer before inserting the
order, in your own code. **Schema validation** ([3.13](13-schema-validation.md))
— can enforce a field's type and shape, but never that its value exists in
another collection.
</details>

---

### Task 10 — `$lookup` joins

From [3.11 `$lookup`](11-lookup-joins.md):

1. Write a pipeline returning every order's `_id`, the customer's `name`, and the `order_date`.
2. Write a pipeline listing every customer's `name` and total number of orders placed — including customers with **zero** orders, showing `0` instead of nothing.

<details>
<summary>Show answer</summary>

```js
// 1.
db.orders.aggregate([
  { $lookup: { from: "customers", localField: "customer_id", foreignField: "_id", as: "customer" } },
  { $unwind: "$customer" },
  { $project: { _id: 1, "customer.name": 1, order_date: 1 } }
]);

// 2.
db.customers.aggregate([
  { $lookup: { from: "orders", localField: "_id", foreignField: "customer_id", as: "orders" } },
  { $project: { name: 1, numOrders: { $size: "$orders" } } }
]);
```

`$lookup` always keeps every source document (like SQL's `LEFT JOIN`), and
gives a customer with no orders an **empty array** rather than a missing
field — `$size` naturally turns that into `0`.
</details>

---

### Task 11 — Search + filter + sort together

Find every product whose name contains `"iPhone"` (search), priced under
`1200.00` (filter), cheapest first, breaking any tie by `_id` (sort).

<details>
<summary>Show answer</summary>

```js
db.products.find({ name: { $regex: "iPhone" }, price: { $lt: 1200 } })
  .sort({ price: 1, _id: 1 });
```

`$regex` searches the name, the two fields in the filter object form an
implicit `$and`, and the 2-field `.sort()` breaks any tie — exactly the 3
skills from [3.5 Query Operators](05-query-operators.md) and
[3.6 Sort, Limit, Skip](06-sort-limit-skip.md), combined in one query.
</details>

---

### Task 12 — Filter + sort + limit ("top N" report)

Excluding the `'smartphone'` category (filter), return the 3 most expensive
remaining products (sort + limit), showing `name`, `category`, and `price`.

<details>
<summary>Show answer</summary>

```js
db.products.find(
  { category: { $ne: "smartphone" } },
  { name: 1, category: 1, price: 1, _id: 0 }
).sort({ price: -1 }).limit(3);
```

Same logical pipeline as [3.6 Sort, Limit, Skip, Step 4](06-sort-limit-skip.md):
the filter runs first, the sort orders what's left, then `.limit()` takes
just the top slice.
</details>

---

### Task 13 — Filter + group + match ("having")

Among products with `stock` over `300` (filter), show each category's
average price rounded to 2 decimals (group), but only for categories
averaging above `700` (having-equivalent).

<details>
<summary>Show answer</summary>

```js
db.products.aggregate([
  { $match: { stock: { $gt: 300 } } },
  { $group: { _id: "$category", avgPrice: { $avg: "$price" } } },
  { $match: { avgPrice: { $gt: 700 } } },
  { $project: { avgPrice: { $round: ["$avgPrice", 2] } } }
]);
```

Returns `smartphone` (1124.00) and `tablet` (799.00). The first `$match`
removes individual documents before grouping ever happens; the second
`$match` then filters the *groups* by their computed average — MongoDB's
version of the `WHERE` vs. `HAVING` distinction from
[3.8 The `$group` Stage, Step 5](08-group-stage.md).
</details>

---

### Task 14 — Group + sort + limit (a ranked summary)

Show the **top 2 categories** by total inventory value
(`price * stock`, summed per category), highest value first.

<details>
<summary>Show answer</summary>

```js
db.products.aggregate([
  { $group: { _id: "$category", inventoryValue: { $sum: { $multiply: ["$price", "$stock"] } } } },
  { $sort: { inventoryValue: -1 } },
  { $limit: 2 }
]);
```

Returns `smartphone` (1,223,900) and `laptop` (656,550) — grouping happens
first (one document per category), then the group-level totals are sorted
and trimmed, the same way `.sort()`/`.limit()` work identically on grouped
or plain documents.
</details>

---

### Task 15 — Search + filter + group + match + sort, all at once

Among products whose name starts with `"i"` (case-insensitive search) and
are priced above `600` (filter), group by category and show the count and
average price per category (group), keeping only categories with **more
than 1** matching product (having-equivalent), ordered by average price
descending (sort).

<details>
<summary>Show answer</summary>

```js
db.products.aggregate([
  { $match: { name: { $regex: "^i", $options: "i" }, price: { $gt: 600 } } },
  { $group: { _id: "$category", numProducts: { $sum: 1 }, avgPrice: { $avg: "$price" } } },
  { $match: { numProducts: { $gt: 1 } } },
  { $sort: { avgPrice: -1 } }
]);
```

Returns just `smartphone` (2 products — iPhone 17 Pro and iPhone 17,
avgPrice 1124.00): the search + filter stage keeps iPhone 17 Pro, iPhone 17,
and iPad Pro (iPad Air is filtered out at 599.00, not above 600); grouping
puts 2 of those 3 in `smartphone` and 1 in `tablet`; the `numProducts > 1`
match then drops `tablet`. Read it as MongoDB's own execution order, from
[3.5 Query Operators](05-query-operators.md) and
[3.8 The `$group` Stage, Step 5](08-group-stage.md): `$match` (search +
filter) → `$group` → `$match` (having) → `$sort` — every stage from this
lesson block, in one pipeline.
</details>

---
← [3.20 Part 2 Conclusion](20-conclusion.md) | Next: [Task 2 →](22-task-2.md)
