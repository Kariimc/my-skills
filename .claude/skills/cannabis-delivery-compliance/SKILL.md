---
name: cannabis-delivery-compliance
description: Comprehensive NJ-compliant cannabis delivery platform implementation guide. Covers corporate formation (NJ CRC Class 6 license), full PostgreSQL schema with PostGIS geospatial indexing, TypeScript compliance middleware (age verification, weight limits, geofencing with Turf.js), Dutchie/METRC POS synchronization workers, and Docker/GitHub Actions deployment. Use when the user wants the full end-to-end technical implementation of an NJ cannabis delivery platform, including production-ready database schemas, compliance code, POS sync workers, and CI/CD deployment configs.
---

# NJ Cannabis Delivery Platform — Full Compliance Implementation Guide

You are an expert regulatory compliance architect, enterprise full-stack developer, and cannabis supply chain engineer delivering a complete NJ CRC-compliant cannabis delivery platform.

---

## Phase 1: Corporate & Legal Foundations

### Entity Formation
- Form a multi-member LLC or C-Corp via the NJ Business Gateway
- Select a corporate structure that allows outside capital investment

### NJ CRC Class 6 Delivery License
Required submissions to NJ Cannabis Regulatory Commission:
- Comprehensive operational plan
- Social equity compliance documentation
- Proof of physical NJ operational base

### B2B Retail Partnerships
Draft commercial service agreements with licensed Class 5 Retail dispensaries specifying:
- W-2 delivery employees under your Class 6 license, OR
- SaaS software licensing to their internal, badged employees

### Compliant Payment Banking
- Merchant account with cannabis-compliant credit union (e.g., Safe Harbor Financial)
- Closed-loop ACH payment infrastructure (e.g., Aeropay) — bypasses federal Visa/Mastercard bans

---

## Phase 2: Database Schema (PostgreSQL + PostGIS)

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

CREATE TYPE order_status AS ENUM ('pending','accepted','manifested','en_route','delivered','cancelled');
CREATE TYPE license_type AS ENUM ('Class_5_Retail','Class_6_Delivery');

CREATE TABLE corporations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    legal_name VARCHAR(255) NOT NULL,
    trade_name VARCHAR(255),
    license_number VARCHAR(100) UNIQUE NOT NULL,
    license_type license_type NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE dispensaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    corporation_id UUID REFERENCES corporations(id),
    name VARCHAR(255) NOT NULL,
    geo_location GEOMETRY(Point, 4326) NOT NULL,
    pos_provider VARCHAR(50) NOT NULL,  -- 'dutchie' | 'treez' | 'metrc'
    pos_api_key TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dispensary_id UUID REFERENCES dispensaries(id) ON DELETE CASCADE,
    sku VARCHAR(100) NOT NULL,
    metrc_tag VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    thc_mg NUMERIC(6,2) NOT NULL,
    weight_grams NUMERIC(6,2) NOT NULL,
    inventory_count INT NOT NULL,
    price_cents INT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(dispensary_id, sku)
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    date_of_birth DATE NOT NULL,
    id_verified BOOLEAN DEFAULT FALSE,
    id_expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    crc_badge_number VARCHAR(100) UNIQUE NOT NULL,
    background_check_status VARCHAR(50) NOT NULL,
    current_location GEOMETRY(Point, 4326),
    is_active_delivery BOOLEAN DEFAULT FALSE
);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    dispensary_id UUID REFERENCES dispensaries(id),
    driver_id UUID REFERENCES drivers(id),
    metrc_manifest_id VARCHAR(100),
    delivery_address TEXT NOT NULL,
    delivery_location GEOMETRY(Point, 4326) NOT NULL,
    total_weight_grams NUMERIC(6,2) NOT NULL,
    status order_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_dispensaries_geo ON dispensaries USING GIST(geo_location);
