---
phase: 02-auth-and-profile-foundation
plan: "02"
subsystem: ui
tags: [swiftui, userdefaults, onboarding, profile, flowlayout]

requires:
  - phase: 02-auth-and-profile-foundation plan 01
    provides: ProfileViewModel with shared instance injected at app root, uploadResume() with post-upload re-fetch

provides:
  - 5-step onboarding wizard with FlowLayout skills tag picker (25 pre-defined skills)
  - UserDefaults quiz state persistence (restores on appear, saves on every field change)
  - Correct merge-before-upload submit ordering in PreferencesQuizView
  - Quiz state cleanup on submit, skip, and sign-out

affects:
  - 03-job-browsing (onboarding must complete before user reaches MainTabView)
  - 04-application-pipeline (profile.skills persisted after onboarding)

tech-stack:
  added: []
  patterns:
    - "Break large view body into private computed vars to avoid Swift type-checker timeout on long modifier chains"
    - "Persist quiz fields to UserDefaults via onChange; restore via onAppear helper method"
    - "Merge profile fields into shared VM BEFORE calling uploadResume() to ensure backend receives complete profile"

key-files:
  created: []
  modified:
    - JobHarvest/Views/Onboarding/PreferencesQuizView.swift
    - JobHarvest/ViewModels/AuthViewModel.swift

key-decisions:
  - "Extracted onAppear body into restoreQuizState() method and split onChange chain across two computed properties (quizStackWithPersistenceA/quizStackWithPersistence) to work around Swift type-checker 'unable to type-check expression in reasonable time' error on large modifier chains"
  - "Merge quiz fields into profileVM.profile BEFORE calling uploadResume() — uploadResume POSTs the full profile to the backend, so merge must happen first or name/skills arrive as nil"
  - "resumeData (Data) not persisted to UserDefaults (binary too large) — only resumeFileName preserved so UI shows prior selection name"

patterns-established:
  - "QuizKeys private enum centralizes all UserDefaults key strings to avoid typo bugs"
  - "static clearSavedQuizState() on the view struct itself makes cleanup callable from AuthViewModel without circular imports"

requirements-completed: [ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05]

duration: 10min
completed: 2026-03-16
---

# Phase 02 Plan 02: Onboarding Quiz Polish Summary

**5-step onboarding wizard with FlowLayout skills tag picker, UserDefaults state persistence, and correct merge-before-upload profile submit ordering**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-16T04:00:00Z
- **Completed:** 2026-03-16T04:09:35Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Switched `PreferencesQuizView` from local `@StateObject profileVM` to shared `@EnvironmentObject`, enabling submit to reach the backend via the real shared instance
- Added FlowLayout skills tag picker on step 5 with 25 pre-defined tags across engineering, product, design, and soft skills
- Rewrote `submitProfile()` to merge all quiz fields into `profileVM.profile` before `uploadResume()` — ensuring the profile POST during resume upload includes firstName, lastName, skills, and all other fields (not nil)
- Added `QuizKeys` enum and `clearSavedQuizState()` static method; wired `onChange` persistence for all 10 fields and `onAppear` restore
- Added `clearSavedQuizState()` to the skip button action and `AuthViewModel.handleSignOut()` so no stale quiz data leaks between users

## Task Commits

Each task was committed atomically:

1. **Task 1: Switch to shared ProfileViewModel, add skills tag picker, wire submit** - `18a7a89` (feat)
2. **Task 2: Add quiz state persistence via UserDefaults, clear on sign-out** - `c76ea23` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `JobHarvest/Views/Onboarding/PreferencesQuizView.swift` - Complete rewrite of ViewModel injection, skills UI, submit ordering, and UserDefaults persistence
- `JobHarvest/ViewModels/AuthViewModel.swift` - Added `clearSavedQuizState()` call in `handleSignOut()`

## Decisions Made

- Extracted onAppear restore into `restoreQuizState()` helper and split the 10 `.onChange` modifiers across two private computed vars (`quizStackWithPersistenceA` + `quizStackWithPersistence`) to work around Swift's "unable to type-check expression in reasonable time" error on large chained modifier expressions
- Chose not to persist `resumeData` (raw `Data`) in UserDefaults — binary too large; only `resumeFileName` is saved so the UI shows the previous file name but user must re-select the PDF after force-quit (acceptable UX, documented in comment)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Refactored modifier chain to fix Swift type-checker timeout**
- **Found during:** Task 2 (build verification)
- **Issue:** Swift compiler error "unable to type-check this expression in reasonable time" caused by chaining 10+ `.onChange` modifiers plus `.onAppear`, `.sheet`, and `NavigationStack` in a single expression chain
- **Fix:** Extracted `NavigationStack` into `quizStack` computed var, `.sheet` into `quizStackWithSheet`, and split the `.onChange` modifiers across `quizStackWithPersistenceA` (5 modifiers) and `quizStackWithPersistence` (5 modifiers)
- **Files modified:** `JobHarvest/Views/Onboarding/PreferencesQuizView.swift`
- **Verification:** Build succeeded with zero errors
- **Committed in:** `c76ea23` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking compiler error)
**Impact on plan:** Structural refactor only — behavior is identical to plan spec. No scope creep.

## Issues Encountered

- Swift type-checker timeout with 10 chained `.onChange` modifiers — resolved by splitting into two private computed properties. This is a known Swift limitation with long modifier chains on complex view types.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Onboarding wizard is fully functional: collects resume, name, phone, work auth, job types, and skills
- Profile data is saved to backend on submit via shared ProfileViewModel
- Quiz state persists across backgrounding and clears cleanly on sign-out
- Phase 03 (job browsing) is unblocked — users will arrive at MainTabView with a complete profile

---
*Phase: 02-auth-and-profile-foundation*
*Completed: 2026-03-16*
