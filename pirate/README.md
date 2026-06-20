# 🏴‍☠️ Pirate

A social media platform built for small communities (≤1000 users, ~100 DAU).

## Stack

- **Frontend:** Vue 3 + Vite + Tailwind CSS + Pinia
- **Backend:** Bun + Hono
- **Database:** MongoDB (via root `.env`)

## Quick start

```bash
cd pirate
bun run install:all
bun run dev
```

- Frontend: http://localhost:5173
- Backend: http://localhost:5000

Uses `MONGO_DB_URL` (database: `social`) and `JWT_SECRET` from the project root `.env` file.

## Features

- Register / login with JWT auth
- Home feed (posts from people you follow)
- Explore all posts
- Create posts with text + images
- Like & comment
- User profiles & follow system
- Search users
- Responsive mobile + desktop UI
