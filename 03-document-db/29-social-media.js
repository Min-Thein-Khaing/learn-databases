// ============================================================
// Pulse Social Media — MongoDB document database example
// Run with: mongosh < 29-social-media.js
// ============================================================

db = db.getSiblingDB("pulse_social")
db.dropDatabase()

db.createCollection("users", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["username", "display_name", "profile", "created_at"],
    properties: {
      username: { bsonType: "string" },
      display_name: { bsonType: "string" },
      profile: { bsonType: "object" },
      created_at: { bsonType: "date" }
    }
  }}
})

db.createCollection("posts", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["author", "body", "media", "hashtags", "visibility", "counts", "created_at"],
    properties: {
      author: { bsonType: "object" },
      body: { bsonType: "string" },
      media: { bsonType: "array" },
      hashtags: { bsonType: "array", items: { bsonType: "string" } },
      visibility: { enum: ["public", "followers", "private"] },
      counts: { bsonType: "object" },
      created_at: { bsonType: "date" }
    }
  }}
})

db.createCollection("comments", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["post_id", "author", "body", "created_at"],
    properties: {
      post_id: { bsonType: "objectId" },
      parent_comment_id: { bsonType: ["objectId", "null"] },
      author: { bsonType: "object" },
      body: { bsonType: "string" },
      created_at: { bsonType: "date" }
    }
  }}
})

db.createCollection("follows", {
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["follower_id", "following_id", "created_at"],
    properties: {
      follower_id: { bsonType: "objectId" },
      following_id: { bsonType: "objectId" },
      created_at: { bsonType: "date" }
    }
  }}
})

const mayaId = new ObjectId()
const somchaiId = new ObjectId()
const ninaId = new ObjectId()
const bangkokPostId = new ObjectId()
const coffeePostId = new ObjectId()
const firstCommentId = new ObjectId()

db.users.insertMany([
  {
    _id: mayaId,
    username: "maya.codes",
    display_name: "Maya Chen",
    profile: {
      bio: "Developer, photographer, and lifelong learner.",
      avatar_url: "https://cdn.example.com/avatars/maya.jpg",
      location: "Bangkok",
      links: [{ label: "Portfolio", url: "https://maya.example.com" }]
    },
    settings: { language: "en", theme: "dark", notifications: { comments: true, follows: true } },
    created_at: ISODate("2026-01-10T08:00:00Z")
  },
  {
    _id: somchaiId,
    username: "somchai.eats",
    display_name: "Somchai Arun",
    profile: { bio: "Finding excellent food and coffee.", avatar_url: "https://cdn.example.com/avatars/somchai.jpg", location: "Chiang Mai", links: [] },
    settings: { language: "th", theme: "light", notifications: { comments: true, follows: false } },
    created_at: ISODate("2026-02-14T10:30:00Z")
  },
  {
    _id: ninaId,
    username: "nina.travels",
    display_name: "Nina Patel",
    profile: { bio: "Slow travel and street photography.", avatar_url: "https://cdn.example.com/avatars/nina.jpg", location: "Singapore", links: [] },
    settings: { language: "en", theme: "system", notifications: { comments: true, follows: true } },
    created_at: ISODate("2026-03-05T12:00:00Z")
  }
])

