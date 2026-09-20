← [3.8 Data Types in MongoDB](08-data-types.md)

# 3.9 Query Operators

Same job as [Lesson 2.5](../02-sql/05-operators.md)'s SQL operators —
narrowing down a collection to just the documents that matter — using the
exact same product data.

## Where our data stands

| _id | name | category | price | stock |
|---|---|---|---|---|
| 1 | iPhone 17 Pro | smartphone | 1249.00 | 500 |
| 2 | MacBook Air | laptop | 989.10 | 300 |
| 3 | MacBook Pro | laptop | 1799.10 | 200 |
| 4 | iPad Air | tablet | 599.00 | 400 |
| 5 | iPad Pro | tablet | 999.00 | 350 |
| 7 | AirPods Max | audio | 549.00 | 250 |
| 10 | Mac Mini | desktop | 599.00 | 450 |
| 11 | iPhone 17 | smartphone | 999.00 | 600 |

## Step 1 — Comparison operators

```js
db.products.find({ category: "tablet" });
```
Returns iPad Air, iPad Pro — plain equality needs no special operator, just
`{ field: value }`.

```js
db.products.find({ price: { $gt: 1000 } });
```
Returns iPhone 17 Pro (1249.00), MacBook Pro (1799.10).

```js
db.products.find({ category: { $ne: "smartphone" } });
```
Every product **except** the 2 smartphones — `$ne` is SQL's `<>`.

| Operator | Meaning | SQL equivalent ([Lesson 2.5](../02-sql/05-operators.md)) |
|---|---|---|
| `$eq` | equal to (usually just omitted) | `=` |
| `$ne` | not equal to | `<>` |
| `$lt` / `$lte` | less than / or equal | `<` / `<=` |
| `$gt` / `$gte` | greater than / or equal | `>` / `>=` |

## Step 2 — Range: two conditions on one field

```js
db.products.find({ price: { $gte: 500, $lte: 1000 } });
```
Returns MacBook Air, iPad Air, iPad Pro, AirPods Max, Mac Mini, iPhone 17 —
the direct equivalent of SQL's `BETWEEN 500 AND 1000`.

## Step 3 — `$in`: match any value in a list

```js
db.products.find({ category: { $in: ["laptop", "tablet"] } });
```
Returns MacBook Air, MacBook Pro, iPad Air, iPad Pro — same result as
[Lesson 2.5](../02-sql/05-operators.md)'s `WHERE category IN ('laptop','tablet')`.

## Step 4 — `$regex`: pattern matching on text

A **regular expression**, often shortened to **regex**, is a pattern used to
search text. MongoDB's `$regex` operator checks whether a string field
matches that pattern.

MongoDB accepts two common forms:

```js
db.products.find({ name: /Pro/ })
db.products.find({ name: { $regex: "Pro" } })
```

Both find names containing `Pro`. The first uses a JavaScript regular
expression literal. The second uses the explicit MongoDB `$regex` operator.

### Basic regular-expression symbols

