# Codebase Concerns

**Analysis Date:** 2026-03-11

---

## Tech Debt

**Prices hard-coded in client-side Swift:**
- Issue: Subscription prices (`$25/mo`, `$30/mo`, `$50 seasonal`, `$200 lifetime`, etc.) are baked directly into `SubscriptionPlan.swift`. If pricing changes on the backend/Stripe, the app must be updated and resubmitted.
- Files: `JobHarvest/Models/SubscriptionPlan.swift` (lines 20–48)
- Impact: Every pricing change requires an App Store release cycle. Prices can be out of sync with what Stripe actually charges.
- Fix approach: Fetch plan details (price, features, swipe limits) from a `/getPlans` endpoint at app launch and cache them in `SubscriptionViewModel`.

**Duplicate profile-update logic in `ProfileViewModel.uploadResume`:**
- Issue: `uploadResume` in `ProfileViewModel` manually re-posts the entire profile to `/users/{id}/profile` after setting `profile.resumeFileName`, duplicating the logic already in `updateProfile`. If the endpoint signature changes, there are two call sites to update.
- Files: `JobHarvest/ViewModels/ProfileViewModel.swift` (lines 71–90)
- Impact: Fragile — a refactor of `updateProfile` will silently miss this path.
- Fix approach: Replace the inline `network.request` call with `try await updateProfile(profile)`.

**`FetchJobsResponse` has two optional keys for the same data:**
- Issue: `resolvedJobs` tries `newJobs` then falls back to `jobs`, masking a backend inconsistency. The comment on line 93 acknowledges this.
- Files: `JobHarvest/Models/Job.swift` (lines 91–96)
- Impact: Decoder silently succeeds when either key is present; a future backend rename to a third key would silently return zero jobs.
- Fix approach: Align to one canonical key with the backend and remove the fallback.

**`isFirstLogin` uses a string comparison `!= "false"` which defaults to `true` on error:**
- Issue: If `getUserAttributes()` fails (network hiccup on first launch), `isFirstLogin()` returns `false` (the error branch), meaning the onboarding quiz is skipped. Conversely, any attribute value other than `"false"` (e.g., `nil`, `"true"`, `"1"`) is treated as first-login-true, which is correct for new users but creates an ambiguous case.
- Files: `JobHarvest/Services/AuthService.swift` (lines 173–184)
- Impact: On auth fetch failure, new users bypass the preferences quiz; on API error, returning users may be unexpectedly routed to onboarding.
- Fix approach: Fail explicitly (throw) instead of silently defaulting; let `AppRouter` handle the error state.

**`seenUrls` in `JobCardsViewModel` grows indefinitely in-memory:**
- Issue: Every swiped job URL is added to `seenUrls: Set<String>` with no pruning. A heavy user who swipes thousands of times per session will carry an ever-growing exclusion list that inflates every `/jobs` POST body.
- Files: `JobHarvest/ViewModels/JobCardsViewModel.swift` (line 17, 44)
- Impact: Memory growth over long sessions; large request bodies. The server already tracks seen jobs per user, so the client-side exclusion list is redundant for cross-session deduplication.
- Fix approach: Cap `seenUrls` at a reasonable size (e.g., last 200 URLs) or remove client-side exclusion and rely entirely on the backend.

---

## Known Bugs

**Swipe animation conflict when `manualInputFields` is non-empty:**
- Symptoms: When the user swipes right on a job that has `manualInputFields`, the card animates off-screen (line 57–60 in `dragGesture`), then `dragOffset` is immediately reset to `.zero` (line 67). This causes a visible "snap back" before the sheet appears.
- Files: `JobHarvest/Views/Main/Apply/JobCardView.swift` (lines 56–71)
- Trigger: Swipe right on any job with `manualInputFields?.isEmpty == false`.
- Workaround: The sheet does appear; the visual glitch is cosmetic.

**`WorkHistoryEntry.id` and `EducationEntry.id` are not stable:**
- Symptoms: `id` is computed from mutable fields (`company + title + startDate`). If the user edits company name or title, SwiftUI's `ForEach` loses identity, causing incorrect animations and potential duplicate-key crashes.
- Files: `JobHarvest/Models/User.swift` (lines 75, 87)
- Trigger: Editing an existing work history or education entry in place.
- Workaround: None currently; items are re-fetched after save which masks the issue.

