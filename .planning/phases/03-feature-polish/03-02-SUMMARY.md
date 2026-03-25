---
phase: 03-feature-polish
plan: 02
subsystem: swipe-apply
tags: [swipe, animation, badge, empty-state, error-handling, ui-polish]
dependency_graph:
  requires: [03-01]
  provides: [SWIPE-01, SWIPE-02, SWIPE-03, SWIPE-04, SWIPE-06, SWIPE-07]
  affects: [JobCardView, ApplyView, JobCardsViewModel]
tech_stack:
  added: []
  patterns:
    - pendingSwipeIsAccepting state flag for sheet dismiss detection
    - context-aware empty state using Equatable JobFilters comparison
    - humanReadableDescription error mapping on ViewModel catch blocks
key_files:
  modified:
    - JobHarvest/Views/Main/Apply/JobCardView.swift
    - JobHarvest/Views/Main/Apply/ApplyView.swift
    - JobHarvest/ViewModels/JobCardsViewModel.swift
decisions:
  - pendingSwipeIsAccepting = false set BEFORE onSwipe call in ManualAnswersSheet callback to prevent false snap-back on submit path
  - emptyView renamed to emptyDeckView and replaced entirely with context-aware version
  - ErrorBannerView placed inside cardDeck VStack before ZStack so it only shows when deck is active (not during loading/empty/noSwipes states)
metrics:
  duration: ~8 minutes
  completed: "2026-03-25T01:36:06Z"
  tasks_completed: 2
  files_modified: 3
---

# Phase 03 Plan 02: Swipe Card Polish Summary

**One-liner:** Fixed manualInputFields snap-back bug via onDismiss flag, added isGreatFit/greatMatch dual-label badge, and wired context-aware empty deck with filter detection and humanized error banner.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Fix manualInputFields animation bug and add isGreatFit badge | 437f873 | JobCardView.swift |
| 2 | Context-aware empty deck, swipe limit polish, error humanization | f674d29 | ApplyView.swift, JobCardsViewModel.swift |

## What Was Built

**Task 1 — JobCardView.swift:**
- Removed `dragOffset = .zero` from the manualInputFields acceptance path in `DragGesture.onEnded`. Card now stays off-screen (at x=600) while the sheet is open.
- Added `onDismiss` handler to `.sheet(isPresented: $showManualAnswers)`: if `pendingSwipeIsAccepting` is still `true` when sheet closes, snap-back animation fires and flag resets. This covers the cancel path.
- In the `ManualAnswersSheet` answer callback, `pendingSwipeIsAccepting = false` is set before calling `onSwipe` so the dismiss handler does not snap-back on submit.
- Badge condition updated from `job.greatMatch == true` to `job.isGreatFit == true || job.greatMatch == true`, with label text "Great Fit" when `isGreatFit` is true and "Great Match" otherwise.

**Task 2 — ApplyView.swift + JobCardsViewModel.swift:**
- Added `hasActiveFilters: Bool` computed property comparing `currentFilters != JobFilters()` (works because Plan 01 made `JobFilters` `Equatable`).
- Replaced generic `emptyView` with `emptyDeckView` showing filter-aware messaging: "No matches for these filters" + "Adjust Filters" button (opens FilterDrawerView) vs "All caught up!" + "Refresh Jobs" button.
- Added `ErrorBannerView` inside `cardDeck` VStack before the card ZStack, bound to `jobCardsVM.error` with retry that clears error and re-fetches.
- Replaced `error.localizedDescription` with `error.humanReadableDescription` in `JobCardsViewModel.fetchJobs` catch block.

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| `pendingSwipeIsAccepting` in JobCardView.swift | PASS (6 occurrences) |
| `onDismiss` in sheet modifier | PASS |
| `isGreatFit` in badge condition | PASS |
| Both "Great Fit" and "Great Match" strings | PASS |
| `hasActiveFilters` in ApplyView.swift | PASS (5 occurrences) |
| "No matches for these filters" | PASS |
| "All caught up!" | PASS |
| "Daily Limit Reached" | PASS (pre-existing) |
| "Upgrade Now" | PASS (pre-existing) |
| `ErrorBannerView` in ApplyView.swift | PASS |
| `humanReadableDescription` in JobCardsViewModel.swift | PASS |
| Build succeeds with zero errors | PASS |

## Deviations from Plan

**None** — Plan executed exactly as written.

The `noSwipesView` already contained "Daily Limit Reached", the flame icon, and "Upgrade Now" NavigationLink with the correct orange gradient. No changes were needed to that section.

The toolbar swipe badge already existed with correct color threshold logic (`remaining <= 5` → orange). No changes needed (SWIPE-04 was pre-existing).

## Self-Check

### Files Created/Modified
- `JobHarvest/Views/Main/Apply/JobCardView.swift` — FOUND
- `JobHarvest/Views/Main/Apply/ApplyView.swift` — FOUND
- `JobHarvest/ViewModels/JobCardsViewModel.swift` — FOUND

### Commits
- `437f873` — FOUND (fix manualInputFields snap-back bug and isGreatFit badge)
- `f674d29` — FOUND (context-aware empty deck, error humanization, error banner)

## Self-Check: PASSED
