# Audit Report: M2-B1 (Resume Parsing & DPDP Consent)

- **Target Branch**: `m2/b1-resume-parsing`
- **Base Branch**: `origin/main`
- **Role**: `m2` (@Tanushyadav9)
- **Prompt ID**: `M2-B1`
- **Audit Date**: 2026-10-18T01:14:00+05:30
- **Auditor**: M1 (Antigravity pair programmer)

---

## 1. Scope Verification

**Requirement**: List all files changed against `origin/main`. Fail any file outside the folders `m2` owns in `scripts/ownership.yml`.

### Execution
```powershell
$ python scripts/check_scope.py --member m2 --ci --pr-base origin/main
[SCOPE GUARD] OK: All 12 file(s) are within scope for 'm2'.
```

### Files Changed (12 files)
1. `backend/app/modules/resume/data/skills_taxonomy.csv`
2. `backend/app/modules/resume/extractor.py`
3. `backend/app/modules/resume/migrations/versions/0001_resume_base.py`
4. `backend/app/modules/resume/models.py`
5. `backend/app/modules/resume/module.py`
6. `backend/app/modules/resume/parser.py`
7. `backend/app/modules/resume/router.py`
8. `backend/app/modules/resume/schemas.py`
9. `backend/app/modules/resume/service.py`
10. `backend/app/modules/resume/storage.py`
11. `backend/app/modules/resume/tests/test_resume.py`
12. `contracts/modules/resume.yaml`

All 12 files fall strictly within `backend/app/modules/resume/**` and `contracts/modules/resume.yaml`.

* **Result**: **PASS**

---

## 2. Secrets and Private Data

**Requirement**: Scan diff and commit history for `.env` files, API keys, tokens, private keys, and real CSVs under `data/`.

### Execution
```powershell
$ git diff origin/main...m2/b1-resume-parsing | Select-String -Pattern "(?i)(api[_-]?key|secret|password|bearer|private[_-]?key)"
+    api_key = settings.GEMINI_API_KEY
+    if not api_key or api_key == "your_gemini_api_key_here":
+    url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.GEMINI_TEXT_MODEL}:generateContent?key={api_key}"
+    api_key = settings.GEMINI_API_KEY
+    if not api_key or api_key == "your_gemini_api_key_here":
+    url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.GEMINI_EMBED_MODEL}:embedContent?key={api_key}"
+    if auth_header and auth_header.startswith("Bearer "):
```

### Analysis
- No hardcoded secrets, API tokens, or private keys detected (configuration is loaded dynamically from `settings.GEMINI_API_KEY`).
- No `.env` files exist in the branch commit.
- The only CSV added is `backend/app/modules/resume/data/skills_taxonomy.csv`, which is standard public skill taxonomy reference data (Python, JavaScript, etc.), not personal data or unapproved root `data/*.csv`.

* **Result**: **PASS**

---

## 3. Test Suite & Code Quality

**Requirement**: Run test suite for owned modules with real Postgres and Redis; run linters.

### Execution: Pytest
```text
$ docker compose exec api pytest app/modules/resume/tests/test_resume.py -v
app/modules/resume/tests/test_resume.py::test_resume_upload_refused_without_consent FAILED
app/modules/resume/tests/test_resume.py::test_consents_flow_grant_and_retrieve FAILED
app/modules/resume/tests/test_resume.py::test_magic_byte_validation_rejects_fake_files FAILED
app/modules/resume/tests/test_resume.py::test_scanned_image_only_pdf_returns_resume_unreadable FAILED
app/modules/resume/tests/test_resume.py::test_resume_upload_parsing_and_profile_retrieval FAILED
app/modules/resume/tests/test_resume.py::test_prompt_injection_in_resume_text FAILED
app/modules/resume/tests/test_resume.py::test_profile_update_and_re_embedding FAILED
app/modules/resume/tests/test_resume.py::test_intent_lifecycle FAILED
app/modules/resume/tests/test_resume.py::test_delete_resume_and_consent_withdrawal FAILED
============================== 9 failed in 7.81s ===============================
```

### Analysis of Test Failures
1. **Route Mount Failure (404)**: FastAPI requires `python-multipart` for `File(...)` and `UploadFile` dependencies in `POST /resume`. Because `python-multipart` is omitted from dependencies in `backend/pyproject.toml`, FastAPI raises an import error on startup, causing `backend/app/main.py` auto-discovery to fail with:
   `Warning: Failed to load module 'resume': Form data requires "python-multipart" to be installed.`
