# PropSense — Real Estate Platform with ML-Powered Price Insights
## Full Build Plan for Claude Code

**Stack:** MongoDB, Express, React, Node (MERN) + Python ML microservice
**Author:** Md. Tanvirul Islam Rifat
**Purpose:** Portfolio-grade, industry-level full-stack project

> Suggested name: **PropSense**. Rename freely — search/replace "PropSense" throughout if you pick something else.

---

## 1. Concept

A property listing platform where buyers search/browse flats and agents manage listings — with every listing automatically tagged with a **Low/Medium/High price category** by a machine learning model (a FastAPI-wrapped version of your CSE422 classifier). This is the feature that makes the project stand out: it's not just CRUD, it's a full-stack app with a real ML service integrated into the backend.

---

## 2. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Frontend | React (Vite) + Tailwind CSS + Framer Motion | Fast dev server, utility styling, industry-standard animation lib |
| State (server) | TanStack Query (React Query) | Caching, refetching, loading/error states handled for you |
| State (client/UI) | Zustand | Lightweight, minimal boilerplate vs Redux |
| Backend | Node.js + Express | Core of MERN |
| Database | MongoDB (Atlas) + Mongoose | Flexible schema, industry standard for MERN |
| Auth | JWT (access + refresh tokens) | Real-world auth pattern, not just session cookies |
| ML Service | Python + FastAPI, wrapping your CSE422 model | Reuses real prior work, shows polyglot integration |
| Real-time | Socket.io | Buyer↔agent inquiry chat |
| Images | Cloudinary | Free tier, handles upload/resize/CDN |
| Maps | Leaflet + OpenStreetMap (free) or Mapbox | Property location display |
| Deployment | Vercel (client) + Render/Railway (server + ml-service) + MongoDB Atlas | All free-tier friendly |

