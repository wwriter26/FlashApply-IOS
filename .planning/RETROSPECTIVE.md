# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-04-01
**Phases:** 4 | **Plans:** 11 | **Tasks:** 17

### What Was Built
- Full API connectivity with DEBUG crash guards for misconfigured domains
- Complete auth flow: sign-in, onboarding quiz with skills picker, profile management
- Polished swipe cards with animations, swipe limits, and prefetch
- Applied jobs pipeline with optimistic stage moves and archived tab
- Stripe web checkout integration via SFSafariViewController
- Human-readable error messages, branded loading, empty states across all tabs
- Image caching (SDWebImageSwiftUI) and crash reporting (Sentry)
- Bounded seenUrls memory and exactly-once Hub listener registration

### What Worked
- Polish-first approach — the app was already built, fixing config + polishing was the fastest path
- Phase dependency chain (connectivity → auth → features → hardening) prevented rework
- Iterative human verification in Phase 3 caught real issues (403 vs 401 confusion, plan display bugs)
- xcconfig `$()` escaping trick solved the URL-stripping problem cleanly

### What Was Inefficient
- Phase 2 and 3 roadmap checkboxes fell out of sync with actual completion during iterative testing
- Stripe checkout required backend investigation mid-phase — the embedded `ui_mode` discovery should have happened earlier
- Some checkpoint fixes were committed in bulk rather than atomically

### Patterns Established
- `Config.xcconfig` + `Info.plist` + `AppConfig` pattern for all configuration values
- `ErrorBannerView` as reusable error display component
- `humanReadableDescription` extension on Error for user-facing messages
- `NotificationCenter` for cross-view communication where @Binding can't propagate
- `scenePhase` + flag pattern for detecting app-return-from-Safari

### Key Lessons
1. Always separate 403 (rate limit) from 401 (auth) in NetworkService — conflating them causes wrong error recovery paths
2. SwiftUI `.task` in Views is not safe for one-time setup — use ViewModel `init()` for exactly-once registration
3. `AsyncImage` has zero caching — always use SDWebImageSwiftUI for images that appear more than once
4. Merge profile data BEFORE upload when the upload POST includes the full profile body

### Cost Observations
- Model mix: ~40% opus (planning, complex execution), ~60% sonnet (research, verification, simple execution)
- Notable: Phase 4 was the most efficient — well-scoped problems with clear solutions, minimal iteration

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 4 | 11 | Initial project — established GSD workflow patterns |

### Top Lessons (Verified Across Milestones)

1. Polish-first works when the foundation is solid — don't rebuild what already works
2. Config issues should be Phase 1 — nothing else is testable without connectivity