CREATE INDEX idx_orders_geo ON orders USING GIST(delivery_location);
CREATE INDEX idx_products_sku ON products(sku);
```

---

## Phase 3: Compliance Middleware (TypeScript)

### Age Verification & Weight Limit Guard
```typescript
// app/actions/compliance.ts
const NJ_MAX_WEIGHT_GRAMS = 28.35; // 1 oz legal limit

export async function verifyUserIdentity(payload: {
  userId: string; dob: string; idExpiration: string;
  documentType: string; stateIssued: string;
}) {
  const birthDate = new Date(payload.dob)
  const today = new Date()
  let age = today.getFullYear() - birthDate.getFullYear()
  const monthDiff = today.getMonth() - birthDate.getMonth()
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) age--
  
  if (age < 21) return { verified: false, reason: 'UNDERAGE' }
  if (new Date(payload.idExpiration) < today) return { verified: false, reason: 'ID_EXPIRED' }
  return { verified: true }
}

export function validateCartWeight(cart: { weightGrams: number; quantity: number }[]) {
  const total = cart.reduce((acc, item) => acc + item.weightGrams * item.quantity, 0)
  return { valid: total <= NJ_MAX_WEIGHT_GRAMS, totalWeight: total }
}
```

### Geofencing Enforcer (Turf.js)
```typescript
// utils/geofencing.ts
import * as turf from '@turf/turf'
import njBoundary from '@/data/nj_boundary.json'
import exclusionZones from '@/data/exclusion_zones.json'

export function validateDeliveryLocation(lng: number, lat: number) {
  const point = turf.point([lng, lat])
  const nj = turf.multiPolygon(njBoundary.coordinates)
  
  if (!turf.booleanPointInPolygon(point, nj))
    return { compliant: false, code: 'GEO_OUT_OF_STATE' }
  
  for (const zone of exclusionZones.features) {
    if (turf.booleanPointInPolygon(point, turf.polygon(zone.geometry.coordinates)))
      return { compliant: false, code: 'GEO_PROHIBITED_ZONE' }
  }
  return { compliant: true, code: 'GEO_VALIDATED' }
}
```

---

## Phase 4: POS Sync Worker (Dutchie → PostgreSQL)

```typescript
// workers/syncMenu.ts
import axios from 'axios'
import { Pool } from 'pg'

const pool = new Pool({ connectionString: process.env.DATABASE_URL })

export async function syncDutchieInventory(dispensaryId: string, apiKey: string) {
  const { data } = await axios.get(`https://dutchie.com/${dispensaryId}/products`, {
    headers: { Authorization: `Bearer ${apiKey}` }
  })
  const client = await pool.connect()
  try {
    for (const p of data.products) {
      await client.query(`
        INSERT INTO products (dispensary_id, sku, metrc_tag, name, thc_mg, weight_grams, inventory_count, price_cents, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW())
        ON CONFLICT (dispensary_id, sku) DO UPDATE SET
          inventory_count = EXCLUDED.inventory_count,
          price_cents = EXCLUDED.price_cents,
          updated_at = NOW()
      `, [dispensaryId, p.sku, p.metrc_tag ?? null, p.name, p.thc_mg ?? 0, p.weight_grams ?? 0, p.quantity, p.price * 100])
    }
  } finally { client.release() }
}
```

---

## Phase 5: Deployment

### Dockerfile
```dockerfile
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

FROM base AS runner
ENV NODE_ENV=production
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

### GitHub Actions CI/CD
```yaml
name: Deploy Cannabis Delivery Engine
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci && npm run build
      - name: Deploy to AWS ECS
        run: |
          aws ecs update-service \
            --cluster ${{ secrets.ECS_CLUSTER }} \
            --service ${{ secrets.ECS_SERVICE }} \
            --force-new-deployment
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION: us-east-1
```

---

## Getting Started

Tell me which phase to implement or expand:
1. Legal checklist and entity formation docs
2. Database schema + PostGIS setup
3. Compliance middleware (age / weight / geofence)
4. METRC API integration + manifest generation
5. Driver dispatch algorithm
6. Full deployment pipeline
