// ============================================================
// Brew & Bite POS — MongoDB document database example
// Run with: mongosh < 27-coffeeshop.js
// ============================================================

db = db.getSiblingDB("brew_and_bite")
db.dropDatabase()

db.createCollection("shops", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["name", "categories", "created_at"],
    properties: {
      name: { bsonType: "string" },
      categories: { bsonType: "array", items: { bsonType: "string" } },
      created_at: { bsonType: "date" }
    }
  }}
})

db.createCollection("menu_items", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["shop_id", "name", "category", "price", "is_available"],
    properties: {
      shop_id: { bsonType: "objectId" },
      name: { bsonType: "string" },
      category: { bsonType: "string" },
      price: { bsonType: "decimal", minimum: NumberDecimal("0") },
      is_available: { bsonType: "bool" }
    }
  }}
})

db.createCollection("customers", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["shop_id", "name"],
    properties: {
      shop_id: { bsonType: "objectId" },
      name: { bsonType: "string" },
      email: { bsonType: "string" }
    }
  }}
})

db.createCollection("vouchers", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["shop_id", "voucher_number", "items", "subtotal", "discount", "total", "payment_method", "created_at"],
    properties: {
      shop_id: { bsonType: "objectId" },
      customer: { bsonType: ["object", "null"] },
      voucher_number: { bsonType: "string" },
      items: { bsonType: "array", minItems: 1 },
      subtotal: { bsonType: "decimal", minimum: NumberDecimal("0") },
      discount: { bsonType: "decimal", minimum: NumberDecimal("0") },
      total: { bsonType: "decimal", minimum: NumberDecimal("0") },
      payment_method: { enum: ["cash", "card", "qr"] },
      created_at: { bsonType: "date" }
    }
  }}
})

const shopId = new ObjectId()
const aliceId = new ObjectId()
const americanoId = new ObjectId()
const latteId = new ObjectId()
const friedRiceId = new ObjectId()

db.shops.insertOne({
  _id: shopId,
  name: "Brew & Bite Café",
  address: "45 Sukhumvit Road, Bangkok, Thailand",
  phone: "02-555-0188",
  categories: ["Coffee", "Drinks", "Meals", "Snacks"],
  created_at: new Date(),
  updated_at: new Date()
})

db.menu_items.insertMany([
  { _id: americanoId, shop_id: shopId, name: "Americano", category: "Coffee", description: "Espresso with hot water", price: NumberDecimal("80.00"), is_available: true },
  { _id: latteId, shop_id: shopId, name: "Café Latte", category: "Coffee", description: "Espresso with steamed milk", price: NumberDecimal("90.00"), is_available: true },
  { _id: friedRiceId, shop_id: shopId, name: "Chicken Fried Rice", category: "Meals", description: "Fried rice with chicken and vegetables", price: NumberDecimal("120.00"), is_available: true }
])

db.customers.insertMany([
  { _id: aliceId, shop_id: shopId, name: "Alice Chen", phone: "081-555-0101", email: "alice@example.com" },
  { shop_id: shopId, name: "Niran Somchai", phone: "089-555-0102", email: "niran@example.com" }
])

// Items are embedded as historical snapshots. Later menu price changes do
// not alter completed vouchers. customer is null for a walk-in sale.
db.vouchers.insertMany([
  {
    shop_id: shopId,
    customer: { _id: aliceId, name: "Alice Chen" },
    voucher_number: "BB-2026-0001",
    items: [
      { menu_id: latteId, name: "Café Latte", quantity: 2, price: NumberDecimal("90.00"), subtotal: NumberDecimal("180.00") },
      { menu_id: friedRiceId, name: "Chicken Fried Rice", quantity: 1, price: NumberDecimal("120.00"), subtotal: NumberDecimal("120.00") }
    ],
    subtotal: NumberDecimal("300.00"), discount: NumberDecimal("20.00"), total: NumberDecimal("280.00"),
    payment_method: "qr", created_at: ISODate("2026-09-19T08:30:00Z")
  },
  {
    shop_id: shopId, customer: null, voucher_number: "BB-2026-0002",
    items: [{ menu_id: americanoId, name: "Americano", quantity: 1, price: NumberDecimal("80.00"), subtotal: NumberDecimal("80.00") }],
    subtotal: NumberDecimal("80.00"), discount: NumberDecimal("0.00"), total: NumberDecimal("80.00"),
    payment_method: "cash", created_at: ISODate("2026-09-19T09:10:00Z")
  }
])

db.menu_items.createIndex({ shop_id: 1, category: 1, name: 1 })
db.customers.createIndex({ shop_id: 1, email: 1 }, { unique: true, sparse: true })
db.vouchers.createIndex({ shop_id: 1, voucher_number: 1 }, { unique: true })
db.vouchers.createIndex({ created_at: -1 })

// Daily sales summary.
db.vouchers.aggregate([
  { $group: { _id: { $dateTrunc: { date: "$created_at", unit: "day" } }, vouchers: { $sum: 1 }, sales: { $sum: "$total" } } },
  { $sort: { _id: 1 } }
])

// Best-selling menu items.
db.vouchers.aggregate([
  { $unwind: "$items" },
  { $group: { _id: "$items.menu_id", name: { $first: "$items.name" }, quantity_sold: { $sum: "$items.quantity" }, revenue: { $sum: "$items.subtotal" } } },
  { $sort: { quantity_sold: -1, name: 1 } }
])
