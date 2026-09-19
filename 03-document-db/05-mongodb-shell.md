← [3.4 What Is MongoDB?](04-what-is-mongodb.md)

# 3.5 MongoDB Shell (`mongosh`)

**MongoDB Shell**, called **`mongosh`**, is a command-line program for
connecting to MongoDB, inspecting data, and running database commands.

The MongoDB server and `mongosh` are different programs:

```text
mongosh  ──connects to──>  MongoDB server  ──stores──>  databases
```

## Connect to local MongoDB

If MongoDB is running locally on its default port, open a terminal and run:

```bash
mongosh
```

The default connection address is:

```text
mongodb://localhost:27017
```

You can provide it explicitly:

```bash
mongosh "mongodb://localhost:27017"
```

When the connection succeeds, `mongosh` displays a prompt where you can
enter MongoDB commands.

## Connect directly to a database

Add the database name to the connection string:

```bash
mongosh "mongodb://localhost:27017/apple_store"
```

For MongoDB Atlas, copy the connection string from Atlas and pass it to
`mongosh`. Avoid placing a real password in notes, source code, or terminal
history.

## Database and collection command reference

Run these inside `mongosh`:

```js
// DATABASES
db                         // show the current database
show dbs                   // list visible databases
show databases             // same as show dbs
use apple_store            // select a database
db.getName()               // return the current database name
db.stats()                 // show statistics for the current database

// COLLECTIONS
show collections           // list collections in the current database
show tables                // same as show collections
db.getCollectionNames()    // return collection names as an array
db.createCollection("products")
db.products.renameCollection("store_products")
db.store_products.drop()   // delete one collection and its documents

// HELP
help                       // show general shell help
db.help()                  // show database methods
db.products.help()         // show collection methods
```

`use apple_store` changes the current database context. It does not save a
new database to disk until the database contains data or an explicitly
created collection.

## Create a database

MongoDB has no separate `create database` command. Select a new database
name, then create a collection or insert a document:

```js
use apple_store
db.createCollection("products")
```

You can also create the database and collection with the first insert:

```js
use apple_store
db.products.insertOne({ name: "MacBook Air" })
```

Confirm that the database now exists:

```js
show dbs
```

## Create a normal collection

```js
db.createCollection("customers")
```

MongoDB can also create a collection automatically when you first insert a
document:

```js
db.orders.insertOne({ customer_id: 101, status: "new" })
```

## Create a collection with schema validation

The following collection requires `name`, `price`, and `stock`:

```js
db.createCollection("validated_products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "price", "stock"],
      properties: {
        name: {
          bsonType: "string",
          description: "must be text and is required"
        },
        price: {
          bsonType: ["double", "decimal", "int", "long"],
          minimum: 0,
          description: "must be a non-negative number and is required"
        },
        stock: {
          bsonType: "int",
          minimum: 0,
          description: "must be a non-negative integer and is required"
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
})
```

This insert succeeds:

```js
db.validated_products.insertOne({
  name: "MacBook Air",
  price: NumberDecimal("1099.00"),
  stock: NumberInt(20)
})
```

This one fails because `price` is text and `stock` is missing:

```js
db.validated_products.insertOne({
  name: "MacBook Air",
  price: "1099.00"
})
```

Despite the name `$jsonSchema`, MongoDB validates **BSON documents and BSON
types**. A later lesson explains schema validation in more depth.

## Show collections

```js
show collections
```

For a value that can be stored in a variable or processed in code, use:

```js
db.getCollectionNames()
// ["customers", "orders", "products", "validated_products"]
```

## Drop a collection

```js
db.validated_products.drop()
```

The method returns `true` when the collection is successfully deleted. This
also permanently deletes every document and index in that collection.

## Drop the current database

Always verify the current database before deleting it:

```js
db
db.dropDatabase()
```

`db.dropDatabase()` permanently deletes the current database and all of its
collections.

## The `db` object

Inside `mongosh`, `db` represents the current database:

```js
db.getName()
db.getCollectionNames()
db.products.findOne()
```

In `db.products.findOne()`:

- `db` is the current database.
- `products` is a collection.
- `findOne()` is a collection method.

## Multiline commands

`mongosh` waits when a command is incomplete, so documents can span several
lines:

```js
db.products.insertOne({
  name: "MacBook Air",
  price: NumberDecimal("1099.00")
});
```

## Leave the shell

```js
exit
```

You can also press `Ctrl+D`.

## Recap

- `mongosh` is a client that connects to a MongoDB server.
- `db` represents the current database.
- `show dbs` lists databases and `show collections` lists collections.
- `use <name>` changes the current database.
- `help`, `db.help()`, and collection `.help()` methods provide assistance.

Further reading: [MongoDB Shell documentation](https://www.mongodb.com/docs/mongodb-shell/)

---
← [3.4 What Is MongoDB?](04-what-is-mongodb.md) | Next: [3.6 Your First Database →](06-your-first-database-apple-example.md)
