"""
scripts/file_issues.py - Automatically file issues to M2, M3, and M4 for contract & port implementation.
"""

import subprocess

issues = [
    {
        "title": "[needs:m2] Implement Resume Extraction and Matching Service endpoints",
        "labels": ["needs:m2", "bug"],
        "body": """### Summary
Contract testing and wire-up verification from integration phase identified that Member 2's modules (Resume and Matching) currently return HTTP 501 `ModuleNotImplemented`.

### Affected Endpoints
- `POST /resume`
- `GET /resume/profile`
- `PUT /resume/profile`
- `DELETE /resume`
- `PUT /me/intent`
- `GET /me/intent`
- `GET /me/consents`
- `PUT /me/consents`
- `GET /recommendations`
- `GET /givers/{id}`
- `PUT /me/giver-profile`
- `GET /me/giver-profile`

### Missing Port Registration
- `MatchingPort.explain(student_id, giver_id)` is left as `pass` in `backend/app/modules/matching/module.py`.

### Reproduction
```bash
curl -X POST http://localhost:8000/resume
# Output: HTTP 501 {"error": {"code": "module_not_implemented", "message": "Endpoint /resume is not implemented yet.", "details": {}}}
```
""",
    },
    {
        "title": "[needs:m3] Implement Availability, Sessions, and Ratings modules",
        "labels": ["needs:m3", "bug"],
        "body": """### Summary
Contract testing and wire-up verification from integration phase identified that Member 3's modules (Availability, Sessions, and Ratings) currently return HTTP 501 `ModuleNotImplemented`.

### Affected Endpoints
- `PUT /me/availability`, `GET /me/availability`
- `POST /me/online`, `DELETE /me/online`
- `GET /presence`, `WS /ws`
- `POST /requests`, `GET /requests`, `GET /requests/{id}`, `POST /requests/{id}/accept`, `POST /requests/{id}/decline`
- `GET /givers/{id}/slots`
- `POST /requests/{id}/messages`, `GET /requests/{id}/messages`
- `POST /sessions/{id}/join`, `POST /sessions/{id}/leave`, `GET /sessions/{id}`, `GET /me/sessions`
- `POST /notifications/devices`
- `POST /sessions/{id}/rating`, `POST /sessions/{id}/request-quality`, `POST /sessions/{id}/dispute`
- `GET /givers/{id}/rating-summary`, `GET /me/band`, `GET /admin/disputes`, `POST /admin/disputes/{id}/resolve`

### Missing Port Registrations
- `RatingsPort.get_band(giver_id)` is left as `pass` in `backend/app/modules/ratings/module.py`.
- `PresencePort.status(user_ids)` is left as `pass` in `backend/app/modules/availability/module.py`.

### Reproduction
```bash
curl -X POST http://localhost:8000/requests
# Output: HTTP 501 {"error": {"code": "module_not_implemented", "message": "Endpoint /requests is not implemented yet.", "details": {}}}
```
""",
    },
    {
        "title": "[needs:m4] Implement Credits, Payments, and Institution Dashboard modules",
        "labels": ["needs:m4", "bug"],
        "body": """### Summary
Contract testing and wire-up verification from integration phase identified that Member 4's modules (Credits, Payments, and Institution) currently return HTTP 501 `ModuleNotImplemented`.

### Affected Endpoints
- `GET /plans`, `GET /me/subscription`, `GET /me/wallet`, `GET /me/earnings`
- `POST /me/cashout`, `POST /me/donate-credits`
- `GET /sponsored-seats`, `POST /admin/sponsored-seats`
- `POST /subscriptions`, `POST /subscriptions/cancel`, `POST /webhooks/razorpay`
- `GET /admin/dashboard/overview`, `GET /admin/dashboard/skill-gap`, `GET /admin/dashboard/safety-summary`, `GET /admin/dashboard/seats`

### Missing Port Registration
- `CreditsPort` (can_access, reserve, release, refund) is left as `pass` in `backend/app/modules/credits/module.py`.

### Reproduction
```bash
curl -X GET http://localhost:8000/plans
# Output: HTTP 501 {"error": {"code": "module_not_implemented", "message": "Endpoint /plans is not implemented yet.", "details": {}}}
```
""",
    },
]


def file_issues():
    for issue in issues:
        cmd = [
            "gh",
            "issue",
            "create",
            "--repo",
            "AnmolGarg8/WarmPath",
            "--title",
            issue["title"],
            "--body",
            issue["body"],
        ]
        for label in issue["labels"]:
            cmd.extend(["--label", label])

        print(f"Creating issue: {issue['title']}...")
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0:
            print(f"  Created: {res.stdout.strip()}")
        else:
            print(f"  Failed: {res.stderr.strip()}")


if __name__ == "__main__":
    file_issues()
