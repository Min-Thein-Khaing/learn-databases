# Social-Media Document Model

Posts embed author and media data needed by the feed. Comments and follow
relationships remain separate because both can grow without limit.

```mermaid
flowchart LR
    U[(users)] -. author snapshot .-> P[(posts)]
    P -->|post_id| C[(comments)]
    U -->|follower_id| F[(follows)]
    F -->|following_id| U
    P --- M["media: [{ type, url, width, height, alt }]"]
    P --- H["hashtags: [string]"]
    P --- CNT["counts: { reactions, comments, shares }"]
    C --- A["author: { _id, username, display_name }"]
```

| Collection | Important design choice |
|---|---|
| `users` | Canonical profiles, settings, and unique usernames |
| `posts` | Feed-ready author snapshots, media, hashtags, and counters |
| `comments` | Separate threaded content that can grow without limit |
| `follows` | Separate many-to-many relationship between users |

Run [29-social-media.js](29-social-media.js) in `mongosh` to create the example.

---
← [Coffee Shop](28-coffeeshop-diagram.md) | Next example: [IoT Monitoring →](32-iot-monitoring-diagram.md)
