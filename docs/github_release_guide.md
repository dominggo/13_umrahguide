# GitHub Versioning & Release Guide
## For: Panduan Umrah — Solo Developer, First-Time GitHub User

---

## Section 1: Core Concepts (Plain English)

| Term | What it means |
|------|--------------|
| **Commit** | A saved snapshot of your code at a point in time — like "Save As" with a message describing what changed |
| **Push** | Upload your local commits to GitHub (cloud backup / public repo) |
| **Pull** | Download changes from GitHub to your local machine (less relevant for solo projects) |
| **Branch** | A parallel copy of the code you can work on without affecting the main line |
| **Tag** | A permanent label stuck to one specific commit — e.g. `v1.1.0` never moves |
| **Release** | A GitHub page tied to a tag; where you attach the APK/AAB for people to download |
| **Fork** | A copy of someone ELSE's repo into your account — NOT needed for your own project |

---

## Section 2: Semantic Versioning for Flutter

Version format in `pubspec.yaml`:

```yaml
version: MAJOR.MINOR.PATCH+BUILD
```

| Part | When to bump | Example |
|------|-------------|---------|
| **MAJOR** | Complete rewrite / breaking redesign (rare) | `1.x.x` → `2.0.0` |
| **MINOR** | New feature added | `1.1.0` → `1.2.0` |
| **PATCH** | Bug fix only, no new features | `1.1.0` → `1.1.1` |
| **BUILD** | Must ALWAYS increase every Play Store submission | `+2` → `+3` |

Example progression:

```
1.0.0+1  →  1.1.0+2  →  1.1.1+3  →  1.2.0+4  →  2.0.0+5
 launch     new feat    bug fix     new feat    full rewrite
```

> **Play Store rule:** The build number (`+N`) must always increase, even across major versions.
> It must NEVER reset to 1. Play Store rejects uploads with a lower or equal build number.

---

## Section 3: Branching Strategy (Recommended for Solo Dev)

### Small fixes / tweaks
Commit directly to `master`. No branch needed.

```bash
git add .
git commit -m "fix: checkpoint dialog not closing on back press"
git push origin master
```

### New feature that takes days
Create a feature branch so `master` stays stable:

```bash
git checkout -b feat/tawaf-counter   # create and switch to new branch
# ... work on it over several days ...
git checkout master                  # switch back to master
git merge feat/tawaf-counter         # bring the work in
git branch -d feat/tawaf-counter     # delete branch (clean up)
git push origin master
```

### Urgent hotfix on an already-released version
Create a hotfix branch from the release tag:

```bash
git checkout v1.1.0                  # go back to the released state
git checkout -b hotfix/crash-fix
# ... fix the bug ...
git checkout master
git merge hotfix/crash-fix
git branch -d hotfix/crash-fix
```

### Rule of thumb
- Fix takes < 1 day → commit directly to `master`
- Feature takes > 1 day → use a branch

---

## Section 4: When to Commit

**Commit after each logical unit of work:**
- "Finished the checkpoint dialog UI"
- "Added PDF export feature"
- "Fixed crash when GPS is off"

**Also commit:**
- Before switching to a different task
- Before testing a risky change (so you can revert if it breaks)

**Do NOT:**
- Make one giant commit at end of day mixing 10 unrelated changes
- Commit broken/non-compiling code to master

### Commit message convention

```
feat:      new feature added
fix:       bug fixed
docs:      documentation only (no code change)
refactor:  code restructured, behaviour unchanged
chore:     version bump, dependency update, build config
```

Examples:
```
feat: add 17-checkpoint GPS recording system
fix: doa audio not pausing on screen lock
docs: add Play Store description in BM
chore: bump version to 1.2.0+3
```

---

## Section 5: Full Release Flow (Step by Step)

### How commits + tags work together

```
master branch timeline:
─────────────────────────────────────────────────────────────────▶

 [tag: v1.1.0]                                        [tag: v1.2.0]
     │                                                      │
     ▼                                                      ▼
  commit A ── commit B ── commit C ── commit D ── commit E ── commit F
  (chore:     (feat:       (feat:      (fix:       (fix:       (chore:
   v1.1.0)     new UI)      GPS)        crash)      typo)       v1.2.0)

  ◀──── already released as v1.1.0 ────▶◀─── work for v1.2.0 ───▶
```