**`SubscriptionViewModel.currentPlan` is never loaded from the user's actual profile on launch:**
- Symptoms: `PremiumView` always shows "current plan: Free" on first open because `SubscriptionViewModel` initializes `currentPlan = .free` and is only updated after `checkSessionStatus`. The user's real plan is available on `profileVM.profile.plan` (a String) but is not bridged to `SubscriptionViewModel`.
- Files: `JobHarvest/ViewModels/SubscriptionViewModel.swift` (line 8), `JobHarvest/Models/User.swift` (line 54)
- Trigger: Opening Premium tab before completing a `checkSessionStatus` call.
- Workaround: The plan string from `ProfileViewModel` is used to derive `isPremium` in `ApplyView` (line 13–15) but is not surfaced in `PremiumView`.

**`FlowLayout` frame height calculation is a rough heuristic:**
- Symptoms: `FlowLayout` calculates its height as `max(CGFloat(items.count / 3 + 1) * 28, 28)`. This hardcodes 3 items per row and 28pt row height, which breaks when items have variable widths or when the view is rendered in a narrower container (e.g., smaller phones).
- Files: `JobHarvest/Views/Main/Apply/JobCardView.swift` (line 355)
- Trigger: Long chip labels, many chips, or narrow device widths.
- Workaround: The layout still renders but chips may be clipped or overflow.

**`MyJobsView` empty state only checks `applying` and `applied` columns:**
- Symptoms: If a user has jobs only in `screen`, `interview`, or `offer` stages (but none in `applying`/`applied`), the view shows "No Applications Yet" even though there are active applications.
- Files: `JobHarvest/Views/Main/MyJobs/MyJobsView.swift` (lines 27–29)
- Trigger: User has advanced all jobs past the `applied` stage.
- Workaround: None; the pipeline columns still render correctly if the user taps "All" in the segmented picker.

---

## Security Considerations

**`amplifyconfiguration.json` not committed, but no `.template` file exists in the repo:**
- Risk: CLAUDE.md mentions copying from a `.template` file; no `.template` is present. A new developer has no documented starting point and may hard-code values directly.
- Files: `JobHarvest/amplifyconfiguration.json` (presence noted, contents not read), `JobHarvest/Config.xcconfig`
- Current mitigation: Both config files are git-ignored.
- Recommendations: Commit `amplifyconfiguration.json.template` and `Config.xcconfig.template` with placeholder values and instructions.

**`AppConfig.apiDomain` falls back to a hardcoded production URL:**
- Risk: If `API_DOMAIN` is missing from `Config.xcconfig` (e.g., in a fresh clone), the app silently uses `"https://jobharvest-api.com"` — the real production API — from debug builds. A developer debugging with a local/staging server may accidentally hit production if the xcconfig is misconfigured.
- Files: `JobHarvest/Utils/Constants.swift` (line 5)
- Current mitigation: None.
- Recommendations: Fail loudly with a `fatalError` in DEBUG builds if `API_DOMAIN` is not set, rather than falling back to production.

**`stripePublishableKey` falls back to an empty string:**
- Risk: An empty Stripe key will silently pass to any Stripe SDK initialization without crashing, but Stripe calls will fail in ways that may not be surfaced clearly to the user.
- Files: `JobHarvest/Utils/Constants.swift` (line 6)
- Current mitigation: Checkout uses a web flow (SFSafariViewController), so the Stripe key may not be actively used in the current implementation, but it is exposed in `Constants.swift` nonetheless.
- Recommendations: Assert non-empty in debug if Stripe calls are ever added client-side.

**Email PII logged in debug builds:**
- Risk: `AuthService.signIn` logs the user's email address at `.debug` level. On a jailbroken device or in a shared developer environment, this could expose user email addresses in system logs.
- Files: `JobHarvest/Services/AuthService.swift` (line 53, 59, 197)
- Current mitigation: `AppLogger.debug` is guarded by `#if DEBUG`, so it does not appear in release builds.
- Recommendations: Replace logged email addresses with a redacted form (e.g., first character + `***@domain.com`) even in debug logs.

**Account deletion has no additional verification step:**
- Risk: The Delete Account confirmation dialog triggers `AuthService.deleteAccount()` via `try? await`, silently ignoring any errors. If the deletion fails on the server, the app still calls `handleSignOut()`, leaving the user logged out of an account that still exists.
- Files: `JobHarvest/Views/Main/Settings/SettingsView.swift` (lines 89–93)
- Current mitigation: None.
- Recommendations: Propagate and display errors from `deleteAccount()` and require re-authentication (e.g., password re-entry) before deletion.

**Payout flow has no amount minimum or identity verification:**
- Risk: `requestPayout` accepts any `payoutEmail` string and submits directly. There is no client-side minimum balance check (the button is shown when `pendingPayout > 0`, which could be fractions of a cent) or identity verification before submitting financial payout details.
- Files: `JobHarvest/Views/Main/Earn/EarnView.swift` (lines 162–199), `JobHarvest/ViewModels/ReferralViewModel.swift` (lines 34–48)
- Current mitigation: Backend presumably enforces minimums; client trust is low risk since the user is authenticated.
- Recommendations: Add a client-side minimum payout threshold check and display the amount being requested in the confirmation flow.

