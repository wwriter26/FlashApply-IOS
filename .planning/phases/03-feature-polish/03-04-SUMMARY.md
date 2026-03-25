---
phase: 03-feature-polish
plan: "04"
subsystem: my-jobs-pipeline
tags: [applied-jobs, pipeline, empty-state, error-handling, optimistic-update]
dependency_graph:
  requires: ["03-01"]
  provides: [JOBS-01, JOBS-02, JOBS-03, JOBS-04, JOBS-05]
  affects: [MyJobsView, JobDetailSheet, AppliedJobsViewModel, MainTabView]
tech_stack:
  added: []
  patterns: [optimistic-update, notification-center-tab-switch, callback-closure-propagation]
key_files:
  created: []
  modified:
    - JobHarvest/Views/Main/MyJobs/MyJobsView.swift
    - JobHarvest/Views/Main/MyJobs/JobDetailSheet.swift
    - JobHarvest/ViewModels/AppliedJobsViewModel.swift
    - JobHarvest/Utils/Extensions.swift
    - JobHarvest/Views/Main/MainTabView.swift
decisions:
  - "Used NotificationCenter for Apply tab switch from empty state CTA — view hierarchy prevents direct @Binding propagation through sheet"
  - "onStageMoved callback on JobDetailSheet surfaces move confirmation to parent MyJobsView; selectedStage reverts on error"
  - "moveJob catch now sets user-facing error message via ErrorBannerView already wired in MyJobsView"
metrics:
  duration: "~18m"
  completed_date: "2026-03-25"
  tasks_completed: 2
  files_modified: 5
---

# Phase 03 Plan 04: Applied Jobs Pipeline Polish Summary

**One-liner:** Applied jobs pipeline polished with correct empty state across all displayed stages, stage move buttons with optimistic feedback, error humanization, and "Start Swiping" CTA wired to tab switch via NotificationCenter.

## What Was Built

All 5 JOBS requirements (JOBS-01 through JOBS-05) satisfied across 2 tasks and 5 files.

### Task 1: MyJobsView — Empty State, Loading, Error Banner, Stage Move Feedback (commit: d8fb4e1)

- Updated empty state copy to "No applications yet" with CTA button "Start Swiping"
- CTA posts `Notification.Name.switchToApplyTab` — handled in `MainTabView.onReceive` to set `selectedTab = 0`
- Empty state check already correctly used `displayedStages.allSatisfy(...)` — verified, no change needed
- Loading message updated to "Loading your applications..." per spec
- Added `ErrorBannerView` at top of content area, wired to `appliedJobsVM.error` with retry action
- Added `stageMoveMessage` state with animated banner that auto-dismisses after 3 seconds
- Active/All segmented toggle was already correct — confirmed, no change needed

### Task 2: JobDetailSheet Stage Move + ViewModel Error Humanization (commit: 516575c)

- `JobDetailSheet` now accepts `onStageMoved: ((String) -> Void)?` callback
- Stage picker button calls `onStageMoved("Moved to \(stage.displayName)")` on success
- Button reverts `selectedStage` to previous value if `appliedJobsVM.error` is set after move
- `AppliedJobsViewModel.fetchAppliedJobs` catch now uses `error.humanReadableDescription`
- `moveJob` catch sets `self.error = "Could not update stage. Tap to retry."` after silent revert
- `appliedDate` confirmed absent from all MyJobs views — JOBS-03 satisfied
- Optimistic remove/add pattern already in place — JOBS-04 satisfied
- Job posting link via Safari already wired in toolbar — JOBS-05 satisfied

## Deviations from Plan

### Auto-fixed Issues

None.

### Observations / Clarifications

**1. Stage move error callback pattern**

The plan suggested `stageMoveMessage` state in `MyJobsView` triggered from the detail sheet move action. Since `JobDetailSheet` is presented as a `.sheet`, a closure callback (`onStageMoved`) was passed at construction time — this is cleaner than posting a second notification and avoids coupling.

**2. `AllSatisfy` empty state was already correct**

The RESEARCH note (Pattern 6) was accurate — `displayedStages.allSatisfy(...)` was already in place. Task 1 was primarily about updating copy and adding the missing loading/error UI.

**3. `PipelineStage.color` and `displayName` already existed**

Both computed properties were in `Constants.swift` — no changes to the model needed. The `stagePicker` in `JobDetailSheet` was already fully wired with `moveJob()`.

## Verification

- Build: SUCCEEDED (iPhone 17 Pro simulator)
- `grep "No applications yet"` — match found
- `grep "humanReadableDescription"` — match found in ViewModel
- `grep -r "appliedDate" JobHarvest/Views/Main/MyJobs/` — no display matches (grep returns nothing, confirming clean)

## Self-Check: PASSED

Files confirmed present:
- JobHarvest/Views/Main/MyJobs/MyJobsView.swift — FOUND
- JobHarvest/Views/Main/MyJobs/JobDetailSheet.swift — FOUND
- JobHarvest/ViewModels/AppliedJobsViewModel.swift — FOUND
- JobHarvest/Utils/Extensions.swift — FOUND
- JobHarvest/Views/Main/MainTabView.swift — FOUND

Commits confirmed:
- d8fb4e1 — FOUND
- 516575c — FOUND
