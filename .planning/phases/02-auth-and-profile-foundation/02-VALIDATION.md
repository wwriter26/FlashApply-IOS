---
phase: 2
slug: auth-and-profile-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-15
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest via xcodebuild |
| **Config file** | JobHarvest/JobHarvest.xcodeproj |
| **Quick run command** | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JobHarvestTests 2>&1 \| tail -20` |
| **Full suite command** | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 \| tail -40` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | AUTH-02 | manual | Simulator: sign up new user → verify onboarding shown | N/A | ⬜ pending |
| 02-01-02 | 01 | 1 | AUTH-03 | manual | Simulator: sign in existing user → verify main tabs shown | N/A | ⬜ pending |
| 02-02-01 | 02 | 1 | ONBD-01 | manual | Simulator: complete all quiz steps → verify data saved | N/A | ⬜ pending |
| 02-02-02 | 02 | 1 | ONBD-02 | manual | Simulator: verify skills tag picker appears and functions | N/A | ⬜ pending |
| 02-02-03 | 02 | 1 | ONBD-03 | manual | Simulator: complete onboarding → check backend for saved data | N/A | ⬜ pending |
| 02-03-01 | 03 | 2 | AUTH-01, AUTH-04 | manual | Simulator: sign in → force quit → relaunch → verify session persists | N/A | ⬜ pending |
| 02-03-02 | 03 | 2 | AUTH-05 | manual | Simulator: sign out → verify clean state → sign back in | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. This phase is primarily bug fixes and UI wiring — validation is manual (Simulator-based) rather than unit-test-based because:
1. Auth flows require Amplify Cognito integration (no protocol abstractions exist yet — Phase 4 scope)
2. Profile data persistence requires live backend responses
3. Onboarding quiz validation is UI-state-driven

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| New user routing on network error | AUTH-02 | Requires simulating network failure during Cognito attribute fetch | 1. Sign up new user 2. Enable airplane mode before attribute check 3. Verify onboarding quiz shown |
| Profile data loads for existing user | AUTH-01 | Requires live backend with existing user data | 1. Sign in with existing account 2. Navigate to Profile tab 3. Verify all fields populated |
| Resume upload persists | ONBD-03 | Requires S3 + backend round-trip | 1. Upload resume in onboarding 2. Complete quiz 3. Check Profile tab shows resume filename |
| Session persistence across restarts | AUTH-04 | Requires app lifecycle simulation | 1. Sign in 2. Force quit app 3. Relaunch 4. Verify still signed in on main tabs |
| Sign-out clears all state | AUTH-05 | Requires checking multiple ViewModels reset | 1. Sign out 2. Verify sign-in screen 3. Sign back in 4. Verify fresh data fetch |
| Skills tag picker functional | ONBD-02 | UI interaction required | 1. Start onboarding 2. Reach skills step 3. Select multiple tags 4. Verify saved to profile |
| Quiz state preserved on background | ONBD-04 | Requires app backgrounding mid-quiz | 1. Start quiz, fill 2 steps 2. Background app 3. Return 4. Verify progress preserved |
| Validation blocks advancement | ONBD-05 | UI state validation | 1. Try advancing without resume 2. Verify blocked 3. Try advancing without name 4. Verify blocked |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
