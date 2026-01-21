# Link Shortener API - Product Requirements Document

## Overview

Build a full-featured link shortener API. Users can create shortened URLs, track clicks with analytics, and manage their links through a RESTful API.

## Tech Stack

- **Runtime**: Node.js with TypeScript
- **Framework**: Hono
- **Database**: SQLite via better-sqlite3 (raw SQL, no ORM)
- **Validation**: Zod
- **Testing**: Vitest
- **Geo-IP**: ip-api.com (free API)
- **QR Codes**: qrcode package

## Database Schema

Create these tables in SQLite:

```sql
-- API Keys for authentication
CREATE TABLE api_keys (
  id TEXT PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  name TEXT,
  created_at INTEGER NOT NULL
);

-- Shortened links
CREATE TABLE links (
  id TEXT PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  target_url TEXT NOT NULL,
  api_key_id TEXT REFERENCES api_keys(id),
  password_hash TEXT,
  expires_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Tags for organizing links
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

-- Many-to-many relationship between links and tags
CREATE TABLE link_tags (
  link_id TEXT REFERENCES links(id) ON DELETE CASCADE,
  tag_id TEXT REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (link_id, tag_id)
);

-- Click tracking
CREATE TABLE clicks (
  id TEXT PRIMARY KEY,
  link_id TEXT REFERENCES links(id) ON DELETE CASCADE,
  timestamp INTEGER NOT NULL,
  ip TEXT,
  user_agent TEXT,
  referrer TEXT,
  country TEXT,
  city TEXT
);
```

## API Endpoints

### Health Check

- `GET /api/health` - Returns `{ status: "ok" }`

### Links

#### Create Link

`POST /api/links`

Request body:

```json
{
  "url": "https://example.com/very-long-url",
  "slug": "custom-slug", // optional, auto-generated if not provided
  "expiresAt": 1234567890, // optional, unix timestamp
  "password": "secret", // optional
  "tags": ["marketing", "q1"] // optional
}
```

Response (201):

```json
{
  "id": "abc123",
  "slug": "custom-slug",
  "shortUrl": "http://localhost:3000/custom-slug",
  "targetUrl": "https://example.com/very-long-url",
  "expiresAt": 1234567890,
  "hasPassword": true,
  "tags": ["marketing", "q1"],
  "createdAt": 1234567890,
  "updatedAt": 1234567890
}
```

#### Bulk Create Links

`POST /api/links/bulk`

Request body:

```json
{
  "links": [
    { "url": "https://example1.com" },
    { "url": "https://example2.com", "slug": "custom" }
  ]
}
```

Response (201):

```json
{
  "created": [
    { "id": "abc123", "slug": "xyz789", "shortUrl": "..." },
    { "id": "def456", "slug": "custom", "shortUrl": "..." }
  ],
  "errors": []
}
```

#### List Links

`GET /api/links?page=1&limit=20&tag=marketing`

Response (200):

