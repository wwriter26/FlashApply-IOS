---
phase: 02-auth-and-profile-foundation
plan: 01
subsystem: auth-and-viewmodel-foundation
tags: [auth, viewmodels, environment-objects, sign-out, codable, networking]
dependency_graph:
  requires: []
  provides:
    - shared-profilevm-at-app-root
    - shared-jobcardsvm-at-app-root
    - shared-appliedjobsvm-at-app-root
    - shared-mailboxvm-at-app-root
    - sign-out-clears-all-state
    - snake-case-codable-decode
  affects:
    - all-downstream-views-consuming-viewmodels
    - profile-tab
    - apply-tab
    - onboarding-routing
tech_stack:
  added: []
  patterns:
    - EnvironmentObject injection at app root
    - JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase
    - JSONEncoder.keyEncodingStrategy = .convertToSnakeCase
    - onChange(of: authVM.isSignedIn) sign-out reset wiring
key_files:
  created: []
  modified:
    - JobHarvest/Services/AuthService.swift
    - JobHarvest/App/FlashApplyApp.swift
    - JobHarvest/App/AppRouter.swift
    - JobHarvest/ViewModels/ProfileViewModel.swift
    - JobHarvest/ViewModels/JobCardsViewModel.swift
    - JobHarvest/ViewModels/AppliedJobsViewModel.swift
    - JobHarvest/ViewModels/MailboxViewModel.swift
    - JobHarvest/Services/NetworkService.swift
    - JobHarvest/Views/Main/MainTabView.swift
decisions:
  - "Used global convertFromSnakeCase decoder strategy (approach A) — safe because camelCase JSON keys with no underscores pass through unchanged; explicit CodingKeys (e.g. PayEstimate.salaryPeriod) take precedence over the strategy"
  - "Post-onboarding loading transition uses Task.sleep(1.5s) to show LoadingView before MainTabView — avoids jarring instant switch after PreferencesQuizView dismissal"
metrics:
  duration: ~15 minutes
  completed_date: "2026-03-16"
  tasks_completed: 2
  files_modified: 9
---

# Phase 2 Plan 01: Auth and ViewModel Foundation Summary

**One-liner:** Promoted all user-data ViewModels to app-root EnvironmentObjects, fixed isFirstLogin error default, wired sign-out state cleanup for all VMs, and fixed snake_case Codable mismatch in NetworkService.

## Tasks Completed

| # | Task | Commit | Status |
|---|------|--------|--------|
| 1 | Fix isFirstLogin error path, promote all ViewModels to app root, wire sign-out reset | 4228c36 | Done |
| 2 | Fix Codable decode strategy and resume upload save chain | fd20d09 | Done |

## What Was Built

### Task 1: ViewModel Foundation and Auth Routing

**AuthService.swift** — Fixed `isFirstLogin()` catch block to `return true` (was `false`). A network error during sign-in now routes new users to onboarding instead of silently skipping it.

**FlashApplyApp.swift** — Added `@StateObject` declarations for `ProfileViewModel`, `JobCardsViewModel`, `AppliedJobsViewModel`, and `MailboxViewModel` at the app root. All four are injected as `.environmentObject()` on `AppRouter`.

**AppRouter.swift** — Added `@EnvironmentObject` properties for all four VMs. Added `.onChange(of: authVM.isSignedIn)` to call `reset()` on all VMs when the user signs out. Added post-onboarding 1.5-second `LoadingView("Getting things ready...")` transition via `showPostOnboardingLoading` state flag.

**ViewModels (all four)** — Added `func reset()` to `ProfileViewModel`, `JobCardsViewModel`, `AppliedJobsViewModel`, and `MailboxViewModel`. Each method resets all published properties to their zero/empty/default state so sign-out leaves no stale data.

**MainTabView.swift** — Converted all four VM declarations from `@StateObject private var` to `@EnvironmentObject var`. The tab-level `.environmentObject()` call-throughs remain (harmless, makes data flow explicit).

### Task 2: Codable Decode Fix and Resume Save Chain

**NetworkService.swift** — `execute<T>()` now uses `JSONDecoder` with `.convertFromSnakeCase` so backend snake_case keys (`first_name`, `resume_file_name`, `work_authorization`, etc.) map correctly to Swift camelCase properties. `performRequest()` now uses `JSONEncoder` with `.convertToSnakeCase` so outgoing request bodies send the keys the backend expects. Added DEBUG logging of outgoing request body (first 500 chars) for diagnostics.

**ProfileViewModel.swift** — `uploadResume(data:fileName:)` now calls `await fetchProfile()` after the metadata POST succeeds, confirming backend persistence and syncing any server-side transformations back to the local profile.

## Deviations from Plan

None — plan executed exactly as written.

## Success Criteria Verification

- [x] isFirstLogin returns true on error (AuthService.swift line 197: `return true`)
- [x] All user-data ViewModels are single shared instances created in FlashApplyApp.swift
- [x] Sign-out resets ALL ViewModel state — profile, jobs, applied jobs, mailbox
- [x] Sign-out confirmation alert preserved in SettingsView ("Are you sure you want to sign out?")
- [x] Profile data decodes from backend JSON correctly (convertFromSnakeCase)
- [x] Resume upload chain re-fetches after POST to confirm persistence
- [x] Post-onboarding "Getting things ready..." loading transition wired
- [x] Project builds clean (BUILD SUCCEEDED on iPhone 17 simulator)

## Self-Check: PASSED
