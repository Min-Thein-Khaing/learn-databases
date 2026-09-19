← [3.22 Capstone](22-capstone.md)

# 3.23 Document Databases Conclusion

Module 3 is done. You started with the document model, explored major
document database brands and BSON, and then built a complete MongoDB system.

## What you've learned

| Lesson | Big idea |
|---|---|
| [3.1 What Is a Document Database?](01-what-is-a-document-database.md) | Documents, collections, nested data, and flexible structure |
| [3.2 Document Database Brands](02-document-database-brands.md) | MongoDB, Amazon DocumentDB, DynamoDB, Cosmos DB, Firestore, Couchbase, and CouchDB |
| [3.3 What Is BSON?](03-what-is-bson.md) | MongoDB documents, embedded values, and BSON data types |
| [3.4 What Is MongoDB?](04-what-is-mongodb.md) | Documents in collections, not rows in tables — no separate query language layer |
| [3.5 Your First Database](05-your-first-database-apple-example.md) | `insertOne`/`insertMany`/`find`/`updateOne`/`deleteOne` — same data as Part 1's end-state |
| [3.6 Types of MongoDB Operations](06-types-of-mongodb-operations.md) | The same 5 SQL categories, mapped to MongoDB's own tools |
| [3.7 Data Types (BSON)](07-data-types.md) | `Decimal128` vs. `Double`, `ObjectId`, native nesting |
| [3.8 Query Operators](08-query-operators.md) | `$gt`, `$in`, `$regex`, `$exists`, `$and`/`$or` |
| [3.9 Sort, Limit, Skip](09-sort-limit-skip.md) | `.sort()`, `.limit()`, `.skip()` |
| [3.10 Aggregation Functions](10-aggregation-functions.md) | `$sum`/`$avg`/`$round`/`$toUpper`/`$ifNull`, inside a pipeline |
| [3.11 The `$group` Stage](11-group-stage.md) | Per-category summaries, `$match` before *and* after |
| [3.12 Embedding vs. Referencing](12-embedding-vs-referencing.md) | The central MongoDB design decision — and how it avoids (or reintroduces) SQL's anomalies |
| [3.13 Relationships in MongoDB](13-relationships-in-mongodb.md) | References, with **no enforcement** — a genuine, honest tradeoff |
| [3.14 `$lookup`](14-lookup-joins.md) | Joining collections — and the real cost of aggregating across embedded arrays |
| [3.15 Aggregation Pipelines](15-aggregation-pipelines.md) | `$facet`, `$graphLookup` — MongoDB's CTEs and recursive queries |
| [3.16 Schema Validation](16-schema-validation.md) | `$jsonSchema`, unique indexes — and what has no equivalent (`DEFAULT`, foreign keys) |
| [3.17 Transactions](17-transactions.md) | Single documents are atomic for free; multi-document needs a session — with no `SAVEPOINT` |
| [3.18 Indexes & Performance](18-indexes-and-performance.md) | The exact same B-Tree structure as PostgreSQL |
| [3.19 Views](19-views.md) | Saved pipelines, always read-only |
| [3.20 Create Collections: More Examples](20-create-collections-examples.md) | Capped collections and TTL indexes — genuinely MongoDB-only tools |
| [3.21 User & Access Management](21-user-access-management.md) | Roles and custom privileges, mirroring `GRANT`/`REVOKE` |
| [3.22 Capstone](22-capstone.md) | The identical feature, built with MongoDB's tools — same final answer, different path |

## The one idea to carry forward

Every SQL guarantee from Part 1 — enforced relationships, `DEFAULT` values,
partial rollback via `SAVEPOINT` — had to be **deliberately rebuilt, weakened,
or explicitly given up** somewhere in Part 2. That's not a flaw in MongoDB;
it's the actual trade being made: less enforced structure, in exchange for
flexibility and documents that map naturally onto how an application already
thinks about its data. Neither database is "better" in the abstract — they
made different bets, on purpose.

## Readiness checklist

- [ ] I can decide whether to embed or reference a given relationship, and explain why
- [ ] I can write a multi-stage aggregation pipeline with `$match`, `$group`, and `$lookup`
- [ ] I know exactly which SQL guarantees MongoDB does *not* enforce automatically
- [ ] I can start, commit, and abort a multi-document transaction
- [ ] I can create a role with only the collections/actions it actually needs

## What's next

[**Chapter 4**](../04-comparison/) puts both parts side by side directly —
the same data, the same queries, a structured pros-and-cons comparison, and
a practical framework for choosing between them on a real project.

---
← [3.22 Capstone](22-capstone.md) | Next: [Chapter 4 — Comparison →](../04-comparison/01-same-data-two-ways.md)
