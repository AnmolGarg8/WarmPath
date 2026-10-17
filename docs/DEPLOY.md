# WarmPath Production Deployment Guide

This guide provides the complete, step-by-step production deployment instructions for WarmPath, covering container builds, managed PostgreSQL with `pgvector`, managed Redis, secrets management, database migrations, CORS security, monitoring, the static admin portal, and the mobile APK release build.

---

## 1. Production Architecture Topology

```
                  +----------------------------------+
                  |           DNS & CDN              |
                  |     (Cloudflare / Route 53)      |
                  +-----------------+----------------+
                                    |
            +-----------------------+-----------------------+
            |                                               |
  https://admin.warmpath.org                      https://api.warmpath.org
            |                                               |
+-----------v------------+                      +-----------v------------+
|  Static Hosting / S3   |                      | Managed Container App  |
|  (React Admin Portal)  |                      | (FastAPI API Service)  |
+------------------------+                      +-----------+------------+
                                                            |
                  +-----------------------------------------+
                  |
        +---------v-----------+                  +----------v-----------+
        | Managed PostgreSQL  |                  |    Managed Redis     |
        |  (pgvector enabled) |                  | (Presence & Queues)  |
        +---------------------+                  +----------+-----------+
                                                            |
                                                +-----------v------------+
                                                | Background Container   |
                                                |   (ARQ Event Worker)   |
                                                +------------------------+
```

---

## 2. Container Images

### Multi-Stage Production Container (`backend/Dockerfile.prod`)
WarmPath uses a hardened, multi-stage Docker build targeting Python 3.12:
- **Builder Stage**: Installs `build-essential` and `libpq-dev` to compile C extensions into an isolated virtualenv (`/opt/venv`).
- **Runtime Stage**: Contains only minimal runtime shared libraries (`libpq5`, `curl`).
- **Security**: Runs under an unprivileged non-root user `warmpath:warmpath` (UID 10001).

### Building the Image
```bash
# Build the production API and Worker image
docker build -t warmpath-backend:prod -f backend/Dockerfile.prod backend/

# Test running the container locally
docker run -p 8000:8000 \
  -e DATABASE_URL="postgresql+asyncpg://warmpath:secretpassword@host.docker.internal:5432/warmpath_db" \
  -e REDIS_URL="redis://host.docker.internal:6379/0" \
  -e ENVIRONMENT="production" \
  warmpath-backend:prod
```

### Running the Worker Image
The worker container uses the exact same production image, overriding the command:
```bash
docker run \
  -e DATABASE_URL="..." \
  -e REDIS_URL="..." \
  warmpath-backend:prod python -m app.core.worker
```

---

## 3. Managed Infrastructure Setup

### A. Managed PostgreSQL (with `pgvector`)
WarmPath requires PostgreSQL 16+ with the `vector` (pgvector) and `pg_trgm` extensions enabled.

**Supported Platforms**:
- **AWS RDS PostgreSQL**: Select PostgreSQL 16. Ensure `pgvector` extension is permitted in parameter group.
- **Google Cloud SQL**: Create a PostgreSQL 16 instance. Enable the `cloudsql.enable_pgvector` flag.
- **Supabase / Neon**: `pgvector` is enabled out of the box.

**Database Initialization**:
Connect to the database as superuser and execute:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### B. Managed Redis
- Deploy a Redis 7+ cluster or standalone instance (AWS ElastiCache, GCP Memorystore, or Redis Cloud).
- Configure memory eviction policy: `volatile-lru` or `noeviction` (WarmPath uses explicit TTLs on presence keys and ARQ queues).

---

## 4. Platform Secret Store & Environment Variables

Configure the following secrets in your platform secret store (AWS Secrets Manager, GCP Secret Manager, or platform environment settings):

