---
phase: 04-hardening
plan: 01
subsystem: testing
tags: [swift, amplify, concurrency, unit-tests, viewmodel]

# Dependency graph
requires: []
provides:
  - Bounded seenUrls set with FIFO eviction at 500-entry cap in JobCardsViewModel
  - Hub listener registered exactly once in AuthViewModel.init via setupHubListener()
  - AppRouter cleaned of all Amplify Hub listener code
  - 7 unit tests (SeenUrlsCapTests x5, HubListenerTests x2)
affects: [04-02]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - FIFO eviction with parallel Set + Array (O(1) lookup, O(1) FIFO order)
    - Hub listener in ObservableObject.init not SwiftUI View body
    - "#if DEBUG test accessors for @MainActor-isolated internal state"
    - "nonisolated deinit with direct Amplify.Hub.removeListener call"

key-files:
  created: []
  modified:
    - JobHarvest/ViewModels/JobCardsViewModel.swift
    - JobHarvest/ViewModels/AuthViewModel.swift
    - JobHarvest/App/AppRouter.swift
    - JobHarvest/JobHarvestTests/JobHarvestTests.swift

key-decisions:
  - "seenUrlsCap=500 constant + seenUrlsOrder [String] array for FIFO tracking alongside seenUrls Set"
  - "hubToken declared private var (not nonisolated) — deinit on @MainActor class runs on main actor in Swift 5.9+"
  - "hubToken added in Task 1 as compilation prerequisite for _hasHubToken DEBUG accessor"

patterns-established:
  - "FIFO eviction pattern: guard !set.contains; set.insert + array.append; if array.count > cap { evict }"
  - "Hub listener pattern: private setupHubListener() called from init(), [weak self] Task capture, deinit cleanup"
  - "#if DEBUG accessors for testing @MainActor state without breaking encapsulation"

requirements-completed: [PERF-02, SC-2, SC-4]

# Metrics
duration: 20min
completed: 2026-04-01
---

# Phase 04 Plan 01: Architectural Hardening — seenUrls Cap + Hub Listener Fix Summary

**FIFO-bounded seenUrls (500-entry cap with Array+Set eviction) and Amplify Hub listener moved from SwiftUI AppRouter into AuthViewModel.init for exactly-once registration**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-04-01T17:00:00Z
- **Completed:** 2026-04-01T17:19:45Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- seenUrls set is now bounded at 500 entries — oldest URLs evicted FIFO when cap exceeded, preventing oversized `exclude` query parameters in long sessions
- Hub listener moved from AppRouter (SwiftUI View, re-renders freely) to AuthViewModel.init (ObservableObject lifecycle, runs once per instance)
- 7 unit tests written covering cap enforcement, eviction correctness, duplicate deduplication, reset, and Hub listener registration per instance
- AppRouter is now free of Amplify dependency — no `import Amplify`, no `hubToken`, no `onDisappear`

## Task Commits

Each task was committed atomically:

1. **Task 1: Bounded seenUrls FIFO eviction + unit tests scaffold** - `9ae9399` (feat)
2. **Task 2: Move Hub listener from AppRouter to AuthViewModel** - `f063cf1` (feat)

## Files Created/Modified
- `JobHarvest/ViewModels/JobCardsViewModel.swift` - Added seenUrlsCap, seenUrlsOrder, recordSeen(), reset() update, #if DEBUG accessors
- `JobHarvest/ViewModels/AuthViewModel.swift` - Added hubToken, init(), deinit, setupHubListener(), #if DEBUG _hasHubToken accessor
- `JobHarvest/App/AppRouter.swift` - Removed import Amplify, hubToken state, listenToAuthEvents(), onDisappear block
- `JobHarvest/JobHarvestTests/JobHarvestTests.swift` - SeenUrlsCapTests (5 tests) + HubListenerTests (2 tests)

## Decisions Made
- Used parallel `Set<String>` + `[String]` array for FIFO eviction: Set gives O(1) contains/remove, Array gives stable insertion order for FIFO. Alternative (OrderedSet from swift-algorithms) not needed — this pattern is zero-dependency and clearly correct.
- `hubToken` added as `private var` in Task 1 (not Task 2) because the `_hasHubToken` DEBUG accessor references it and needs to compile before Task 2. This front-loaded a Task 2 artifact but prevented a compile error.
- `deinit` uses direct `Amplify.Hub.removeListener(token)` call. In Swift 5.9+, `deinit` on a `@MainActor`-isolated class runs on the main actor, so accessing `hubToken` is safe without `nonisolated(unsafe)` (which requires Swift 5.10).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added hubToken property in Task 1 to prevent compile error**
- **Found during:** Task 1 (writing _hasHubToken DEBUG accessor)
- **Issue:** The plan's `_hasHubToken` accessor references `hubToken` which the plan schedules for Task 2. This would cause a compile error at end of Task 1.
- **Fix:** Added `private var hubToken: UnsubscribeToken?` to AuthViewModel in Task 1. Task 2 then adds init/deinit/setupHubListener() that uses it.
- **Files modified:** JobHarvest/ViewModels/AuthViewModel.swift
- **Verification:** grep confirms hubToken exists before Task 2 commit; both tasks compile cleanly
- **Committed in:** 9ae9399 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — compile error prevention)
**Impact on plan:** Minimal — hubToken declaration front-loaded by one task, no behavior change.

## Issues Encountered
None beyond the compile-order deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- 04-02 can proceed: architectural hardening for seenUrls and Hub listener is complete
- All 7 unit tests should pass once Amplify is configured (Hub listener tests require Amplify.configure() to be called before AuthViewModel init in test host)

---
*Phase: 04-hardening*
*Completed: 2026-04-01*
