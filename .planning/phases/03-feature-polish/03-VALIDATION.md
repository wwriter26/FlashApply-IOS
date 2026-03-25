---
phase: 3
slug: feature-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in with Xcode) |
| **Config file** | `JobHarvest/JobHarvest.xcodeproj` |
| **Quick run command** | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JobHarvestTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| *Populated after planning* | | | | | | | |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Test infrastructure exists but has zero meaningful tests (only empty `example()` stub)
- [ ] Most Phase 3 work is UI/UX polish — requires manual verification on simulator
- [ ] Automated unit tests feasible for: ViewModel error mapping, plan bridging logic, swipe limit state transitions

*Note: Phase 3 is heavily UI-focused. Most requirements (animations, loading states, empty states) require manual simulator verification. Automated tests can cover ViewModel logic changes.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Card fly-off animation | SWIPE-01, SWIPE-02 | Visual animation quality | Swipe left/right and tap buttons; verify smooth exit with no snap-back |
| Swipe limit countdown banner | SWIPE-03, SWIPE-04 | UI appearance + threshold | Swipe until near limit; verify banner appears and shows correct count |
| Empty deck states | SWIPE-06 | Context-aware UI branching | Empty deck with/without filters active; verify correct message shown |
| Great Fit badge | SWIPE-07 | Visual badge rendering | View cards with `isGreatFit`/`greatMatch` true; verify green badge visible |
| Profile edit + save feedback | PROF-01–PROF-06 | End-to-end with backend | Edit name, phone, preferences; verify save success/failure feedback |
| Resume upload from Profile tab | PROF-04 | S3 + metadata chain | Upload resume from Profile tab; verify it persists after re-fetch |
| Pipeline stage move | JOBS-01–JOBS-04 | Optimistic update + revert | Move job between stages; verify instant UI update; kill network to test revert |
| Job detail sheet | JOBS-05 | Sheet layout + data display | Tap pipeline job; verify detail sheet shows all fields + stage move buttons |
| Stripe checkout flow | PAY-01–PAY-05 | Safari + foreground return | Tap upgrade, complete Stripe checkout, return to app; verify plan updates |
| Branded logo loading | UX-02 | Visual animation | Force loading states; verify logo animation appears (not generic spinner) |
| Empty state messaging | UX-03 | Tone + CTA presence | Clear data for each tab; verify encouraging message + action button |
| Error message readability | UX-01 | Human-readable strings | Trigger network errors; verify no raw AWS/SDK strings shown |
| Network retry | UX-04 | Retry button behavior | Disable network; verify retry option appears on all screens |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
