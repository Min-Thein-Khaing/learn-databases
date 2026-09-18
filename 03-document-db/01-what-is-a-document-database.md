← [2.21 Part 1 Conclusion](../02-sql/21-conclusion.md)

# 3.1 What Is a Document Database?

A **document database** stores information as documents. Each document is
one complete object, such as a product, customer, article, or order.

```json
{
  "name": "iPhone 17 Pro",
  "price": 1249,
  "inStock": true,
  "colors": ["black", "silver"],
  "specs": {
    "storageGB": 256,
    "has5G": true
  }
}
```

Documents are grouped into **collections**. A store might have collections
named `products`, `customers`, and `orders`.

```text
store
├── products
│   ├── iPhone document
│   ├── MacBook document
│   └── AirPods document
├── customers
└── orders
```

## Why documents are useful

A document can contain:

- simple values such as a name or price
- lists such as colors or tags
- nested objects such as product specifications
- fields that are not present in every other document

This makes document databases useful when data naturally looks like an
object and its shape may change over time. Common examples include product
catalogs, content systems, user profiles, mobile apps, and event data.

## The main idea

Keep information that belongs together in one document when it is normally
read and updated together. A good document should represent something the
application understands as one object.

## Recap

- A document database stores data as documents.
- Documents contain fields, values, lists, and nested objects.
- Related documents live in collections.
- Document structure can be flexible.

---
← [2.21 Part 1 Conclusion](../02-sql/21-conclusion.md) | Next: [3.2 Document Database Brands →](02-document-database-brands.md)