*(Note: If you'd rather use Next.js instead of plain React+Vite, everything below still applies — just merge `client/` into a Next.js app router structure. Plain React+Express keeps the "MERN" split cleanest for this build.)*

---

## 3. Database Schema (Mongoose Models)

### User
```js
{
  name: String, required,
  email: String, required, unique,
  password: String, required (hashed via bcrypt),
  role: { type: String, enum: ['buyer', 'agent', 'admin'], default: 'buyer' },
  avatar: String (Cloudinary URL),
  phone: String,
  savedListings: [{ type: ObjectId, ref: 'Property' }],
  createdAt: Date, default: Date.now
}
```

### Property
```js
{
  title: String, required,
  description: String, required,
  price: Number, required,
  priceCategory: { type: String, enum: ['Low', 'Medium', 'High'] }, // set by ML service
  location: {
    area: String,
    city: String,
    coordinates: { lat: Number, lng: Number }
  },
  sizeSqft: Number,
  bedrooms: Number,
  bathrooms: Number,
  floorNumber: Number,
  buildingAgeYears: Number,
  hasBalcony: Boolean,
  parkingAvailable: Boolean,
  nearbySchools: { type: String, enum: ['Few', 'Many'] },
  securityLevel: { type: String, enum: ['Low', 'Medium', 'High'] },
  images: [String], // Cloudinary URLs
  agent: { type: ObjectId, ref: 'User', required: true },
  status: { type: String, enum: ['available', 'pending', 'sold'], default: 'available' },
  views: { type: Number, default: 0 },
  createdAt: Date, default: Date.now,
  updatedAt: Date
}
```

### Inquiry
```js
{
  property: { type: ObjectId, ref: 'Property', required: true },
  buyer: { type: ObjectId, ref: 'User', required: true },
  agent: { type: ObjectId, ref: 'User', required: true },
  messages: [{
    sender: { type: ObjectId, ref: 'User' },
    text: String,
    timestamp: { type: Date, default: Date.now }
  }],
  status: { type: String, enum: ['open', 'closed'], default: 'open' },
  createdAt: Date, default: Date.now
}
```

### Review (optional, adds depth if time allows)
```js
{
  agent: { type: ObjectId, ref: 'User', required: true },
  reviewer: { type: ObjectId, ref: 'User', required: true },
  rating: { type: Number, min: 1, max: 5 },
  comment: String,
  createdAt: Date, default: Date.now
}
```

---

## 4. API Routes (Express)

### Auth — `/api/auth`
| Method | Route | Description |
|---|---|---|
| POST | `/register` | Create account (buyer or agent) |
| POST | `/login` | Returns access + refresh token |
| POST | `/refresh` | Issue new access token |
| POST | `/logout` | Invalidate refresh token |
| GET | `/me` | Return logged-in user (protected) |

### Users — `/api/users`
| Method | Route | Description |
|---|---|---|
| GET | `/:id` | Public profile |
| PATCH | `/:id` | Update profile (protected, owner only) |
| GET | `/:id/saved-listings` | Buyer's saved properties |
| POST | `/:id/saved-listings/:propertyId` | Save a listing |
| DELETE | `/:id/saved-listings/:propertyId` | Remove saved listing |

### Properties — `/api/properties`
| Method | Route | Description |
|---|---|---|
| GET | `/` | List/search with query params: `location, minPrice, maxPrice, bedrooms, priceCategory, page, limit` |
| GET | `/:id` | Single listing detail (increments views) |
| POST | `/` | Create listing (agent only, protected) |
| PATCH | `/:id` | Update listing (agent/owner only) |
| DELETE | `/:id` | Delete listing (agent/owner only) |
| POST | `/:id/predict-price` | Calls ML microservice, caches `priceCategory` on the document |

### Inquiries — `/api/inquiries`
| Method | Route | Description |
|---|---|---|
| POST | `/` | Buyer starts an inquiry on a property |
| GET | `/` | List inquiries for logged-in user (buyer or agent view) |
| GET | `/:id` | Single inquiry thread |
| POST | `/:id/messages` | Send a message (also emits via Socket.io) |
| PATCH | `/:id/status` | Mark open/closed |

---

## 5. ML Microservice (Python + FastAPI)

Wraps your existing CSE422 model as an internal HTTP service the Express backend calls.

```
POST /predict
Body: {
  "size_sqft": 1200, "num_bedrooms": 3, "num_bathrooms": 2,
  "has_balcony": true, "floor_number": 4, "building_age_years": 5,
  "parking_available": true, "nearby_schools": "Many",
  "distance_to_citycenter_km": 3.2, "security_level": "High",
  "location": "City Center"
}
Response: { "price_category": "High", "confidence": 0.61 }
```

- Load the trained model (pickle/joblib export from your CSE422 notebook) at service startup
- Keep this service internal-only (not exposed to the public internet directly) — Express calls it server-to-server
- This is a genuinely good interview talking point: *"I deployed my ML coursework as a live microservice consumed by a production-style Node backend."*

---

## 6. Frontend Structure (React)

### Pages
- `Home` — hero section, animated search bar, featured listings carousel
- `Search` — filter sidebar + list/map toggle, pagination, infinite scroll optional
- `PropertyDetail` — image gallery, full details, price category badge, map, "Contact Agent" inquiry form
- `Dashboard` (role-based)
  - Buyer: saved listings, active inquiries
  - Agent: my listings (create/edit/delete), inquiries inbox
- `Login` / `Register`
- `Profile` — edit account details

### Key Components
- `Navbar` — animated shrink/blur on scroll
- `PropertyCard` — hover lift animation, price category color badge
- `SearchBar` — animated expand/focus state
- `FilterPanel` — slide-in drawer (mobile), sticky sidebar (desktop)
- `ImageGallery` — draggable carousel with crossfade
- `MapView` — Leaflet map with custom pin markers
- `PriceCategoryBadge` — color-coded (green=Low, amber=Medium, red=High), small reveal animation
- `InquiryChatBox` — real-time messages via Socket.io, animated message bubbles
- `ProtectedRoute` — role-based route guard
- `SkeletonCard` — loading state placeholder

### State Management
- **TanStack Query** for all server data (properties, inquiries, user) — handles caching/loading/error automatically
- **Zustand** for auth state (current user, tokens) and UI state (filter drawer open/closed, theme)

---

## 7. Animation Plan (Framer Motion)

| Where | Animation |
|---|---|
| Hero section | Staggered fade + slide-up for headline, subtext, search bar (`staggerChildren`) |
| Property cards | `whileInView` fade/slide-up as user scrolls, staggered by index |
| Route changes | `AnimatePresence` for page transitions (fade or slide) |
| Filter panel | Slide-in/out drawer with spring physics |
| Image gallery | Crossfade between images, drag-to-swipe on mobile |
| Modals (login, inquiry form) | Scale + fade entrance, backdrop blur |
| Property card hover | Scale(1.02) + shadow lift, smooth transition |
| Price badge | Small pop/reveal animation when it renders (draws attention to the ML feature) |
| Map pins | Drop-in bounce animation on map load |
| Buttons | Micro tap animation (`whileTap={{ scale: 0.97 }}`) |
| Loading states | Skeleton shimmer, not spinners — feels more premium |

Keep animations under ~300ms for UI feedback (feels snappy) and 400-600ms for section entrances (feels intentional, not sluggish).

---

## 8. Folder Structure

```
propsense/
├── client/                        # React frontend
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── hooks/
│   │   ├── store/                 # Zustand stores
│   │   ├── services/               # API call functions (axios)
│   │   ├── utils/
│   │   └── App.jsx
│   ├── .env
│   └── package.json
├── server/                        # Express backend
│   ├── src/
│   │   ├── models/                # Mongoose schemas
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── middleware/            # auth, error handling, validation
│   │   ├── config/                # db connection, env config
│   │   ├── services/              # ml-service client (axios call to Python)
│   │   ├── sockets/                # Socket.io handlers
│   │   └── app.js
│   ├── .env
│   └── package.json
├── ml-service/                    # Python FastAPI wrapper
│   ├── model/                     # exported .pkl model + encoders
│   ├── main.py
│   └── requirements.txt
├── docs/
│   ├── architecture-diagram.png
│   └── er-diagram.png
├── .github/workflows/             # CI (GitHub Actions)
├── README.md
└── .gitignore
```

---

## 9. Build Phases (paste to Claude Code one phase at a time)

| Phase | What to build | Est. time |
|---|---|---|
| 0 | Repo scaffolding: init `client` (Vite+React+Tailwind), `server` (Express), `ml-service` (FastAPI); git init; `.env.example` files | 2-3 hrs |
| 1 | Backend foundation: MongoDB connection, User model, JWT auth (register/login/refresh/me), middleware | 1 day |
| 2 | Property model + full CRUD API + search/filter/pagination query logic | 1 day |
| 3 | ML microservice: wrap CSE422 model in FastAPI, connect Express → ML service, cache prediction on listing create/update | 0.5-1 day |
| 4 | Frontend foundation: routing, auth pages, API service layer, React Query + Zustand setup | 1 day |
| 5 | Core pages: Home, Search/Browse (filters + map), Property Detail | 1.5-2 days |
| 6 | Dashboards: agent listing management, buyer saved listings | 1 day |
| 7 | Inquiry/messaging system with Socket.io real-time chat | 1 day |
| 8 | Animation pass: Framer Motion across all pages per Section 7 | 1 day |
| 9 | Testing: Jest + Supertest (API routes), React Testing Library (key components) | 0.5-1 day |
| 10 | Deployment: MongoDB Atlas, Render/Railway (server + ml-service), Vercel (client), GitHub Actions CI | 0.5 day |
| 11 | Polish: README with architecture diagram, demo GIF, final portfolio write-up | 0.5 day |

**Total realistic estimate: ~10-14 working days** if building steadily (not full-time). This lines up well as your project after CSE424/428/470 are done, or in parallel if you want a bigger portfolio push.

---

## 10. Deployment Plan

- **Database:** MongoDB Atlas free tier (M0 cluster)
- **Backend (Express):** Render or Railway — free tier, easy env var config
- **ML service (FastAPI):** Same platform as backend, separate service/process
- **Frontend (React):** Vercel — auto-deploys from GitHub, free tier, fast CDN
- **Images:** Cloudinary free tier
- **Env vars needed:**
  - `server/.env`: `MONGO_URI`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `ML_SERVICE_URL`, `CLOUDINARY_*`, `CLIENT_URL`
  - `client/.env`: `VITE_API_URL`, `VITE_MAPBOX_TOKEN` (if using Mapbox)
  - `ml-service/.env`: `MODEL_PATH`

---

## 11. Testing Plan

- **API:** Jest + Supertest — cover auth flows, property CRUD, permission checks (agent-only routes reject buyers)
- **Frontend:** React Testing Library — test key components (PropertyCard render, SearchBar interaction, form validation)
- **Optional:** One Cypress e2e test covering the critical path: search → view listing → submit inquiry

A few solid tests beat a large brittle suite — 10-15 well-chosen tests is enough to show you understand testing without over-investing.

---

## 12. How to Use This With Claude Code

Paste phases in order, one at a time, e.g.:

> "Using this plan [paste Phase 0 + Section 2 tech stack + Section 8 folder structure], scaffold the PropSense project: client (Vite+React+Tailwind), server (Express), and ml-service (FastAPI) folders with basic configs and git initialized."

Then for each following phase, paste the relevant section (schema, routes, or animation spec) plus a short instruction like "Now implement Phase 1: the User model and JWT auth routes as specified."

This keeps each Claude Code session focused and reviewable, rather than asking for the whole app in one shot.

---

## 13. CV / Portfolio Framing (once built)

> **PropSense — Full-Stack Real Estate Platform with ML Price Insights**
> Built a MERN platform with JWT auth, real-time buyer-agent messaging (Socket.io), and a Python/FastAPI ML microservice serving live price-category predictions on every listing. Deployed across Vercel, Render, and MongoDB Atlas with CI via GitHub Actions.

That one line does a lot of work: full-stack, real-time systems, ML integration, deployment, and CI — in a single sentence a recruiter can scan in five seconds.
