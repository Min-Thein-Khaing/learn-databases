← [3.2 Document Database Brands](02-document-database-brands.md)

# 3.3 What Is BSON?

**BSON** stands for **Binary JSON**. It is the data format MongoDB uses to
store documents and exchange them with MongoDB drivers.

A MongoDB document might look like this in the shell:

```js
{
  name: "MacBook Air",
  price: NumberDecimal("1099.00"),
  inStock: true,
  createdAt: ISODate("2026-09-19T00:00:00Z")
}
```

It looks similar to JSON, but it is BSON. Values such as `NumberDecimal`
and `ISODate` are not available in standard JSON.

## BSON building blocks

A BSON document contains field-value pairs. A value can be simple, an
array, or another document.

```js
{
  name: "MacBook Air",
  colors: ["silver", "midnight"],
  specs: {
    memoryGB: 16,
    storageGB: 512
  }
}
```

`colors` is an array. `specs` is an embedded document.

## Common BSON types

| Type | Example | Use |
|---|---|---|
| String | `"MacBook Air"` | Text |
| Boolean | `true` | True or false values |
| Null | `null` | An empty or unknown value |
| Array | `["silver", "midnight"]` | A list of values |
| Document | `{ memoryGB: 16 }` | Nested structured data |
| Int32 / Int64 | `NumberInt(16)` / `NumberLong(5000)` | Whole numbers |
| Double | `1099.5` | Floating-point numbers |
| Decimal128 | `NumberDecimal("1099.00")` | Exact decimal values |
| Date | `ISODate("2026-09-19T00:00:00Z")` | Dates and times |
| ObjectId | `ObjectId("66ecb2e85d39f123456789ab")` | Unique document identifiers |

## BSON and JSON are not the same

**JSON** is a text format with a small set of value types. **BSON** is a
binary format with additional types needed by databases and applications.

MongoDB tools display BSON in a readable, JavaScript-like form called
**Extended JSON** or MongoDB shell syntax. The displayed document is not
the raw binary data stored by MongoDB.

## Why MongoDB uses BSON

BSON lets MongoDB preserve important type information. A date stays a date,
an object ID stays an object ID, and an exact decimal stays an exact decimal
instead of becoming ordinary text or a generic number.

## Recap

- MongoDB stores documents as BSON.
- BSON uses field-value pairs, arrays, and embedded documents.
- BSON supports more data types than standard JSON.
- MongoDB tools show BSON in a readable JSON-like form.

---
← [3.2 Document Database Brands](02-document-database-brands.md) | Next: [3.4 What Is MongoDB? →](04-what-is-mongodb.md)