// Posts embed the author information needed by a feed. The canonical user
// profile remains in users, while the snapshot avoids a lookup for each card.
db.posts.insertMany([
  {
    _id: bangkokPostId,
    author: { _id: mayaId, username: "maya.codes", display_name: "Maya Chen", avatar_url: "https://cdn.example.com/avatars/maya.jpg" },
    body: "Golden hour beside the Chao Phraya River.",
    media: [
      { type: "image", url: "https://cdn.example.com/posts/river-1.jpg", width: NumberInt(1600), height: NumberInt(1067), alt: "Sunset over the Chao Phraya River" },
      { type: "image", url: "https://cdn.example.com/posts/river-2.jpg", width: NumberInt(1600), height: NumberInt(1067), alt: "Boats crossing the river at sunset" }
    ],
    hashtags: ["bangkok", "photography", "sunset"],
    mentions: [], visibility: "public",
    counts: { reactions: NumberInt(2), comments: NumberInt(2), shares: NumberInt(0) },
    created_at: ISODate("2026-09-18T10:15:00Z"), updated_at: ISODate("2026-09-18T10:15:00Z")
  },
  {
    _id: coffeePostId,
    author: { _id: somchaiId, username: "somchai.eats", display_name: "Somchai Arun", avatar_url: "https://cdn.example.com/avatars/somchai.jpg" },
    body: "A quiet morning and a very good pour-over.",
    media: [{ type: "image", url: "https://cdn.example.com/posts/coffee.jpg", width: NumberInt(1200), height: NumberInt(1200), alt: "Pour-over coffee beside a window" }],
    hashtags: ["coffee", "chiangmai"], mentions: [], visibility: "followers",
    counts: { reactions: NumberInt(1), comments: NumberInt(1), shares: NumberInt(0) },
    created_at: ISODate("2026-09-19T01:30:00Z"), updated_at: ISODate("2026-09-19T01:30:00Z")
  }
])

// Comments can grow without limit and are paginated independently, so they
// use a separate collection. A parent ID supports threaded replies.
db.comments.insertMany([
  { _id: firstCommentId, post_id: bangkokPostId, parent_comment_id: null, author: { _id: ninaId, username: "nina.travels", display_name: "Nina Patel" }, body: "The light is beautiful!", reaction_count: NumberInt(1), created_at: ISODate("2026-09-18T10:20:00Z") },
  { post_id: bangkokPostId, parent_comment_id: firstCommentId, author: { _id: mayaId, username: "maya.codes", display_name: "Maya Chen" }, body: "Thank you! It lasted only a few minutes.", reaction_count: NumberInt(0), created_at: ISODate("2026-09-18T10:23:00Z") },
  { post_id: coffeePostId, parent_comment_id: null, author: { _id: mayaId, username: "maya.codes", display_name: "Maya Chen" }, body: "Adding this café to my list.", reaction_count: NumberInt(0), created_at: ISODate("2026-09-19T01:45:00Z") }
])

// Follow relationships are unbounded many-to-many edges, so they are not
// embedded inside user documents.
db.follows.insertMany([
  { follower_id: mayaId, following_id: somchaiId, created_at: ISODate("2026-05-01T00:00:00Z") },
  { follower_id: mayaId, following_id: ninaId, created_at: ISODate("2026-05-02T00:00:00Z") },
  { follower_id: ninaId, following_id: mayaId, created_at: ISODate("2026-05-03T00:00:00Z") }
])

db.users.createIndex({ username: 1 }, { unique: true })
db.posts.createIndex({ "author._id": 1, created_at: -1 })
db.posts.createIndex({ hashtags: 1, visibility: 1, created_at: -1 })
db.posts.createIndex({ body: "text" })
db.comments.createIndex({ post_id: 1, parent_comment_id: 1, created_at: 1 })
db.follows.createIndex({ follower_id: 1, following_id: 1 }, { unique: true })
db.follows.createIndex({ following_id: 1 })

// Public posts tagged photography.
db.posts.find(
  { visibility: "public", hashtags: "photography" },
  { body: 1, author: 1, media: { $slice: 1 }, counts: 1, created_at: 1 }
).sort({ created_at: -1 })

// Maya's feed: find followed accounts, then retrieve their recent posts.
const followedIds = db.follows
  .find({ follower_id: mayaId }, { _id: 0, following_id: 1 })
  .toArray()
  .map(follow => follow.following_id)

db.posts.find({
  "author._id": { $in: followedIds },
  visibility: { $in: ["public", "followers"] }
}).sort({ created_at: -1 }).limit(20)

// Post cards with the latest two comments.
db.posts.aggregate([
  { $lookup: {
    from: "comments",
    let: { postId: "$_id" },
    pipeline: [
      { $match: { $expr: { $eq: ["$post_id", "$$postId"] } } },
      { $sort: { created_at: -1 } },
      { $limit: 2 }
    ],
    as: "latest_comments"
  } },
  { $project: { body: 1, author: 1, media: 1, hashtags: 1, counts: 1, latest_comments: 1, created_at: 1 } },
  { $sort: { created_at: -1 } }
])
