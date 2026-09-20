← [3.17 Schema Validation](17-schema-validation.md)

# 3.18 Transactions

Same 3 scenarios as [Lesson 2.14](../02-sql/17-transactions.md) — a bank
transfer, an airline booking, a shop checkout — all needing several writes
to succeed together, or not at all.

## Step 1 — The good news first: single documents are already atomic

Each individual document write is atomic. The customer contact details in
[3.13](13-embedding-vs-referencing.md), for example, can be updated inside
one `customers` document without a transaction.

Creating an order changes **three separate documents**: insert an `orders`
document, insert its `order_items` document, and reduce `products` stock.
That needs a real transaction.

## Step 2 — Starting a transaction

```js
const session = db.getMongo().startSession();
session.startTransaction();
try {
  // ... operations, each passed { session } ...
  session.commitTransaction();
} catch (e) {
  session.abortTransaction();
}
```

Every operation inside must explicitly pass `{ session }`, or it runs
**outside** the transaction entirely — an easy mistake with no error to warn
you, worth double-checking every time.

## Step 3 — A failed attempt, and what rolls back

```js
session.startTransaction();
try {
  db.orders.insertOne({
    _id: 4,
    customer_id: 3,
    order_date: ISODate("2026-03-10"),
    status: "paid"
  }, { session });

  db.order_items.insertOne(
    { _id: 6, order_id: 4, product_id: 4, quantity: 2, unit_price: 599.00 },
    { session }
  );

  db.products.updateOne(
    { _id: 4 },
    { $inc: { stock: -99999 } },   // way more than in stock
    { session }
  );

  session.commitTransaction();
} catch (e) {
  print("Transaction aborted:", e.message);
  // Document failed validation — stock would go negative,
  // violating Lesson 3.17's "minimum: 0" rule
  session.abortTransaction();
}
```

`abortTransaction()` undoes **all three** operations — including the `orders`
insert that, on its own, would have succeeded. Same all-or-nothing guarantee
as [Lesson 2.14](../02-sql/17-transactions.md)'s `ROLLBACK`.

> Unlike SQL's `SERIAL` ([Lesson 2.14](../02-sql/17-transactions.md)),
> nothing here auto-consumed the value `4` — MongoDB has no sequence
> counting attempts behind the scenes. `_id: 4` is genuinely free to reuse.
> We'll skip to `5` anyway below, purely to keep matching
> [Lesson 2.10](../02-sql/13-relationships-and-foreign-keys.md)'s order
> numbering for easy comparison.

## Step 4 — The corrected, successful transaction

```js
session.startTransaction();
try {
  db.orders.insertOne({
    _id: 5,
    customer_id: 3,   // Carla's first order
    order_date: ISODate("2026-03-10"),
    status: "paid"
  }, { session });

  db.order_items.insertOne(
    { _id: 6, order_id: 5, product_id: 4, quantity: 2, unit_price: 599.00 },
    { session }
  );

  db.products.updateOne(
    { _id: 4 },
    { $inc: { stock: -2 } },   // iPad Air: 400 → 398
    { session }
  );

  session.commitTransaction();
} catch (e) {
  session.abortTransaction();
}
```

Carla finally has her first order — matching
[Lesson 2.14](../02-sql/17-transactions.md)'s SQL result exactly.

## Step 5 — Bob's second order

```js
session.startTransaction();
try {
  db.orders.insertOne({
    _id: 6,
    customer_id: 2,
    order_date: ISODate("2026-03-12"),
    status: "paid"
  }, { session });

  db.order_items.insertOne(
    { _id: 7, order_id: 6, product_id: 3, quantity: 1, unit_price: 1799.10 },
    { session }
  );

  db.products.updateOne({ _id: 3 }, { $inc: { stock: -1 } }, { session });

  session.commitTransaction();
} catch (e) {
  session.abortTransaction();
}
```

## Step 6 — What's missing: no `SAVEPOINT`

[Lesson 2.14](../02-sql/17-transactions.md)'s `SAVEPOINT` let SQL undo
*part* of a transaction while keeping the rest. MongoDB has **no
equivalent** — a transaction is all-or-nothing with no partial rollback
point. If step 3 of a 5-step transaction fails, all 5 steps abort; there's
no way to keep steps 1–2 and only retry step 3.

## Step 7 — A preview: atomic single-document updates

```js
db.products.updateOne(
  { _id: 4, stock: { $gte: 2 } },
  { $inc: { stock: -2 } }
);
```

Same idea as [Lesson 2.14](../02-sql/17-transactions.md)'s
`UPDATE ... WHERE stock >= 2` — and since a single document's update is
*always* atomic in MongoDB, this needs no transaction at all: if two
requests race, only one can actually succeed in reducing stock below the
guard.

## Recap

| SQL ([Lesson 2.14](../02-sql/17-transactions.md)) | MongoDB |
|---|---|
| `BEGIN` | `session.startTransaction()` |
| `COMMIT` | `session.commitTransaction()` |
| `ROLLBACK` | `session.abortTransaction()` |
| `SAVEPOINT` | **No equivalent** — all-or-nothing only |
| Multi-statement atomicity | Needed for multi-*document* writes; a single document is already atomic |

---
← [3.17 Schema Validation](17-schema-validation.md) | Next: [3.19 Indexes & Performance →](19-indexes-and-performance.md)
