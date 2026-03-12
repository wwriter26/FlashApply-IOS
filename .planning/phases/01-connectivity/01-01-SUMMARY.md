---
phase: 01-connectivity
plan: 01
subsystem: api
tags: [xcconfig, amplify, cognito, s3, configuration, dev-environment]

# Dependency graph
requires: []
provides:
  - API_DOMAIN configured to dev.jobharvest-api.com via xcconfig $() escape pattern
  - DEBUG fatalError guard in AppConfig.apiDomain for missing/empty API_DOMAIN
  - DEBUG fatalError guard in configureAmplify() catch block for bad Amplify config
  - Startup log of resolved API domain on every launch
  - Config.xcconfig.template for developer onboarding
  - amplifyconfiguration.json.template for developer onboarding
affects: [02-connectivity, 03-payments, 04-polish]

# Tech tracking
tech-stack:
  added: []
  patterns: [crash-loudly-in-debug, xcconfig-url-escape-pattern]

key-files:
  created:
    - JobHarvest/Config.xcconfig.template
    - JobHarvest/amplifyconfiguration.json.template
  modified:
    - JobHarvest/Config.xcconfig
    - JobHarvest/Utils/Constants.swift
    - JobHarvest/App/FlashApplyApp.swift

key-decisions:
  - "Use $() xcconfig URL-escaping trick to prevent Xcode stripping // in API_DOMAIN value"
  - "Crash-loudly in DEBUG for misconfigured API_DOMAIN rather than silently fall back to production"
  - "Crash-loudly in DEBUG for Amplify configure failure rather than hanging on LoadingView"
  - "Keep Config.xcconfig and amplifyconfiguration.json tracked by git — they contain no secrets; templates serve as developer documentation"

patterns-established:
  - "Crash-loudly pattern: #if DEBUG fatalError for configuration guard clauses, silent fallback only in release"
  - "xcconfig URL-escaping: API_DOMAIN = https://$()/domain.com to prevent // comment stripping"
  - "Startup domain log: AppLogger.network.info at Amplify configure success for environment verification"

requirements-completed: [CONN-01, CONN-02, CONN-03, CONN-04]

# Metrics
duration: 3min
completed: 2026-03-11
---

# Phase 1 Plan 01: Fix API Domain and Add Crash-Loudly Guards Summary

**Fixed xcconfig API_DOMAIN typo routing all traffic to production, added #if DEBUG fatalError guards for misconfigured API_DOMAIN and Amplify config failure, and created developer onboarding templates.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-11T21:26:34Z
- **Completed:** 2026-03-11T21:29:38Z
- **Tasks:** 2
- **Files modified:** 5 (3 modified, 2 created)

## Accomplishments

- Fixed `API_DOMAIN` in `Config.xcconfig` — corrected single-slash typo to `https://$()/dev.jobharvest-api.com`, routing all API traffic to the dev backend
- Added `#if DEBUG fatalError` to `AppConfig.apiDomain` computed closure — missing or empty API_DOMAIN now crashes immediately in DEBUG instead of silently falling back to production
- Added `#if DEBUG fatalError` to `configureAmplify()` catch block — bad Amplify config crashes immediately instead of producing an infinite LoadingView
- Added `AppLogger.network.info("API domain: \(AppConfig.apiDomain)")` startup log for runtime verification of domain resolution
- Created `Config.xcconfig.template` and `amplifyconfiguration.json.template` for developer onboarding

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix API_DOMAIN and add fatalError guards** - `809d3b1` (fix)
2. **Task 2: Create developer onboarding template files** - `bbc3303` (chore)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `JobHarvest/Config.xcconfig` - Fixed API_DOMAIN: `https://$()/dev.jobharvest-api.com`
- `JobHarvest/Utils/Constants.swift` - AppConfig.apiDomain replaced with guard closure + #if DEBUG fatalError
- `JobHarvest/App/FlashApplyApp.swift` - configureAmplify() catch block now has #if DEBUG fatalError + startup domain log
- `JobHarvest/Config.xcconfig.template` - Developer onboarding reference with $() URL-escaping docs
- `JobHarvest/amplifyconfiguration.json.template` - Developer onboarding reference with placeholder Cognito/S3 values

## Decisions Made

- Used $() xcconfig URL-escaping trick (empty variable expansion) to preserve `//` in the API_DOMAIN value — Xcode treats `//` as a comment in xcconfig files without this workaround
- Crash-loudly in DEBUG for API_DOMAIN guard — silent fallback to production would cause hard-to-debug 403 errors on the wrong domain
- Kept both config files tracked by git — they contain only a domain name and non-sensitive AWS public pool IDs; templates serve as documentation rather than replacements

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The `iPhone 16` simulator named in the build command does not exist in this environment (OS 26.2 simulators available). Used `iPhone 17` instead — build succeeded with zero errors. The single pre-existing warning (`call to main actor-isolated initializer`) is unrelated to these changes.

## User Setup Required

None - no external service configuration required. The template files serve as documentation; the actual config files (`Config.xcconfig` and `amplifyconfiguration.json`) are already committed with correct dev values.

## Next Phase Readiness

- API domain is now correctly pointed at `dev.jobharvest-api.com`
- Misconfigured environments will crash immediately in DEBUG rather than silently misbehaving
- Developer onboarding templates provide clear setup instructions
- Ready for Phase 1 Plan 02 (next connectivity task)

## Self-Check: PASSED

- FOUND: JobHarvest/Config.xcconfig
- FOUND: JobHarvest/Utils/Constants.swift
- FOUND: JobHarvest/App/FlashApplyApp.swift
- FOUND: JobHarvest/Config.xcconfig.template
- FOUND: JobHarvest/amplifyconfiguration.json.template
- FOUND: .planning/phases/01-connectivity/01-01-SUMMARY.md
- FOUND commit: 809d3b1 (fix API_DOMAIN and fatalError guards)
- FOUND commit: bbc3303 (developer onboarding templates)

---
*Phase: 01-connectivity*
*Completed: 2026-03-11*