---

## Performance Bottlenecks

**`htmlDecoded()` runs on the main thread via `NSAttributedString` HTML parsing:**
- Problem: `String.htmlDecoded()` creates an `NSAttributedString` with HTML document type, which is a synchronous, expensive operation. It is called for job descriptions rendered in `JobCardView`.
- Files: `JobHarvest/Utils/Extensions.swift` (lines 30–39)
- Cause: `NSAttributedString` HTML parsing triggers WebKit layout engine on the calling thread. Calling this from a SwiftUI `body` blocks the main thread during card rendering.
- Improvement path: Move HTML decoding to a background task in `JobCardsViewModel.fetchJobs` and store pre-decoded strings on the `Job` model, or replace with a lightweight HTML-strip regex.

**`CompanyLogoView` creates a new `AsyncImage` per render with no disk caching:**
- Problem: `AsyncImage` fetches from `logo.clearbit.com` on every view appearance with no disk or memory cache layer beyond iOS's default `URLCache`. In the card deck (`ApplyView`), three `CompanyLogoView` instances are always on screen; navigating between tabs re-creates them.
- Files: `JobHarvest/Views/Shared/CompanyLogoView.swift`
- Cause: `AsyncImage` does not persist across view identity changes or tab switches.
- Improvement path: Replace `AsyncImage` with a caching image loader (e.g., `SDWebImageSwiftUI` or a custom `NSCache`-backed loader).

**Every `/users/{id}/profile` update sends the full profile object:**
- Problem: `updateProfile` and `uploadResume` in `ProfileViewModel` both POST the entire `UserProfile` struct to the backend. For a user with long work history and skills arrays, this is a large payload for what may be a single field change.
- Files: `JobHarvest/ViewModels/ProfileViewModel.swift` (lines 35–55, 71–90)
- Cause: No partial-update (PATCH) endpoint is used; the full model is always sent.
- Improvement path: Implement a PATCH endpoint on the backend and send only the changed fields, or at minimum use `Encodable` with custom `CodingKeys` to omit nil fields.

---

## Fragile Areas

**`AppRouter` Hub listener token stored in `@State` on a `struct`:**
- Files: `JobHarvest/App/AppRouter.swift` (line 8, 37–54)
- Why fragile: `hubToken` is stored as `@State private var hubToken: UnsubscribeToken?`. The `onDisappear` cleanup assumes the view disappears exactly once. If SwiftUI recreates `AppRouter` (possible during scene transitions), the old token is leaked and `listenToAuthEvents()` registers a second listener, causing duplicate auth-event handling.
- Safe modification: Store the hub listener token in `AuthViewModel` (an `ObservableObject` with a stable lifetime) rather than in view state.
- Test coverage: No tests exist for auth event handling.

**`JobCardsViewModel.fetchJobs` is not re-entrant safe for the prefetch path:**
- Files: `JobHarvest/ViewModels/JobCardsViewModel.swift` (lines 20–64, 72–73)
- Why fragile: `handleSwipe` spawns a prefetch via `Task { await fetchJobs(appending: true) }` (line 73). The guard on line 21 (`guard !isLoading`) uses `isLoading`, but `isPrefetching` is a separate flag. If `handleSwipe` is called rapidly (multiple swipes before the prefetch completes), `isPrefetching` is checked on line 72 but `isLoading` could still be false, allowing a second non-appending fetch to begin concurrently with the prefetch.
- Safe modification: Use a single `isFetching` flag that guards both paths, or use Swift's `actor` isolation for the fetch state.
- Test coverage: None.

**`PreferencesQuizView` creates its own `@StateObject private var profileVM`:**
- Files: `JobHarvest/Views/Onboarding/PreferencesQuizView.swift` (line 8)
- Why fragile: `PreferencesQuizView` instantiates a private `ProfileViewModel` rather than receiving one via `@EnvironmentObject`. After `submitProfile()` completes and `AppRouter` transitions to `MainTabView`, `MainTabView` creates a separate `ProfileViewModel` instance that has no knowledge of the profile just saved, causing a redundant fetch on first load.
- Safe modification: Pass the existing `ProfileViewModel` as an environment object from `AppRouter` or use a shared singleton pattern consistent with the rest of the app.
- Test coverage: None.

