---
name: cannabis-delivery-compliance
description: Comprehensive NJ-compliant cannabis delivery platform implementation guide. Covers corporate formation (NJ CRC Class 6 license), full PostgreSQL schema with PostGIS geospatial indexing, TypeScript compliance middleware (age verification, weight limits, geofencing with Turf.js), Dutchie/METRC POS synchronization workers, and Docker/GitHub Actions deployment. Use when the user wants the full end-to-end technical implementation of an NJ cannabis delivery platform, including production-ready database schemas, compliance code, POS sync workers, and CI/CD deployment configs.
---

# NJ Cannabis Delivery Platform — Full Compliance Implementation Guide

You are an expert regulatory compliance architect, enterprise full-stack developer, and cannabis supply chain engineer delivering a complete NJ CRC-compliant cannabis delivery platform.

---

## LOOP PROTOCOLS

### Context-First Loop
→ ASSESS context sufficiency before any output: What phase of compliance? (licensing, build, audit, reporting?) Which license type? (Class 5 with delivery endorsement or Class 6 standalone?) METRC credentials available? Existing POS system?
→ IF missing critical info: ask ONE targeted question → gather → reassess
→ PROCEED only when compliance scope, license type, and regulatory obligations are confirmed

### Verify-Refine-Deliver (VRD) Loop
→ GENERATE compliance artifact → SELF-CHECK against NJ CRC quality gate below → IDENTIFY gaps → REFINE → RE-VERIFY
→ Max 3 iterations; surface specific regulatory blocker if unresolvable
→ DELIVER only when ALL quality gate criteria pass

### Regression Guard
→ After every compliance middleware change: re-verify METRC sync timing, age verification fail-closed behavior, manifest state machine, and inventory reconciliation alarm remain intact
→ Log each iteration: what changed, regulatory impact, test result

---

## NJ CRC Regulatory Map (N.J.A.C. 17:30)

### Key Provisions Reference
| Section | Topic | Key Requirement |
|---|---|---|
| 17:30-1 | Definitions | "Cannabis delivery" definition, "Class 5/6 license" scope |
| 17:30-2 | License classes | Class 5 = retail with delivery; Class 6 = delivery-only operator |
| 17:30-6 | Application requirements | Social equity disclosure, background checks, operational plan |
| 17:30-7 | Seed-to-sale tracking | METRC mandatory; all packages tagged; 24h sync requirement |
| 17:30-10 | Security requirements | Video surveillance 90-day retention; locking storage in vehicles |
| 17:30-11 | Delivery operations | Manifest required; driver must carry CRC badge; GPS tracking |
| 17:30-14 | Transport manifests | Pre-departure generation; real-time update at each stop |
| 17:30-16 | Age verification | 21+; government-issued photo ID; fail-closed; audit log |
| 17:30-18 | Purchase limits | 1 oz (28.35g) flower equivalent per 24h per customer |
| 17:30-19 | Prohibited zones | Federal property; schools/daycares 1,000 ft; parks (municipal) |
| 17:30-20 | Municipal opt-in | Delivery only permitted in municipalities that have opted in |
| 17:30-21 | Advertising | No advertising near schools; no targeting under-21; required disclaimers |
| 17:30-22 | Labeling | Required label fields: license #, METRC tag, THC%, weight, COA QR code |
| 17:30-23 | Lab testing | COA required before sale; failed tests → quarantine; 90-day retention |
| 17:30-24 | Employment | Social equity employee hiring targets; background check requirements |
| 17:30-25 | Reporting | Daily manifests; quarterly compliance reports; annual license renewal |

### Social Equity Provisions (17:30-24)
- Minority-, women-, and veteran-owned business hiring preferences
- Impact Zone employer hiring targets (document and report)
- Social equity plans required in license application
- Annual reporting to NJ CRC on social equity metrics

---

## Phase 1: Corporate & Legal Foundations

### Entity Formation
- Form multi-member LLC or C-Corp via NJ Business Gateway (`business.nj.gov`)
- Designate a Compliance Officer (named individual, on license)
- Social equity compliance documentation required at application

### License Types
- **Class 5 Retail with Delivery Endorsement**: dispensary that also delivers; delivery employees are W-2 under your Class 5 license
- **Class 6 Standalone Delivery**: delivery-only operator; partners with Class 5 dispensaries; employees are W-2 under your Class 6 license (not contractors)

