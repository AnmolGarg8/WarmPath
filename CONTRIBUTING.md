# Contributing to WarmPath

Welcome to WarmPath! To allow four developers to work rapidly in parallel without merge collisions, our team follows a strict zero-collision modular workflow.

---

## 1. Zero-Collision Rules

1. **One Owner Per Folder:** Every file has exactly one designated role owner. Never edit files outside your assigned module paths without prior coordination and an issue tracker entry.
2. **One Branch Per Task, One Pusher Per Branch:** Always create a dedicated branch for your prompt/task. Never push directly to `main`.
3. **Shared Files Are Frozen:** Dependencies (`pyproject.toml`, `pubspec.yaml`, `package.json`), routing registries, and core database tables are pre-wired. Modules self-register through automated discovery.
4. **Scope Guard Pre-Commit Hook:** A pre-commit hook verifies that your staged changes only modify paths within your assigned ownership scope.

---

## 2. Daily Workflow for Every Member

### Step 1: Set Your Identity (Run Once)
Use the email address linked to your GitHub account so commits are properly credited to your profile:
```bash
git config user.name "Your Real Name"
git config user.email "your-github-linked-email@example.com"
git config warmpath.member m1        # Replace with your role: m1, m2, m3, or m4
pre-commit install                   # Installs the pre-commit scope guard
```

### Step 2: Start a Task on a Fresh Branch
```bash
git switch main && git pull --ff-only
git switch -c <role>/<short-task-name>
# Example: git switch -c m2/b1-resume-parsing
```

### Step 3: Work in Small, Focused Commits
Stage only your owned folders (never run `git add .` from root):
```bash
git add backend/app/modules/resume contracts/modules/resume.yaml
git commit -m "feat(resume): parse uploaded PDF into structured profile"
```
Follow Conventional Commits: `type(scope): summary` (types: `feat`, `fix`, `test`, `docs`, `refactor`, `chore`).

### Step 4: Rebase and Push
Always rebase on the latest `main` before pushing:
```bash
git fetch origin && git rebase origin/main
git push -u origin HEAD
```
If a push is rejected: run `git pull --rebase origin <your-branch>` and push again. Use `--force-with-lease` only on your personal feature branch after a rebase. **Never force-push `main`.**

### Step 5: Open a Pull Request
Open a PR with the template filled out:
```bash
gh pr create --fill
```
- Request a review from your review pair:
  - **M1** reviews **M2**
  - **M2** reviews **M3**
  - **M3** reviews **M4**
  - **M4** reviews **M1**
- Merge strategy: **Rebase and merge only**. Keep linear commit history and author attribution.
- After merging:
  ```bash
  git switch main && git pull --ff-only && git branch -d <branch>
  ```

---

## 3. Requesting Changes to Another Module
If you need functionality or an alteration in another member's module:
1. Do **not** edit their files directly.
2. Open a GitHub Issue labelled `needs:<role>` (e.g. `needs:m3`) detailing the port or contract change needed.

---

## 4. Contributor Audit
Before reporting to judges or at the end of each sprint, run:
```bash
bash scripts/contrib-report.sh
```
This prints the commit count, lines added/removed, and folder distribution per author.
