---
phase: 04-hardening
plan: 02
subsystem: image-caching, crash-reporting
tags: [sdwebimage, sentry, caching, observability, performance]
dependency_graph:
  requires: [04-01]
  provides: [cached-image-loading, crash-reporting-initialization]
  affects: [CompanyLogoView, FlashApplyApp, AppConfig]
tech_stack:
  added: [SDWebImageSwiftUI 3.x, sentry-cocoa 9.x]
  patterns: [xcconfig-to-infoplist wiring, guard-based optional SDK initialization]
key_files:
  created: []
  modified:
    - JobHarvest/Views/Shared/CompanyLogoView.swift
    - JobHarvest/App/FlashApplyApp.swift
    - JobHarvest/Utils/Constants.swift
    - JobHarvest/Config.xcconfig
    - JobHarvest/JobHarvest/Info.plist
key_decisions:
  - "SDWebImageSwiftUI WebImage replaces AsyncImage for automatic memory+disk caching — zero config required"
  - "Sentry guard clause checks for empty DSN and placeholder value so app runs without crash if DSN not yet set"
  - "Sentry disabled in DEBUG builds (options.enabled = !isDebug) to avoid noise during development"
  - "SENTRY_DSN wired through Config.xcconfig -> Info.plist using same $(KEY) pattern as API_DOMAIN"
metrics:
  duration: 7m
  completed_date: "2026-04-01"
  tasks: 1
  files_modified: 5
requirements_completed: [PERF-01, OBS-01]
---

# Phase 04 Plan 02: Image Caching + Sentry Crash Reporting Summary

**One-liner:** SDWebImageSwiftUI WebImage replaces AsyncImage for dual-layer caching; Sentry SDK initializes before Amplify with configurable DSN via xcconfig.

## What Was Built

### Task 1 (human-action — completed prior)
User added SDWebImageSwiftUI and sentry-cocoa SPM packages via Xcode UI and linked both to the JobHarvest target.

### Task 2 — Code Changes

**CompanyLogoView.swift:** Replaced `AsyncImage(url:) { phase in switch ... }` with `WebImage(url:) { image in ... } placeholder: { ... }`. URL construction and placeholder view are identical — only the image loading mechanism changed. SDWebImageSwiftUI automatically handles memory and disk caching; no additional configuration needed.

**FlashApplyApp.swift:** Added `import Sentry` and a `configureSentry()` method called before `configureAmplify()` in `init()`. The method reads `AppConfig.sentryDsn`, skips initialization if empty or placeholder, then calls `SentrySDK.start` configuring DSN, environment, and disabling in DEBUG builds.

**Constants.swift:** Added `AppConfig.sentryDsn` (reads `SENTRY_DSN` from `Bundle.main.infoDictionary`) and `AppConfig.isDebug` (compile-time flag using `#if DEBUG`).

**Config.xcconfig:** Added `SENTRY_DSN = YOUR_SENTRY_DSN_HERE` placeholder. User replaces value with actual DSN from Sentry dashboard.

**Info.plist:** Added `<key>SENTRY_DSN</key><string>$(SENTRY_DSN)</string>` following the same xcconfig-to-Bundle wiring pattern as `API_DOMAIN`, `STRIPE_KEY`, and `BUCKET_NAME`.

## Deviations from Plan

None — plan executed exactly as written.

## Acceptance Criteria Verification

| Criterion | Result |
|-----------|--------|
| CompanyLogoView contains `import SDWebImageSwiftUI` | Pass |
| CompanyLogoView contains `WebImage(url: url)` | Pass |
| CompanyLogoView does NOT contain `AsyncImage` | Pass (count: 0) |
| Constants.swift contains `static let sentryDsn` | Pass |
| Constants.swift contains `static let isDebug: Bool` | Pass |
| Config.xcconfig contains `SENTRY_DSN` | Pass |
| Info.plist contains `<key>SENTRY_DSN</key>` + `<string>$(SENTRY_DSN)</string>` | Pass |
| FlashApplyApp.swift contains `import Sentry` | Pass |
| FlashApplyApp.swift contains `configureSentry()` | Pass |
| FlashApplyApp.swift contains `SentrySDK.start` | Pass |
| `init()` calls `configureSentry()` before `configureAmplify()` | Pass |

## Next Steps for User

To activate crash reporting:
1. Create a free Sentry account at sentry.io
2. Create an iOS project (Apple > iOS)
3. Copy the DSN from Sentry Dashboard -> Settings -> Client Keys (DSN)
4. Replace `YOUR_SENTRY_DSN_HERE` in `JobHarvest/Config.xcconfig` with the actual DSN

Sentry will remain silently disabled until the DSN is set — the app does not crash or show errors with a placeholder DSN.