```json
{
  "links": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

#### Get Link

`GET /api/links/:id`

Response (200): Same as create response

#### Update Link

`PATCH /api/links/:id`

Request body (all fields optional):

```json
{
  "url": "https://new-url.com",
  "slug": "new-slug",
  "expiresAt": 1234567890,
  "password": "new-password",
  "tags": ["new-tag"]
}
```

#### Delete Link

`DELETE /api/links/:id`

Response (204): No content

### Redirect

#### Redirect to Target

`GET /:slug`

- Redirects (302) to target URL
- Records click with: timestamp, IP, user agent, referrer
- Fetches geo data from ip-api.com asynchronously
- If link has password, returns 401 with `{ error: "Password required" }`
- If link is expired, returns 410 with `{ error: "Link expired" }`

#### Password-Protected Redirect

`GET /:slug?password=secret`

- Same as above but validates password first

### Analytics

#### Get Link Stats

`GET /api/links/:id/stats`

Response (200):

```json
{
  "totalClicks": 1234,
  "clicksByDay": [
    { "date": "2024-01-15", "count": 50 },
    { "date": "2024-01-16", "count": 75 }
  ],
  "clicksByCountry": [
    { "country": "US", "count": 500 },
    { "country": "UK", "count": 200 }
  ],
  "topReferrers": [
    { "referrer": "twitter.com", "count": 300 },
    { "referrer": "direct", "count": 250 }
  ],
  "recentClicks": [
    {
      "timestamp": 1234567890,
      "country": "US",
      "city": "New York",
      "referrer": "twitter.com"
    }
  ]
}
```

#### Get Raw Clicks

`GET /api/links/:id/clicks?page=1&limit=50`

Response (200):

```json
{
  "clicks": [
    {
      "id": "click123",
      "timestamp": 1234567890,
      "ip": "1.2.3.4",
      "userAgent": "Mozilla/5.0...",
      "referrer": "https://twitter.com",
      "country": "US",
      "city": "New York"
    }
  ],
  "pagination": { ... }
}
```

### QR Code

#### Generate QR Code

`GET /api/links/:id/qr?size=300`

Response: PNG image (Content-Type: image/png)

### API Keys

#### Create API Key

`POST /api/keys`

Request body:

```json
{
  "name": "My App"
}
```

Response (201):

```json
{
  "id": "key123",
  "key": "sk_live_abc123xyz789", // Only shown once
  "name": "My App",
  "createdAt": 1234567890
}
```

#### Delete API Key

`DELETE /api/keys/:id`

Response (204): No content

### Tags

#### List Tags

`GET /api/tags`

Response (200):

```json
{
  "tags": [
    { "id": "tag1", "name": "marketing", "linkCount": 15 },
    { "id": "tag2", "name": "q1", "linkCount": 8 }
  ]
}
```

#### Create Tag

`POST /api/tags`

Request body:

```json
{
  "name": "new-tag"
}
```

Response (201):

```json
{
  "id": "tag123",
  "name": "new-tag"
}
```

## Authentication

- API key passed via `Authorization: Bearer sk_live_xxx` header
- All `/api/*` endpoints require authentication except `GET /api/health`
- The redirect endpoint `GET /:slug` does NOT require authentication

## Rate Limiting

- 100 requests per minute per API key
- 20 requests per minute per IP for unauthenticated endpoints
- Return 429 with `Retry-After` header when exceeded

## Validation Rules

- **URL**: Must be valid URL format (http/https)
- **Slug**: 3-50 characters, alphanumeric + hyphens only, must be unique
- **Password**: Minimum 4 characters if provided
- **Tag name**: 1-30 characters, alphanumeric + hyphens only

## Error Responses

All errors return JSON:

```json
{
  "error": "Human readable message",
  "code": "VALIDATION_ERROR",
  "details": { ... }  // optional
}
```

Error codes:

- `VALIDATION_ERROR` (400)
- `UNAUTHORIZED` (401)
- `NOT_FOUND` (404)
- `CONFLICT` (409) - e.g., slug already exists
- `GONE` (410) - link expired
- `RATE_LIMITED` (429)
- `INTERNAL_ERROR` (500)

## Scripts

Add to package.json:

```json
{
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest",
    "db:init": "tsx src/db/init.ts"
  }
}
```

## Environment Variables

```
PORT=3000
BASE_URL=http://localhost:3000
DATABASE_PATH=./data/links.db
```

## Implementation Notes

1. **Slug Generation**: Use nanoid with custom alphabet (a-z, 0-9) for 7-character slugs
2. **Password Hashing**: Use bcrypt with salt rounds of 10
3. **Geo Lookup**: Call ip-api.com/json/{ip} - cache results to avoid rate limits
4. **Click Recording**: Record click synchronously, geo lookup can be async
5. **Database**: Create `data/` directory if it doesn't exist, initialize schema on startup
6. **IDs**: Use nanoid for all entity IDs