| Pattern | Meaning | Example match |
|---|---|---|
| `Pod` | Contains `Pod` anywhere | `AirPods` |
| `^Pod` | Starts with `Pod` | `Pods Max` |
| `Pod$` | Ends with `Pod` | `HomePod` |
| `.` | Any one character | `Pod`, `Rod` for `.od` |
| `.*` | Any number of characters | `AirPods Pro` for `Air.*Pro` |
| `[abc]` | One character from the set | `Pad` for `P[ao]d` |
| `[0-9]` | One digit | `iPhone 17` |
| `+` | One or more of the previous item | `100` for `[0-9]+` |
| `?` | Zero or one of the previous item | `color`, `colour` for `colou?r` |
| `\` | Escape a special character | `\.` matches a literal period |

### SQL `LIKE` to MongoDB regex

SQL's `%` means any number of characters. Regex uses `.*` for the same
idea, although `.*` can often be omitted when matching anywhere. SQL's `_`
means one character; regex uses `.`.

| SQL | MongoDB |
|---|---|
| `WHERE name LIKE '%pod%'` | `{ name: /pod/ }` or `{ name: { $regex: "pod" } }` |
| `WHERE name LIKE 'Pod%'` | `{ name: /^Pod/ }` |
| `WHERE name LIKE '%Pod'` | `{ name: /Pod$/ }` |
| `WHERE name LIKE '_od%'` | `{ name: /^.od/ }` |
| `WHERE name LIKE '%pod%'` case-insensitive | `{ name: { $regex: "pod", $options: "i" } }` |

### Start-of-text example

```js
db.products.find({ name: { $regex: "^iPhone" } });
```
Returns iPhone 17 Pro, iPhone 17 — `^` anchors to the start of the string,
the regex equivalent of SQL's `LIKE 'iPhone%'`.

### Contains-text example

```js
db.products.find({ name: { $regex: "Pro" } });
```
Returns iPhone 17 Pro, MacBook Pro, iPad Pro — matches "Pro" anywhere in the
name, like SQL's `LIKE '%Pro%'`.

### Case-insensitive matching

Regular expressions are case-sensitive by default:

```js
db.products.find({ name: { $regex: "iphone" } });
// Does not match "iPhone" because I and i are different.
```

Add the `i` option to ignore letter case:

```js
db.products.find({ name: { $regex: "iphone", $options: "i" } });
```

The literal form can place the option after the closing slash:

```js
db.products.find({ name: /iphone/i });
```

Common options are:

| Option | Meaning |
|---|---|
| `i` | Case-insensitive matching |
| `m` | `^` and `$` work at the start and end of each line |
| `s` | `.` can also match newline characters |
| `x` | Ignore unescaped whitespace and allow comments in the pattern |

### Escaping user input

Characters such as `.`, `*`, `+`, `?`, `(`, `)`, `[`, `]`, `{`, `}`, `^`,
`$`, `|`, and `\` have special meanings. Escape them when they should be
treated as ordinary text. Applications should never place untrusted user
input directly into a regex without escaping or validating it.

### Index note

A case-sensitive prefix pattern such as `/^Pod/` can make useful use of a
normal index on `name`. A pattern that begins with unrestricted text, such
as `/pod/` or `/.*pod/`, usually requires much more scanning.

## Step 5 — `$exists`: checking for a missing field

Every document here has every field, so there's nothing to demonstrate on
`products` — same situation as [Lesson 2.5](../02-sql/05-operators.md).
Imagine a `customers` collection where `phone` isn't always provided:

```js
db.customers.find({ phone: { $exists: false } });
```

This is MongoDB's version of SQL's `IS NULL` — but note the distinction:
`$exists: false` means the *field itself is missing*; a field explicitly set
to `null` is a different case (`{ phone: null }` matches `$eq: null`, not
`$exists: false`) — worth remembering, since the two are easy to conflate.

## Step 6 — Combining conditions: `$and`, `$or`, `$not`

```js
db.products.find({ category: "laptop", price: { $lt: 1000 } });
```
Returns just MacBook Air (989.10) — listing multiple fields in one object is
an **implicit `$and`**, MongoDB's default when you don't write `$and`
explicitly.

```js
db.products.find({ $or: [{ category: "tablet" }, { category: "audio" }] });
```
Returns iPad Air, iPad Pro, AirPods Max.

```js
db.products.find({ category: { $not: { $eq: "smartphone" } } });
```
Same result as Step 1's `$ne` example.

## Recap

| SQL ([Lesson 2.5](../02-sql/05-operators.md)) | MongoDB |
|---|---|
| `WHERE price > 1000` | `find({ price: { $gt: 1000 } })` |
| `BETWEEN 500 AND 1000` | `find({ price: { $gte: 500, $lte: 1000 } })` |
| `IN ('laptop','tablet')` | `find({ category: { $in: [...] } })` |
| `LIKE 'iPhone%'` | `find({ name: { $regex: "^iPhone" } })` |
| `IS NULL` | `find({ field: { $exists: false } })` |
| `AND` | Multiple fields in one object (implicit), or `$and` |
| `OR` | `$or: [...]` |
| `NOT` | `$not`, or a negating operator like `$ne` |

---
← [3.8 Data Types in MongoDB](08-data-types.md) | Next: [3.10 Sort, Limit, Skip →](10-sort-limit-skip.md)