2. **Missing Database Tables**: The module migration was placed at `backend/app/modules/resume/migrations/versions/0001_resume_base.py` instead of `backend/app/modules/resume/migrations/0001_resume_base.py`. `alembic.ini` only scans `app/modules/resume/migrations`, so Alembic does not discover or run the migration.
3. **Legacy Stub Test Left Behind**: `backend/app/modules/resume/tests/test_router.py` still contains the obsolete scaffold test `test_resume_endpoints_return_501`.

### Execution: Ruff Linter
```text
$ ruff check app/modules/resume
Found 136 errors.
[*] 94 fixable with the `--fix` option.
```
Contains 136 lint violations across deprecated typing annotations (`List`, `Dict`, `Optional`), unsorted imports, and blind exception handlers (`except Exception: pass`).

* **Result**: **FAIL**

---

## 4. Contract Conformance

**Requirement**: Verify every endpoint in `PROJECT_CONTEXT.md` section 7 is implemented and matches `contracts/modules/resume.yaml`.

### Endpoint Audit Table
| Endpoint | Method | Contract Schema | Live Server Status | Result |
| :--- | :--- | :--- | :--- | :--- |
| `/resume` | POST | `ResumeUploadResponse` | `HTTP/1.1 404 Not Found` | **FAIL** |
| `/resume` | DELETE | `204 No Content` | `HTTP/1.1 404 Not Found` | **FAIL** |
| `/resume/profile` | GET | `StudentProfileResponse` | `HTTP/1.1 404 Not Found` | **FAIL** |
| `/resume/profile` | PUT | `StudentProfileResponse` | `HTTP/1.1 404 Not Found` | **FAIL** |
| `/me/intent` | GET | `StudentIntentResponse` | `HTTP/1.1 404 Not Found` | **FAIL** |
| `/me/intent` | PUT | `StudentIntentResponse` | `HTTP/1.1 404 Not Found` | **FAIL** |
| `/me/consents` | GET | `ConsentsListResponse` | `HTTP/1.1 404 Not Found` | **FAIL** |
| `/me/consents` | PUT | `ConsentsListResponse` | `HTTP/1.1 404 Not Found` | **FAIL** |

### Execution Excerpt
```powershell
$ curl.exe -i -s http://localhost:8000/me/consents
HTTP/1.1 404 Not Found
content-type: application/json

{"detail":"Not Found"}

$ curl.exe -i -s -X POST http://localhost:8000/resume
HTTP/1.1 404 Not Found
content-type: application/json

{"detail":"Not Found"}
```
All 8 endpoints return 404 because the module router fails to mount due to the missing `python-multipart` dependency.

* **Result**: **FAIL**

---

## 5. Architectural Rules & Engineering Principles

**Requirement**: Grep for mock data/silent fallbacks, cross-module imports, permissive ports, unpaginated lists, and missing idempotency keys.

### 5.1 Cross-Module Imports
```powershell
$ git grep "app\.modules\." backend/app/modules/resume/
```
Output confirms all imports reference strictly internal `app.modules.resume.*` components. Zero cross-module imports detected.
* **Status**: **PASS**

### 5.2 Mock Data & Silent Fallbacks (Rule 19 Violation)
`PROJECT_CONTEXT.md` Rule 19 states: *"No mock or demo data, no silent fallback to fake data. If an external service fails, return a typed error."*
In `backend/app/modules/resume/parser.py`:
- **Line 153-155**: `if not api_key or api_key == "your_gemini_api_key_here": return _fallback_heuristic_parse(user_content)`
- **Line 221-222**: `if not api_key or api_key == "your_gemini_api_key_here": return _deterministic_dummy_vector(text)`
- **Line 237-240**: `except Exception: pass; return _deterministic_dummy_vector(text)`
This silently falls back to synthetic heuristic skills and pseudo-random dummy vectors rather than raising a typed `AppError(code="ai_unavailable")`.
* **Status**: **FAIL**

### 5.3 Idempotency Key Handling (Rule 24 Violation)
`PROJECT_CONTEXT.md` Rule 24 states: *"Every write that can be retried accepts an Idempotency-Key."*
```powershell
$ git grep -i "idempotency" backend/app/modules/resume/
# (Empty output)
```
None of the write endpoints (`POST /resume`, `PUT /resume/profile`, `PUT /me/intent`, `PUT /me/consents`) accept or validate the `Idempotency-Key` header.
* **Status**: **FAIL**

### 5.4 List Cursor Pagination (Rule 24)
`GET /me/consents` returns `{ "items": [...] }` without cursor pagination metadata (`next_cursor`). While consent records are naturally bounded, it diverges from the monorepo standard pagination format `{ items, next_cursor }`.
* **Status**: **FAIL (Warning)**