| Variable | Description | Example / Note |
| :--- | :--- | :--- |
| `DATABASE_URL` | Asyncpg PostgreSQL connection string | `postgresql+asyncpg://user:pass@host:5432/warmpath_db` |
| `REDIS_URL` | Redis connection URL | `rediss://default:token@host:6379/0` (SSL enabled) |
| `JWT_SECRET` | 256-bit secret for user auth tokens | Generate via `openssl rand -hex 32` |
| `APP_SECRET_KEY` | Application-level encryption key | Generate via `openssl rand -hex 32` |
| `ENVIRONMENT` | Target environment mode | `production` |
| `PORT` | Container HTTP listen port | `8000` |
| `ADMIN_CORS_ORIGIN` | Allowed CORS origin for admin | `https://admin.warmpath.org` |
| `GEMINI_API_KEY` | Google AI Studio / Gemini API key | Extracted skills & safety scan |
| `GEMINI_TEXT_MODEL` | Gemini LLM model | `gemini-1.5-flash` |
| `GEMINI_EMBED_MODEL`| Gemini embedding model | `text-embedding-004` |
| `RAZORPAY_KEY_ID` | Razorpay test key ID | Starts with `rzp_test_...` |
| `RAZORPAY_KEY_SECRET` | Razorpay test secret key | Test mode only |
| `RAZORPAY_WEBHOOK_SECRET` | Webhook verification secret | Verified on `/webhooks/razorpay` |
| `SMTP_HOST` | Production SMTP hostname | e.g., `smtp.sendgrid.net` |
| `SMTP_PORT` | SMTP port | `587` |
| `SMTP_USER` | SMTP username | `apikey` |
| `SMTP_PASSWORD` | SMTP password / token | Secure token |
| `SMTP_FROM` | Outgoing email address | `no-reply@warmpath.org` |
| `JITSI_BASE_URL` | Video conference instance | `https://meet.jit.si` |

---

## 5. Deployment Step-by-Step

### Step 1: Pre-Deployment Migration (`alembic upgrade heads`)
Never run raw migrations directly on live instances without a release step.
In your deployment pipeline (e.g., Render Pre-Deploy Command, Cloud Run Job, or ECS Task):
```bash
# Execute release migrations across all module branches
alembic upgrade heads
```

### Step 2: Seed Institutions & Skills Taxonomy
```bash
# Seed standard institutions and skills taxonomy idempotently
python scripts/deploy/seed_data.py
```

### Step 3: Create the First Platform Administrator
```bash
# Protected script to bootstrap the platform admin
python scripts/deploy/create_admin.py --email admin@vips.edu --name "Platform Lead" --institution "VIPS-TC"
```

### Step 4: Deploy API & Worker Services
- **API Service**: Configure 2+ replicas with horizontal auto-scaling (CPU > 70%).
- **Worker Service**: Configure 1-2 worker instances running `python -m app.core.worker`.

---

## 6. Probes, Security & Observability

### Health & Readiness Probes
- **Liveness Probe**: `GET /healthz` (Returns `200 {"status":"ok"}`). Used to restart stalled containers.
- **Readiness Probe**: `GET /readyz` (Verifies live connection to both PostgreSQL and Redis. Returns `200` when ready, `503` when degraded).

### CORS Policy
In production, CORS is strictly bound to the Admin frontend:
```python
# In backend/app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.getenv("ADMIN_CORS_ORIGIN", "https://admin.warmpath.org")],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)
```

### Structured Logging & Metrics
- All backend logs are output as single-line JSON via `structlog`.
- Every incoming request receives a unique `X-Request-ID` attached to response headers and log context.

---

## 7. Admin Portal Static Deployment

The React Vite admin portal (`admin/`) is compiled as a static single-page application (SPA).

### Build Command
```bash
cd admin
npm install --frozen-lockfile
VITE_API_URL="https://api.warmpath.org" npm run build
```
This generates production assets in `admin/dist/`.

### Hosting Options
- **Vercel / Cloudflare Pages / Netlify**:
  - Root directory: `admin`
  - Build command: `npm run build`
  - Output directory: `dist`
  - Environment variable: `VITE_API_URL=https://api.warmpath.org`
  - Ensure SPA rewrite rule: `/* -> /index.html`.

---

## 8. Mobile App Release Build (Flutter APK)

### Prerequisites
- Flutter 3.19+ SDK
- Android SDK with command-line tools

### Keystore Configuration
Create a production keystore (if not already generated):
```bash
keytool -genkey -v -keystore warmpath-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias warmpath
```
Configure `app/android/key.properties` with keystore credentials.

### Release Build Command
Compile the release APK with the production API URL injected via compile-time define:
```bash
cd app
flutter build apk --release --dart-define=API_BASE_URL=https://api.warmpath.org
```

### Installation on Real Hardware
The compiled release artifact is generated at:
```
app/build/app/outputs/flutter-apk/app-release.apk
```
Install directly onto a physical Android device:
```bash
adb install -r app/build/app/outputs/flutter-apk/app-release.apk
```
