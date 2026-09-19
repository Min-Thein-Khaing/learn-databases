// ============================================================
// Northwind IoT Monitoring — MongoDB document database example
// Run with: mongosh < 31-iot-monitoring.js
// ============================================================

db = db.getSiblingDB("northwind_iot")
db.dropDatabase()

db.createCollection("devices", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["serial_number", "type", "location", "configuration", "status", "installed_at"],
    properties: {
      serial_number: { bsonType: "string" },
      type: { enum: ["temperature_sensor", "air_quality_sensor", "energy_meter"] },
      location: { bsonType: "object" },
      configuration: { bsonType: "object" },
      status: { enum: ["online", "offline", "maintenance"] },
      installed_at: { bsonType: "date" }
    }
  }}
})

db.createCollection("readings", {
  timeseries: {
    timeField: "recorded_at",
    metaField: "device",
    granularity: "minutes"
  },
  // Time-series collections do not support schema validation rules.
  expireAfterSeconds: 7776000
})

db.createCollection("alerts", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["device_id", "severity", "type", "message", "status", "created_at"],
    properties: {
      device_id: { bsonType: "objectId" },
      severity: { enum: ["info", "warning", "critical"] },
      status: { enum: ["open", "acknowledged", "resolved"] },
      created_at: { bsonType: "date" }
    }
  }}
})

const freezerId = new ObjectId()
const officeAirId = new ObjectId()
const meterId = new ObjectId()

// Different device types can have different configuration shapes.
db.devices.insertMany([
  {
    _id: freezerId, serial_number: "TEMP-BKK-001", type: "temperature_sensor",
    location: { site: "Bangkok Warehouse", building: "Cold Storage", room: "Freezer 1", coordinates: { lat: 13.7563, lng: 100.5018 } },
    configuration: { unit: "celsius", sample_interval_seconds: NumberInt(60), minimum: -22, maximum: -16 },
    firmware: { version: "2.4.1", updated_at: ISODate("2026-08-20T00:00:00Z") },
    status: "online", installed_at: ISODate("2026-01-10T00:00:00Z"), tags: ["cold-chain", "critical"]
  },
  {
    _id: officeAirId, serial_number: "AIR-BKK-007", type: "air_quality_sensor",
    location: { site: "Bangkok Office", floor: NumberInt(7), zone: "Open Workspace" },
    configuration: { sample_interval_seconds: NumberInt(300), measures: ["co2_ppm", "pm25", "humidity_percent"] },
    status: "online", installed_at: ISODate("2026-03-15T00:00:00Z"), tags: ["workplace"]
  },
  {
    _id: meterId, serial_number: "ENERGY-BKK-003", type: "energy_meter",
    location: { site: "Bangkok Office", floor: NumberInt(1), panel: "Main-A" },
    configuration: { voltage: NumberInt(230), phases: NumberInt(3), sample_interval_seconds: NumberInt(60) },
    status: "maintenance", installed_at: ISODate("2025-11-02T00:00:00Z"), tags: ["energy"]
  }
])

// The measurement shape varies naturally by device type.
db.readings.insertMany([
  { device: { _id: freezerId, serial_number: "TEMP-BKK-001", type: "temperature_sensor" }, recorded_at: ISODate("2026-09-19T09:00:00Z"), measurements: { temperature_c: -18.4, battery_percent: 91 } },
  { device: { _id: freezerId, serial_number: "TEMP-BKK-001", type: "temperature_sensor" }, recorded_at: ISODate("2026-09-19T09:01:00Z"), measurements: { temperature_c: -15.2, battery_percent: 91 } },
  { device: { _id: officeAirId, serial_number: "AIR-BKK-007", type: "air_quality_sensor" }, recorded_at: ISODate("2026-09-19T09:00:00Z"), measurements: { co2_ppm: 812, pm25: 14.2, humidity_percent: 61.5 } },
  { device: { _id: officeAirId, serial_number: "AIR-BKK-007", type: "air_quality_sensor" }, recorded_at: ISODate("2026-09-19T09:05:00Z"), measurements: { co2_ppm: 1055, pm25: 16.1, humidity_percent: 62.0 } }
])

db.alerts.insertMany([
  { device_id: freezerId, device_serial: "TEMP-BKK-001", severity: "critical", type: "temperature_high", message: "Freezer temperature rose above -16°C.", observed_value: -15.2, threshold: -16, status: "open", created_at: ISODate("2026-09-19T09:01:00Z") },
  { device_id: officeAirId, device_serial: "AIR-BKK-007", severity: "warning", type: "co2_high", message: "CO₂ exceeded 1000 ppm.", observed_value: 1055, threshold: 1000, status: "acknowledged", created_at: ISODate("2026-09-19T09:05:00Z") }
])

db.devices.createIndex({ serial_number: 1 }, { unique: true })
db.devices.createIndex({ "location.site": 1, type: 1, status: 1 })
db.alerts.createIndex({ device_id: 1, status: 1, created_at: -1 })

// Temperature summary in five-minute windows.
db.readings.aggregate([
  { $match: { "device._id": freezerId, recorded_at: { $gte: ISODate("2026-09-19T09:00:00Z") } } },
  { $group: {
    _id: { $dateTrunc: { date: "$recorded_at", unit: "minute", binSize: 5 } },
    minimum: { $min: "$measurements.temperature_c" },
    maximum: { $max: "$measurements.temperature_c" },
    average: { $avg: "$measurements.temperature_c" }
  } },
  { $sort: { _id: 1 } }
])

// Open alerts with current device details.
db.alerts.aggregate([
  { $match: { status: "open" } },
  { $lookup: { from: "devices", localField: "device_id", foreignField: "_id", as: "device" } },
  { $unwind: "$device" },
  { $project: { severity: 1, message: 1, created_at: 1, serial_number: "$device.serial_number", location: "$device.location" } },
  { $sort: { created_at: -1 } }
])
