# Phase 2: Auth and Profile Foundation - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Users are routed correctly on first run vs. returning run, onboarding collects all required data (matching the web app), and profile state is shared (not duplicated) across the app. This phase also fixes the critical data persistence bugs: profile data not loading for existing users (GET returns 200 but UI stays blank) and resume uploads succeeding to S3 but not persisting metadata to the database.

</domain>

<decisions>
## Implementation Decisions

### Data Persistence Fixes
- API calls return 200 but profile data doesn't populate UI — likely a Codable decoding mismatch between backend response shape and `UserProfile` struct. Must diagnose and fix the decode path.
- Resume upload to S3 succeeds but metadata POST to `/users/{id}/profile` either fails silently or response isn't reflected. Fix the save chain: S3 upload → metadata POST → re-fetch to confirm.
- Profile tab must also support resume re-upload (not just onboarding) — users need to replace their resume from the Profile tab.

### Shared ProfileViewModel
- Single shared ProfileViewModel created at the app level (in `FlashApplyApp.swift`), injected everywhere via `@EnvironmentObject`.
- Onboarding and Profile tab share the same instance — no more dual ProfileViewModel where onboarding data is discarded on view disappear.
- After onboarding saves data, the shared VM already has it — no refetch needed on transition to MainTabView.

### New vs Returning User Routing
- Current routing works: existing users land on main tabs, new users see onboarding.
- On network error checking `firstLogin` attribute: assume new user, show onboarding (safer — worst case returning user sees quiz again).
- Session persists across app restarts (Amplify stored tokens). User stays signed in until explicit sign-out or token expiry.
- After onboarding completion: show a brief "Getting things ready..." loading moment (1-2 seconds) while profile syncs, then transition to main tabs.

### Onboarding Quiz Completeness
- Match the web app exactly — add any missing fields so iOS and web users have identical profiles.
- Wire up the dead skills/preferences step (ONBD-02) as a multi-select tag picker with pre-defined skill tags.
- Validation: Resume + Name are required and block advancement. All other steps are optional/skippable.
- Quiz state saved locally on background — user resumes where they left off (not start over).
- All onboarding data must be successfully saved to the backend on completion (ONBD-03).

### Sign-Out & Session Cleanup
- Sign-out requires confirmation alert ("Are you sure you want to sign out?").
- On sign-out: clear EVERYTHING — all ViewModels (profile, jobs, mailbox), cached data, local state. Clean slate.
- On re-sign-in: fresh fetch from backend for all data. No stale cache.

### Claude's Discretion
- Exact approach to diagnose and fix the Codable decoding issue (may need to log raw response and compare to model)
- Loading skeleton/spinner design during profile fetch
- Error state handling for failed profile loads
- Exact implementation of quiz state persistence (in-memory vs UserDefaults)
- Transition animation from onboarding to main tabs

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Auth & Routing
- `JobHarvest/App/AppRouter.swift` — Auth-gated navigation root, drives all routing decisions
- `JobHarvest/App/FlashApplyApp.swift` — App entry point, Amplify config, where shared VMs should be created
- `JobHarvest/ViewModels/AuthViewModel.swift` — Manages isSignedIn, isNewUser, markOnboardingComplete
- `JobHarvest/Services/AuthService.swift` — Amplify Cognito wrapper, firstLogin attribute, token management

### Profile & Data Persistence
- `JobHarvest/ViewModels/ProfileViewModel.swift` — Profile state management, fetchProfile, updateProfile, uploadResume
- `JobHarvest/Models/User.swift` — UserProfile Codable struct, must match backend response shape
- `JobHarvest/Services/NetworkService.swift` — URLSession wrapper, token injection, request methods
- `JobHarvest/Services/FileUploadService.swift` — S3 resume upload via Amplify.Storage

### Onboarding
- `JobHarvest/Views/Onboarding/PreferencesQuizView.swift` — Current 5-step wizard, creates local ProfileVM (must be refactored)

### Profile Tab (resume re-upload)
- `JobHarvest/Views/Main/Profile/ProfileView.swift` — Profile tab root
- `JobHarvest/Views/Main/Profile/ResumeSection.swift` — Resume display and upload UI

### Main Tab Integration
- `JobHarvest/Views/Main/MainTabView.swift` — Currently creates ProfileViewModel (must use shared instead)
- `JobHarvest/Views/Main/Apply/ApplyView.swift` — Calls profileVM.fetchProfile on appear, gates swiping on resume

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProfileViewModel`: Already has fetchProfile(), updateProfile(), uploadResume() — needs to be shared, not duplicated
- `FileUploadService`: S3 upload + resume parsing (parseResume exists but unused — could auto-fill profile)
- `DocumentPickerView`: PDF picker already built, used in onboarding and ResumeSection
- `AppLogger`: Categorized OSLog loggers (auth, network, files, profile) — use for debugging decode issues

### Established Patterns
- MVVM with `@StateObject` + `@EnvironmentObject` injection through view hierarchy
- All authenticated requests via `NetworkService.request<T>()` with automatic Bearer token
- Profile sections follow load-from-VM → edit locally → save-back-to-VM pattern

### Integration Points
- `FlashApplyApp.swift` — Where shared ProfileViewModel should be created (alongside AuthViewModel)
- `AppRouter` — Where onboarding→main transition happens, needs brief loading state
- `MainTabView` — Must stop creating its own ProfileViewModel, use injected one instead
- `PreferencesQuizView` — Must stop creating local ProfileViewModel, use shared one instead

</code_context>

<specifics>
## Specific Ideas

- User reported: "API calls 200 but data doesn't populate" — the GET /users/{id}/profile returns successfully but UserProfile Codable decoding likely fails silently. Priority debug target.
- User reported: "Resume uploads succeed but don't stay" — S3 upload works but the follow-up metadata POST to backend either fails or the response isn't processed. Must fix the full chain.
- Quiz should match the web app fields exactly — compare with web onboarding to identify any missing fields.
- Skills step should use pre-defined tags (multi-select) that align with the job matching algorithm on the backend.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-auth-and-profile-foundation*
*Context gathered: 2026-03-15*