**`DocumentPickerView` reads file data on the main thread via `Data(contentsOf:)`:**
- Files: `JobHarvest/Views/Onboarding/PreferencesQuizView.swift` (line 74)
- Why fragile: `Data(contentsOf: url)` is a synchronous I/O call executed in `documentPicker(_:didPickDocumentsAt:)` on the main thread. For large PDFs (multi-MB resumes), this blocks the UI.
- Safe modification: Wrap the `Data(contentsOf:)` call in `Task { await MainActor.run { ... } }` or dispatch it to a background queue.
- Test coverage: None.

**`ChangeEmailView` does not update `AuthViewModel.email` after successful confirmation:**
- Files: `JobHarvest/Views/Main/Settings/SettingsView.swift` (lines 143–145)
- Why fragile: After `confirmEmailUpdate(code:)` succeeds, the view is dismissed but `authVM.email` still holds the old address. Any UI relying on `authVM.email` (e.g., a future profile display) will show stale data until the next `checkAuthState()` call.
- Safe modification: Call `await authVM.checkAuthState()` after a successful email update, or update `authVM.email` directly.
- Test coverage: None.

---

## Scaling Limits

**In-memory pipeline state in `AppliedJobsViewModel`:**
- Current capacity: The entire applied-jobs pipeline is loaded into memory as 7 separate `@Published` arrays on first fetch.
- Limit: Users with hundreds or thousands of applied jobs (likely for power users over many months) will hold all of them in memory simultaneously. The pipeline horizontal scroll view renders all columns at once.
- Scaling path: Implement server-side pagination per pipeline stage; render columns lazily using `LazyHStack`.

**`MailboxViewModel` appends emails indefinitely:**
- Current capacity: Paginated via `bookmarkTimestamp`, but all loaded pages are kept in the `emails` array for the lifetime of the `MailboxViewModel` instance (which persists across tab switches as `@StateObject` in `MainTabView`).
- Limit: Heavy email users will accumulate large arrays in memory after multiple "load more" calls.
- Scaling path: Implement a sliding window: remove oldest items from the array as new pages are appended.

---

## Dependencies at Risk

**`amplify-swift` 2.x (AWS Cognito + S3):**
- Risk: Amplify 2.x is a major version with a large dependency footprint. AWS regularly releases breaking changes across major versions. The `AWSS3StoragePlugin` is imported in `FlashApplyApp.swift` but file upload goes directly through presigned URLs via `NetworkService`; S3 SDK may be an unused dependency.
- Impact: Build times; potential conflicts with Swift Package Manager resolution.
- Migration plan: Audit whether `AWSS3StoragePlugin` is actively used (presigned URL uploads do not require it); remove if unused. Pin to a specific minor version in `Package.resolved`.

**Clearbit logo API (unauthenticated third-party):**
- Risk: `CompanyLogoView` calls `https://logo.clearbit.com/{domain}` without authentication or rate-limiting. Clearbit has changed its free tier terms historically and may begin returning errors or require API keys.
- Impact: All company logos fall back to a placeholder icon if Clearbit is unavailable or rate-limited.
- Migration plan: Cache successfully fetched logos on-device; have a fallback logo strategy that does not require a live network call.

---

## Test Coverage Gaps

**Zero meaningful tests exist:**
- What's not tested: All business logic — auth state machine, swipe handling, profile update/revert, pipeline stage transitions, subscription status, email pagination, referral payouts.
- Files: `JobHarvest/JobHarvestTests/JobHarvestTests.swift` (line 13: empty `example()` test), `JobHarvest/JobHarvestUITests/JobHarvestUITests.swift`, `JobHarvest/JobHarvestUITests/JobHarvestUITestsLaunchTests.swift`
- Risk: Any refactor to ViewModels or Services has no safety net. The swipe mechanic, profile save/revert, and auth flow are all untested critical paths.
- Priority: High — especially for `JobCardsViewModel.handleSwipe`, `ProfileViewModel.updateProfile` (optimistic revert), and `AuthViewModel.checkAuthState`.

**`FlowLayout` height calculation is untested:**
- What's not tested: The heuristic height formula `max(CGFloat(items.count / 3 + 1) * 28, 28)` for varying chip counts and label lengths.
- Files: `JobHarvest/Views/Main/Apply/JobCardView.swift` (line 355)
- Risk: Layout regressions across device sizes go undetected.
- Priority: Medium — snapshot tests would catch visual regressions.

**Network layer has no mock/stub infrastructure:**
- What's not tested: `NetworkService.execute`, error-path handling (401, 403, 5xx), timeout behavior, decode failures.
- Files: `JobHarvest/Services/NetworkService.swift`
- Risk: Changes to error handling or token attachment are invisible until a production incident.
- Priority: High — inject a `URLSession` mock via a protocol to enable unit testing of all network paths.

---

*Concerns audit: 2026-03-11*