### 5.5 Port Fail-Closed
`resume` does not implement or register ports (the `MatchingPort.explain` port belongs to module `matching`).
* **Status**: **PASS**

---

## 6. Prompt Acceptance Criteria & Feature Completeness

| Requirement | Implementation Details | Status |
| :--- | :--- | :--- |
| **Magic Byte Validation** | Validates `%PDF-` and `PK\x03\x04` with `word/document.xml` in `extractor.py` | Complete |
| **Size & Page Limits** | Rejects files > 5 MB (`file_too_large`) and > 5 pages (`page_limit_exceeded`) | Complete |
| **Scanned Image Detection** | Rejects resumes with < 50 extractable characters as `resume_unreadable` (422) | Complete |
| **DPDP Consent Gate** | Blocks resume upload with 403 `consent_required` if `resume_processing` is not granted | Complete |
| **DPDP Consent Withdrawal** | Automatically purges stored resume files, parsed data, and embeddings upon withdrawal | Complete |
| **Skill Normalization** | Matches against `skills_taxonomy.csv` case-insensitively with alias support | Complete |
| **Outbox Events** | Publishes `resume.parsed` and `profile.updated` events with valid schemas | Complete |
| **Runtime Dependencies** | Missing `python-multipart` causes FastAPI startup failure | **Incomplete** |
| **Database Migration Discovery** | Migration nested under `versions/` subdirectory is skipped by Alembic | **Incomplete** |
| **Error Handling on AI Outage** | Silently falls back to dummy vectors rather than returning typed 503 errors | **Incomplete** |

* **Result**: **FAIL**

---

## 7. Commit History & Identity

**Requirement**: Every commit must use `type(scope): summary` and be authored by the designated member.

### Execution
```powershell
$ git log origin/main..m2/b1-resume-parsing --format='%an <%ae> %s'
Tanush Yadav <Tanushyadav9@users.noreply.github.com> feat(resume): parse uploaded PDF into structured profile with embeddings and DPDP consent
```

* **Author**: `Tanush Yadav <Tanushyadav9@users.noreply.github.com>` matches M2 (@Tanushyadav9).
* **Format**: Conventional commit format `feat(resume): parse uploaded PDF into structured profile with embeddings and DPDP consent` followed.

* **Result**: **PASS**

---

## Overall Audit Summary Table

| Category | Check | Status | Notes |
| :--- | :--- | :--- | :--- |
| **1. Scope** | File changes within owned directories | **PASS** | All 12 files within `backend/app/modules/resume/**` and `contracts/modules/resume.yaml` |
| **2. Secrets** | No leaked API keys, tokens, or private data | **PASS** | Clean diff; public taxonomy CSV only |
| **3. Tests** | Module test suite execution & linter | **FAIL** | 9/9 pytest tests fail; 136 ruff lint errors |
| **4. Contracts** | Endpoints live and match schema | **FAIL** | All 8 endpoints return 404 due to startup import error |
| **5. Rules** | Idempotency, no mock fallbacks, isolation | **FAIL** | Missing `Idempotency-Key`; silent fallback dummy vector |
| **6. Brief Fit** | Prompt acceptance criteria fulfillment | **FAIL** | Good domain logic, blocked by migration and dependency bugs |
| **7. Commits** | Conventional commits & member identity | **PASS** | Authored by @Tanushyadav9 with conventional commit title |

---

## Prioritised Action Items for M2

1. **Add `python-multipart` to Dependencies**:
   * Request M1 to add `python-multipart>=0.0.9` to `backend/pyproject.toml` so `UploadFile` does not break router discovery.
2. **Move Migration File**:
   * Move `backend/app/modules/resume/migrations/versions/0001_resume_base.py` to `backend/app/modules/resume/migrations/0001_resume_base.py` so Alembic discovers and applies it under the `resume` branch.
3. **Remove Silent Mock Fallback**:
   * In `backend/app/modules/resume/parser.py`, remove `_fallback_heuristic_parse` and `_deterministic_dummy_vector` fallback on `except Exception: pass`. Instead, raise `AppError(code="ai_unavailable", status_code=503)`.
4. **Implement Idempotency-Key Handling**:
   * Add `idempotency_key: Optional[str] = Header(None, alias="Idempotency-Key")` to `POST /resume`, `PUT /resume/profile`, `PUT /me/intent`, and `PUT /me/consents`.
5. **Delete Stale Stub Test**:
   * Remove `test_resume_endpoints_return_501` from `backend/app/modules/resume/tests/test_router.py`.
6. **Fix Ruff Lint Violations**:
   * Run `ruff check app/modules/resume --fix` to clean up the 136 lint errors.