### Insurance Requirements
- General liability: minimum $1M per occurrence
- Commercial auto: all delivery vehicles, including hired/non-owned
- Product liability: required for cannabis products
- Workers' compensation: mandatory for all W-2 drivers
- Cyber liability: recommended (handling PII + payment data)

### Payment Infrastructure
- ACH via cannabis-compliant fintech (Aeropay, PayGarden, Hypur)
- Cannabis-compliant credit union merchant account (Safe Harbor Financial, Partner Colorado CU)
- Cash handling policy: dual-control, safe drop limit per NJ CRC (document in SOP)
- No Visa/Mastercard direct processing — federal prohibition applies

---

## Phase 2: Database Schema (PostgreSQL + PostGIS)

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE order_status AS ENUM (
  'placed','age_verified','packed','dispatched','delivered','failed','cancelled'
);
CREATE TYPE license_type AS ENUM ('Class_5_Retail','Class_6_Delivery');
CREATE TYPE manifest_status AS ENUM (
  'generated','departed','at_stop','stop_complete','returned','closed'
);
CREATE TYPE lab_status AS ENUM ('passed','failed','pending','not_required');

CREATE TABLE corporations (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  legal_name     TEXT NOT NULL,
  trade_name     TEXT,
  license_number TEXT UNIQUE NOT NULL,
  license_type   license_type NOT NULL,
  license_expiry DATE NOT NULL,
  compliance_officer_name TEXT NOT NULL,
  social_equity_plan_url  TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE dispensaries (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  corporation_id   UUID REFERENCES corporations(id),
  name             TEXT NOT NULL,
  license_number   TEXT NOT NULL,
  geo_location     GEOMETRY(Point, 4326) NOT NULL,
  municipality     TEXT NOT NULL,
  municipality_opted_in BOOLEAN NOT NULL DEFAULT FALSE,
  pos_provider     TEXT NOT NULL,  -- 'dutchie' | 'treez' | 'blaze'
  pos_api_key_ref  TEXT NOT NULL,  -- reference to AWS Secrets Manager path
  is_active        BOOLEAN DEFAULT TRUE
);
CREATE INDEX idx_dispensaries_geo ON dispensaries USING GIST(geo_location);

CREATE TABLE packages (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  metrc_tag         TEXT UNIQUE NOT NULL,
  dispensary_id     UUID REFERENCES dispensaries(id),
  product_name      TEXT NOT NULL,
  category          TEXT NOT NULL,
  thc_pct           NUMERIC(5,2),
  cbd_pct           NUMERIC(5,2),
  unit_weight_grams NUMERIC(6,3) NOT NULL,
  quantity          NUMERIC(10,3) NOT NULL,
  lab_result_status lab_status NOT NULL DEFAULT 'pending',
  coa_url           TEXT,
  is_quarantined    BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE products (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dispensary_id   UUID REFERENCES dispensaries(id),
  package_id      UUID REFERENCES packages(id),
  sku             TEXT NOT NULL,
  name            TEXT NOT NULL,
  category        TEXT NOT NULL,
  thc_mg          NUMERIC(6,2) NOT NULL,
  weight_grams    NUMERIC(6,2) NOT NULL,
  inventory_count INT NOT NULL,
  price_cents     INT NOT NULL,
  is_compliant    BOOLEAN NOT NULL DEFAULT TRUE,  -- false if lab failed or label non-compliant
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(dispensary_id, sku)
);

-- PII encrypted at rest
CREATE TABLE users (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email_encrypted    BYTEA NOT NULL,
  phone_encrypted    BYTEA NOT NULL,
  dob_encrypted      BYTEA NOT NULL,
  id_verified        BOOLEAN NOT NULL DEFAULT FALSE,
  id_verified_at     TIMESTAMPTZ,
  id_expiry_date     DATE,
  id_type            TEXT,
  id_state           CHAR(2),
  daily_limit_grams  NUMERIC(6,2) NOT NULL DEFAULT 28.35,
  created_at         TIMESTAMPTZ DEFAULT NOW()
);

-- Immutable append-only; revoke UPDATE/DELETE from app role
CREATE TABLE age_verification_log (
  id             BIGSERIAL PRIMARY KEY,
  user_id        UUID REFERENCES users(id),
  verified_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  result         TEXT NOT NULL,
  ocr_confidence NUMERIC(5,4),
  id_type        TEXT,
  id_state       CHAR(2),
  reviewer_id    UUID,
  ip_address     INET
);

CREATE TABLE vehicles (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  corporation_id      UUID REFERENCES corporations(id),
  plate_number        TEXT NOT NULL,
  vin                 TEXT NOT NULL,
  registration_expiry DATE NOT NULL,
  insurance_expiry    DATE NOT NULL,
  has_locking_storage BOOLEAN NOT NULL DEFAULT TRUE,
  has_temp_control    BOOLEAN NOT NULL DEFAULT FALSE,
  is_active           BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE drivers (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  corporation_id          UUID REFERENCES corporations(id),
  name_encrypted          BYTEA NOT NULL,
  crc_badge_number        TEXT UNIQUE NOT NULL,
  badge_expiry            DATE NOT NULL,
  background_check_status TEXT NOT NULL DEFAULT 'pending',
  background_check_date   DATE,
  vehicle_id              UUID REFERENCES vehicles(id),
  current_location        GEOMETRY(Point, 4326),
  is_on_duty              BOOLEAN DEFAULT FALSE
);

CREATE TABLE manifests (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  metrc_transfer_id  TEXT,
  driver_id          UUID REFERENCES drivers(id),
  vehicle_id         UUID REFERENCES vehicles(id),
  dispensary_id      UUID REFERENCES dispensaries(id),
  status             manifest_status NOT NULL DEFAULT 'generated',
  departure_time     TIMESTAMPTZ,
  return_time        TIMESTAMPTZ,
  total_weight_grams NUMERIC(8,3) NOT NULL,
  pdf_url            TEXT,
  created_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE deliveries (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  manifest_id           UUID REFERENCES manifests(id),
  user_id               UUID REFERENCES users(id),
  delivery_address_encrypted BYTEA NOT NULL,
  delivery_location     GEOMETRY(Point, 4326) NOT NULL,
  geocode_confidence    NUMERIC(4,3) NOT NULL,
  zone_check_result     TEXT NOT NULL,
  status                order_status NOT NULL DEFAULT 'placed',
  arrived_at            TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  failure_reason        TEXT,
  metrc_sale_id         TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_deliveries_geo ON deliveries USING GIST(delivery_location);

-- Immutable audit log
CREATE TABLE audit_log (
  id          BIGSERIAL PRIMARY KEY,
  event_type  TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id   UUID NOT NULL,
  actor_id    UUID,
  payload     JSONB NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## Phase 3: Compliance Middleware (TypeScript)

### Age Verification — Fail-Closed
```typescript
// middleware/ageVerification.ts
const MIN_AGE = 21
const MIN_OCR_CONFIDENCE = 0.90

export async function verifyAge(payload: {
  userId: string
  dob: string
  idExpiration: string
  documentType: string
  stateIssued: string
  ocrConfidence: number
  ipAddress: string
}): Promise<{ verified: boolean; reason: string }> {
  // Fail closed: if confidence below threshold, deny
  if (payload.ocrConfidence < MIN_OCR_CONFIDENCE) {
    await logVerification(payload.userId, 'DENIED_OCR_FAIL', payload.ocrConfidence, payload.ipAddress)
    return { verified: false, reason: 'DENIED_OCR_FAIL' }
  }

  const today = new Date()
  const dob = new Date(payload.dob)
  let age = today.getFullYear() - dob.getFullYear()
  const m = today.getMonth() - dob.getMonth()
  if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) age--

  if (age < MIN_AGE) {
    await logVerification(payload.userId, 'DENIED_UNDERAGE', payload.ocrConfidence, payload.ipAddress)
    return { verified: false, reason: 'DENIED_UNDERAGE' }
  }

  if (new Date(payload.idExpiration) < today) {
    await logVerification(payload.userId, 'DENIED_EXPIRED', payload.ocrConfidence, payload.ipAddress)
    return { verified: false, reason: 'DENIED_EXPIRED' }
  }

  await logVerification(payload.userId, 'APPROVED', payload.ocrConfidence, payload.ipAddress)
  await db.query(
    `UPDATE users SET id_verified=TRUE, id_verified_at=NOW(), id_expiry_date=$2, id_type=$3, id_state=$4 WHERE id=$1`,
    [payload.userId, payload.idExpiration, payload.documentType, payload.stateIssued]
  )
  return { verified: true, reason: 'APPROVED' }
}

async function logVerification(userId: string, result: string, confidence: number, ip: string) {
  // Immutable INSERT — no update path
  await db.query(
    `INSERT INTO age_verification_log (user_id, result, ocr_confidence, ip_address) VALUES ($1,$2,$3,$4)`,
    [userId, result, confidence, ip]
  )
}
```

### Purchase Weight Limit Guard
```typescript
// middleware/weightLimit.ts
const NJ_DAILY_LIMIT_GRAMS = 28.35

// THC equivalency factors per NJ CRC guidance
const THC_EQUIVALENCY: Record<string, number> = {
  flower: 1.0,
  concentrate: 4.0,
  edible: 0.1,  // per mg THC
  tincture: 1.0,
  topical: 0.0  // not counted toward limit
}

export async function checkDailyLimit(userId: string, cartItems: CartItem[]): Promise<{
  allowed: boolean
  cartEquivalentGrams: number
  usedTodayGrams: number
}> {
  const { rows } = await db.query(`
    SELECT COALESCE(SUM(oi.weight_grams), 0) AS used_grams
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.user_id = $1
      AND o.status = 'delivered'
      AND o.created_at > NOW() - INTERVAL '24 hours'
  `, [userId])
  const usedGrams = parseFloat(rows[0].used_grams)
  const cartGrams = cartItems.reduce((acc, item) => acc + item.weightGrams * item.quantity, 0)
  return {
    allowed: (usedGrams + cartGrams) <= NJ_DAILY_LIMIT_GRAMS,
    cartEquivalentGrams: cartGrams,
    usedTodayGrams: usedGrams
  }
}
```

### Geofencing Enforcer
```typescript
// middleware/geofencing.ts
import * as turf from '@turf/turf'
import njBoundary from '@/data/nj_boundary.geojson'
import exclusionZones from '@/data/nj_exclusion_zones.geojson'
import municipalOptIn from '@/data/nj_municipal_optin.json'

export interface GeoResult {
  compliant: boolean
  code: 'COMPLIANT' | 'OUT_OF_STATE' | 'PROHIBITED_ZONE' | 'MUNICIPALITY_NOT_OPTED_IN'
  detail?: string
}

// SERVER-SIDE ONLY — never trust client-submitted zone check result
export function validateDeliveryLocation(lng: number, lat: number, municipality: string): GeoResult {
  const point = turf.point([lng, lat])

  if (!turf.booleanPointInPolygon(point, njBoundary))
    return { compliant: false, code: 'OUT_OF_STATE' }

  if (!municipalOptIn[municipality])
    return { compliant: false, code: 'MUNICIPALITY_NOT_OPTED_IN', detail: municipality }

  for (const zone of exclusionZones.features) {
    // Buffer already pre-computed (1,000 ft geodesic) in GeoJSON data layer
    if (turf.booleanPointInPolygon(point, zone))
      return { compliant: false, code: 'PROHIBITED_ZONE', detail: zone.properties?.name }
  }

  return { compliant: true, code: 'COMPLIANT' }
}
```

### Compliance Request Interceptor (Express middleware)
```typescript
// middleware/complianceLayer.ts
import { Request, Response, NextFunction } from 'express'

export async function complianceGate(req: Request, res: Response, next: NextFunction) {
  const userId = req.user?.id
  if (!userId) return res.status(401).json({ error: 'UNAUTHENTICATED' })

  // 1. Check ID verification status
  const { rows: [user] } = await db.query(
    `SELECT id_verified, id_expiry_date FROM users WHERE id=$1`, [userId]
  )
  if (!user.id_verified || new Date(user.id_expiry_date) < new Date()) {
    return res.status(403).json({ error: 'ID_VERIFICATION_REQUIRED' })
  }

  // 2. Check municipality opt-in for delivery address
  const { municipality, lng, lat } = req.body.deliveryLocation ?? {}
  if (lng && lat) {
    const geoResult = validateDeliveryLocation(lng, lat, municipality)
    if (!geoResult.compliant) {
      return res.status(422).json({ error: geoResult.code, detail: geoResult.detail })
    }
  }

  // 3. Check daily weight limit
  if (req.body.cartItems) {
    const limitCheck = await checkDailyLimit(userId, req.body.cartItems)
    if (!limitCheck.allowed) {
      return res.status(422).json({
        error: 'DAILY_LIMIT_EXCEEDED',
        usedGrams: limitCheck.usedTodayGrams,
        cartGrams: limitCheck.cartEquivalentGrams,
        limitGrams: 28.35
      })
    }
  }

  next()
}
```

---

## Phase 4: METRC API v2 Integration

### Endpoint Reference
```
Base URL (prod):    https://api.metrc.com
Base URL (sandbox): https://sandbox-api.metrc.com
Auth:               Basic base64(userApiKey:vendorApiKey)

GET  /packages/v2/active?licenseNumber=XXX           — active packages
GET  /packages/v2/{tag}?licenseNumber=XXX            — single package
POST /transfers/v2?licenseNumber=XXX                 — create manifest/transfer
GET  /transfers/v2/outgoing?licenseNumber=XXX        — outgoing transfers
POST /sales/v2/receipts?licenseNumber=XXX            — record sale receipt
GET  /labtests/v2/results?licenseNumber=XXX          — lab test results
POST /packages/v2/adjust?licenseNumber=XXX           — adjust package quantity
```

### Sandbox Integration Testing
```typescript
const METRC_BASE = process.env.NODE_ENV === 'production'
  ? 'https://api.metrc.com'
  : 'https://sandbox-api.metrc.com'

// Test license number for sandbox: varies by state; NJ sandbox = provided by NJ CRC
const TEST_LICENSE = process.env.METRC_TEST_LICENSE ?? 'LIC-NJ-SANDBOX-001'
```

### Create METRC Transfer (Manifest)
```typescript
export async function createMetrcTransfer(manifest: Manifest) {
  const payload = {
    ShipperLicenseNumber: manifest.dispensaryLicense,
    ShipperName: manifest.dispensaryName,
    TransporterFacilityLicenseNumber: manifest.deliveryLicense,
    DriverOccupationalLicenseNumber: manifest.driverBadge,
    DriverName: manifest.driverName,
    DriverLicenseNumber: manifest.driverLicense,
    PhoneNumberForQuestions: manifest.dispatchPhone,
    VehicleMake: manifest.vehicleMake,
    VehicleModel: manifest.vehicleModel,
    VehicleLicensePlateNumber: manifest.vehiclePlate,
    Destinations: manifest.stops.map(stop => ({
      RecipientLicenseNumber: stop.recipientLicense ?? null,
      TransferTypeName: 'Delivery Sale',
      PlannedRoute: stop.address,
      EstimatedDepartureDateTime: manifest.departureTime,
      EstimatedArrivalDateTime: stop.estimatedArrival,
      Transporters: [],
      Packages: stop.packages.map(pkg => ({
        PackageLabel: pkg.metrcTag,
        WholesalePrice: pkg.wholesalePriceCents / 100
      }))
    }))
  }

  const { data } = await metrcClient.post(
    `/transfers/v2?licenseNumber=${manifest.dispensaryLicense}`,
    [payload]
  )
  return data
}
```

### Post Sale Receipt (after delivery)
```typescript
export async function postSaleReceipt(delivery: CompletedDelivery) {
  const payload = {
    SalesDateTime: delivery.completedAt.toISOString(),
    SalesCustomerType: 'Consumer',
    PatientLicenseNumber: null,
    CaregiverLicenseNumber: null,
    IdentificationMethod: 'State Issued ID',
    Transactions: delivery.items.map(item => ({
      PackageLabel: item.metrcTag,
      Quantity: item.quantity,
      UnitOfMeasureName: item.unitOfMeasure,
      TotalAmount: item.totalCents / 100
    }))
  }

  await metrcClient.post(
    `/sales/v2/receipts?licenseNumber=${delivery.licenseNumber}`,
    [payload]
  )
}
```

### Failed Lab Results — Quarantine Flow
```typescript
export async function processLabResults(licenseNumber: string) {
  const { data } = await metrcClient.get(`/labtests/v2/results?licenseNumber=${licenseNumber}`)
  for (const result of data) {
    if (result.OverallPassed === false) {
      // Quarantine in METRC + local DB
      await metrcClient.post(`/packages/v2/adjust?licenseNumber=${licenseNumber}`, [{
        Label: result.PackageLabel,
        Quantity: 0,
        UnitOfMeasureName: result.UnitOfMeasureName,
        AdjustmentReason: 'Failed Lab Test',
        AdjustmentDate: new Date().toISOString().split('T')[0],
        RemedyMethodName: null
      }])
      await db.query(
        `UPDATE packages SET is_quarantined=TRUE, lab_result_status='failed' WHERE metrc_tag=$1`,
        [result.PackageLabel]
      )
      await db.query(
        `UPDATE products SET is_compliant=FALSE WHERE package_id=(SELECT id FROM packages WHERE metrc_tag=$1)`,
        [result.PackageLabel]
      )
      await createComplianceAlert({ type: 'LAB_FAIL_QUARANTINE', packageTag: result.PackageLabel })
    }
  }
}
```

---

## Phase 5: Dutchie POS Sync

```typescript
// workers/dutchieSync.ts — GraphQL menu sync
const DUTCHIE_GRAPHQL = 'https://plus.dutchie.com/plus/2021-07/graphql'

const MENU_QUERY = `
  query GetMenu($dispensaryId: ID!) {
    dispensary(id: $dispensaryId) {
      menu {
        products {
          id name category strainType
          variants { id price inventory { quantity } }
          labResults { thcContent cbdContent }
          potencyAmount potencyUnit
        }
      }
    }
  }
`

export async function syncDutchieMenu(dispensaryId: string, apiKey: string) {
  const { data } = await axios.post(DUTCHIE_GRAPHQL,
    { query: MENU_QUERY, variables: { dispensaryId } },
    { headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' } }
  )

  const client = await pool.connect()
  try {
    await client.query('BEGIN')
    for (const p of data.data.dispensary.menu.products) {
      const variant = p.variants[0]
      // Only sync products with COA (lab results present)
      if (!p.labResults?.thcContent && p.category !== 'TOPICAL') continue

      await client.query(`
        INSERT INTO products (dispensary_id, sku, name, category, thc_mg, weight_grams, inventory_count, price_cents, updated_at)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW())
        ON CONFLICT (dispensary_id, sku) DO UPDATE SET
          inventory_count = EXCLUDED.inventory_count,
          price_cents = EXCLUDED.price_cents,
          updated_at = NOW()
      `, [dispensaryId, p.id, p.name, p.category,
          p.labResults?.thcContent ?? 0,
          p.potencyAmount ?? 0,
          variant?.inventory?.quantity ?? 0,
          Math.round((variant?.price ?? 0) * 100)])
    }
    await client.query('COMMIT')
  } catch (e) {
    await client.query('ROLLBACK')
    throw e
  } finally { client.release() }
}
```

---

## Conditional Access Control Matrix

| Role | Packages | Manifests | Age Verification Log | Audit Log | Customer PII | Orders |
|---|---|---|---|---|---|---|
| `driver` | READ (own manifest) | READ (own) | NONE | NONE | NONE | READ (own deliveries) |
| `dispatcher` | READ | CREATE/READ | NONE | NONE | NONE | CREATE/READ/UPDATE |
| `compliance_officer` | READ | READ | READ | READ | READ (anonymized) | READ |
| `manager` | READ/UPDATE | READ | READ | READ | READ | READ/UPDATE |
| `app_role` | READ/INSERT/UPDATE | READ/INSERT/UPDATE | INSERT only | INSERT only | READ/INSERT | READ/INSERT/UPDATE |
| `admin` | ALL | ALL | READ | READ | ALL | ALL |

---

## Advertising Compliance (17:30-21)

Required disclaimers on all marketing materials:
- "Keep Out of Reach of Children"
- "For Use Only by Adults 21 Years of Age and Older"
- NJ CRC license number
- "This product has not been analyzed or approved by the FDA"

Prohibited:
- Advertising within 1,000 ft of schools, daycares, playgrounds
- Content that targets or appeals to persons under 21
- Health claims or therapeutic benefit claims
- Cartoon characters, toys, or child-appealing imagery

---

## Product Label Compliance (17:30-22)

Required label fields:
```
[ ] License number
[ ] METRC package tag (barcode or QR)
[ ] Product name and category
[ ] Net weight / volume
[ ] THC % and CBD %
[ ] Serving size and servings per container (edibles)
[ ] Ingredients list (edibles/concentrates)
[ ] Allergen warnings
[ ] Batch/lot number
[ ] Test date and testing laboratory name
[ ] COA QR code (links to full Certificate of Analysis)
[ ] "KEEP OUT OF REACH OF CHILDREN" warning
[ ] "For Adults 21+" statement
[ ] Manufacture/packaging date
[ ] Expiration date (if applicable)
```

---

## Customer/Patient Data Retention

- ID verification records: 7 years minimum (NJ CRC 17:30-14)
- Purchase records: 7 years (NJ tax compliance)
- Audit logs: 7 years
- Video surveillance: 90 days minimum (then auto-delete per retention policy)
- GDPR/CCPA delete requests: anonymize PII columns (set to NULL/placeholder); retain transaction records for 7-year statutory period; log deletion event in audit_log

---

## Phase 6: Deployment

### Dockerfile
```dockerfile
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .

FROM base AS runner
ENV NODE_ENV=production
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

### GitHub Actions CI/CD
```yaml
name: Deploy NJ Cannabis Delivery Platform
on:
  push:
    branches: [main]
jobs:
  compliance-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npm run test:compliance   # runs geofence, age-verify, weight-limit unit tests
      - run: npm run test:metrc-sync   # integration test against METRC sandbox

  deploy:
    needs: compliance-check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
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

## Compliance Monitoring Calendar

| Frequency | Task |
|---|---|
| Real-time | METRC inventory update on every sale/adjustment |
| Within 24h | METRC sync after any inventory change (N.J.A.C. 17:30-7) |
| Daily midnight | End-of-day reconciliation: local vs METRC quantities |
| Daily midnight | Daily manifest report generation and archival |
| Daily | Cash reconciliation report (dual-control sign-off required) |
| Weekly | Driver badge expiry check (alert if <30 days) |
| Weekly | Vehicle registration/insurance expiry check |
| Weekly | Lab result sweep (quarantine any newly failed packages) |
| Monthly | Purchase limit audit (sample 10% of orders, verify limits enforced) |
| Monthly | Age verification log review (spot-check denied + approved) |
| Quarterly | NJ CRC compliance report submission |
| Quarterly | Social equity metrics report |
| Annually | License renewal (track in `corporations.license_expiry`) |
| Annually | Insurance policy renewal verification |

---

## Quality Gate

Before any release or compliance submission, ALL must pass:

- [ ] METRC sync runs within 24 hours of any inventory change
- [ ] All sales reported to METRC within required window post-delivery
- [ ] Age verification logged with result, confidence score, and timestamp for every attempt
- [ ] Age verification fail-closed: OCR confidence < 90% = DENY (verified in unit tests)
- [ ] Delivery manifest status updated at every state change (generated → departed → at_stop → closed)
- [ ] Zero inventory discrepancy tolerated: reconciliation alert fires on any mismatch > 0.01g
- [ ] COA accessible (coa_url populated) for every product before listing
- [ ] Failed lab results quarantined automatically (is_quarantined=TRUE, is_compliant=FALSE)
- [ ] All PII encrypted at rest (AES-256 / AWS KMS)
- [ ] `app_role` has no UPDATE/DELETE on `audit_log` or `age_verification_log`
- [ ] Municipality opt-in check runs server-side before order acceptance
- [ ] Geofence check runs server-side — client-side display only
- [ ] Daily compliance reports generated and archived automatically
- [ ] METRC sandbox integration tests pass in CI before every production deploy

---

## Module Selection

Tell me which phase to implement or expand:
1. Legal checklist and entity formation docs
2. Database schema + PostGIS setup + role grants
3. Compliance middleware (age / weight / geofence / interceptor)
4. METRC API integration + manifest generation + sale receipt
5. Dutchie/Treez POS sync worker
6. Access control matrix implementation
7. Lab result quarantine flow
8. Driver dispatch and route optimization
9. Full deployment pipeline + compliance CI tests
10. Compliance monitoring calendar automation