**Key insight:**
- You code normally, committing after each feature/fix (commits B, C, D, E above)
- The TAG is the demarcation — everything between the two tags is "v1.2.0 work"
- You only bump `pubspec.yaml` version at the very end (commit F), right before tagging
- No separate branch needed — tags on master are sufficient for a solo project

---

### Step-by-step release checklist

```
DURING DEVELOPMENT (can take days or weeks):
  ✔ Code normally — commit after each feature/fix
  ✔ Use descriptive commit messages (feat:, fix:, etc.)
  ✔ Push to GitHub regularly (daily, or after important commits)
  ✔ Keep `flutter analyze` at 0 issues


WHEN READY TO RELEASE:

  Step 1: Final test on real device
          Confirm everything works as expected.
          Run: flutter analyze
          Fix any issues before proceeding.

  Step 2: Bump version in pubspec.yaml
          Open pubspec.yaml and change the version line:

          version: 1.1.0+2  →  version: 1.2.0+3

          Rules:
          - MINOR bump (x.Y.0) if new features were added
          - PATCH bump (x.x.Z) if bug fixes only
          - BUILD number (+N) always increases by 1

  Step 3: Commit the version bump
          git add pubspec.yaml
          git commit -m "chore: bump version to 1.2.0+3"

  Step 4: Build the release files
          flutter build appbundle --release   ← AAB for Play Store
          flutter build apk --release         ← APK for direct sharing

          Output locations:
          AAB: build/app/outputs/bundle/release/app-release.aab
          APK: build/app/outputs/flutter-apk/app-release.apk

  Step 5: Push to GitHub
          git push origin master

  Step 6: Create a version tag on that commit
          git tag v1.2.0
          git push origin v1.2.0

          This tag permanently marks this commit as v1.2.0.
          It will never move, even as you add more commits later.

  Step 7: Create a GitHub Release
          1. Go to: github.com/dominggo/13_umrahguide/releases
          2. Click "Draft a new release"
          3. Choose tag: v1.2.0 (select from dropdown)
          4. Title: "v1.2.0 — Short description of what's new"
          5. Write release notes:
             - What's new
             - What's fixed
             - Any known issues
          6. Attach files:
             - app-release.apk  (so people can sideload)
             - app-release.aab  (archive/reference copy)
          7. Click "Publish release" ✅

          This is what people see when they visit your releases page.

  Step 8: Upload to Play Console (if submitting to Play Store)
          1. Play Console → Your app → Testing → Internal testing
          2. Create new release
          3. Upload app-release.aab
          4. Paste release notes from GitHub
          5. Save → Roll out to internal testers ✅
```

---

## Section 6: FAQ

**Should I fork my own repo?**
No. Forking is for contributing to OTHER people's repos. You own this repo — just clone it directly.

**Should I delete old feature branches after merging?**
Yes. Once merged, delete them: `git branch -d branch-name`. Keep master clean.

**I pushed a wrong commit — what do I do?**
Use `git revert <commit-hash>` — this creates a new "undo" commit, which is safe.
Never use `git reset --hard` on commits that have already been pushed to GitHub. It rewrites history and causes problems.

**How do I see all my tags?**
```bash
git tag          # list all local tags
git tag -n       # list tags with their messages
```
Or check GitHub → your repo → Releases tab.

**Do I need a separate branch for each release?**
No. For a solo project, tags on master are sufficient. Branches are for parallel work, not releases.

**When does the build number reset?**
Never. It must always increase, even across major version changes (v1 → v2). The Play Store rejects any upload with a build number equal to or lower than a previous upload.

**How do I check the current version/build number?**
Look at the `version:` line in `pubspec.yaml`.

**What if I forgot to tag a commit and added more commits after?**
You can tag any past commit:
```bash
git log --oneline          # find the commit hash
git tag v1.2.0 <hash>      # tag that specific commit
git push origin v1.2.0
```

---

## Quick Reference Card

```bash
# Daily workflow
git add .
git commit -m "feat: describe what you did"
git push origin master

# Release day
# 1. Edit pubspec.yaml version
git add pubspec.yaml
git commit -m "chore: bump version to X.Y.Z+N"
flutter build appbundle --release
flutter build apk --release
git push origin master
git tag vX.Y.Z
git push origin vX.Y.Z
# Then create GitHub Release manually in browser
```
