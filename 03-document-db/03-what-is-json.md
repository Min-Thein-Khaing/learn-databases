← [3.2 Document Database Brands](02-document-database-brands.md)

# 3.3 What Is JSON?

**JSON** stands for **JavaScript Object Notation**. It is a text format for
representing structured data. People can read it, and applications can send
and receive it easily.

```json
{
  "name": "MacBook Air",
  "price": 1099,
  "inStock": true
}
```

## JSON building blocks

An object is wrapped in `{}` and contains **key-value pairs**. JSON supports
six value types:

| Type | Example |
|---|---|
| String | `"MacBook Air"` |
| Number | `1099` |
| Boolean | `true` |
| Null | `null` |
| Array | `["silver", "midnight"]` |
| Object | `{ "memoryGB": 16 }` |

## Nested objects and arrays

```json
{
  "name": "MacBook Air",
  "colors": ["silver", "midnight"],
  "specs": {
    "memoryGB": 16,
    "storageGB": 512
  }
}
```

`colors` is an array. `specs` is a nested object.

## JSON syntax rules

- Keys and string values use double quotes.
- A colon separates a key from its value.
- A comma separates each key-value pair.
- The final key-value pair has no trailing comma.
- JSON does not allow comments.

This is invalid JSON because it uses single quotes and has a trailing comma:

```text
{ 'name': 'MacBook Air', }
```

## JSON and MongoDB

MongoDB documents look like JSON, but MongoDB stores them as **BSON**
(Binary JSON). BSON adds useful data types such as dates, object IDs, and
decimal numbers.

## Recap

- JSON is a text format for structured data.
- JSON uses objects, arrays, and simple values.
- Valid JSON follows strict punctuation and quoting rules.
- MongoDB uses BSON, a JSON-like binary format with extra data types.

---
← [3.2 Document Database Brands](02-document-database-brands.md) | Next: [3.4 What Is MongoDB? →](04-what-is-mongodb.md)
