# Phase 02: Auth and Profile Foundation - Research

**Researched:** 2026-03-15
**Domain:** SwiftUI MVVM — Amplify Cognito auth routing, EnvironmentObject sharing, Codable debugging, onboarding wizard state
**Confidence:** HIGH (all findings based on direct code inspection of the existing codebase)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Data Persistence Fixes**
- API calls return 200 but profile data doesn't populate UI — likely a Codable decoding mismatch between backend response shape and `UserProfile` struct. Must diagnose and fix the decode path.
- Resume upload to S3 succeeds but metadata POST to `/users/{id}/profile` either fails silently or response isn't reflected. Fix the save chain: S3 upload → metadata POST → re-fetch to confirm.
- Profile tab must also support resume re-upload (not just onboarding) — users need to replace their resume from the Profile tab.

**Shared ProfileViewModel**
- Single shared ProfileViewModel created at the app level (in `FlashApplyApp.swift`), injected everywhere via `@EnvironmentObject`.
- Onboarding and Profile tab share the same instance — no more dual ProfileViewModel where onboarding data is discarded on view disappear.
- After onboarding saves data, the shared VM already has it — no refetch needed on transition to MainTabView.

**New vs Returning User Routing**
- Current routing works: existing users land on main tabs, new users see onboarding.
- On network error checking `firstLogin` attribute: assume new user, show onboarding (safer — worst case returning user sees quiz again).
- Session persists across app restarts (Amplify stored tokens). User stays signed in until explicit sign-out or token expiry.
- After onboarding completion: show a brief "Getting things ready..." loading moment (1-2 seconds) while profile syncs, then transition to main tabs.

**Onboarding Quiz Completeness**
- Match the web app exactly — add any missing fields so iOS and web users have identical profiles.
- Wire up the dead skills/preferences step (ONBD-02) as a multi-select tag picker with pre-defined skill tags.
- Validation: Resume + Name are required and block advancement. All other steps are optional/skippable.
- Quiz state saved locally on background — user resumes where they left off (not start over).
- All onboarding data must be successfully saved to the backend on completion (ONBD-03).

**Sign-Out & Session Cleanup**
- Sign-out requires confirmation alert ("Are you sure you want to sign out?").
- On sign-out: clear EVERYTHING — all ViewModels (profile, jobs, mailbox), cached data, local state. Clean slate.
- On re-sign-in: fresh fetch from backend for all data. No stale cache.

### Claude's Discretion
- Exact approach to diagnose and fix the Codable decoding issue (may need to log raw response and compare to model)
- Loading skeleton/spinner design during profile fetch
- Error state handling for failed profile loads
- Exact implementation of quiz state persistence (in-memory vs UserDefaults)
- Transition animation from onboarding to main tabs

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | User can sign in with existing account and reach the main app | AuthViewModel.signIn + checkAuthState already work; verify flow end-to-end |
| AUTH-02 | New user is correctly routed to onboarding quiz (not skipped on network error) | `isFirstLogin()` currently returns `false` on error — must flip to `true` (show onboarding) |
| AUTH-03 | Returning user bypasses onboarding and goes directly to main tabs | AppRouter already handles this via `authVM.isNewUser`; verify correct after AUTH-02 fix |
| AUTH-04 | User session persists across app restarts | Amplify stores tokens — `fetchAuthSession` in `isSignedIn()` handles this; verify no regression |
| AUTH-05 | Sign-out clears all local state and returns user to sign-in screen | `handleSignOut()` only clears authVM fields — must also reset profileVM and other VMs |
| ONBD-01 | Onboarding collects all required fields: name, phone, work authorization, job type preferences, resume upload | All five fields present in `PreferencesQuizView`; wire skills step and add missing fields |
| ONBD-02 | Skills/preferences step is present and functional in the quiz (currently dead state variable) | `skills` state var exists but step 5 only shows job type/remote — need tag picker UI |
| ONBD-03 | Onboarding data successfully saved to backend on completion | `submitProfile()` calls `updateProfile()` — must verify it doesn't silently skip skills |
| ONBD-04 | Progress preserved if user backgrounds the app mid-quiz | No persistence today — need UserDefaults (or in-memory is acceptable per Claude's discretion) |
| ONBD-05 | Each quiz step has clear validation — user cannot advance with invalid input | `canAdvance` only blocks steps 0 and 1; step 2 (Name) requires resume first — review gate logic |
</phase_requirements>

---

## Summary

Phase 2 is a refactor-and-fix phase, not a greenfield build. The core SwiftUI architecture (MVVM, EnvironmentObject injection, Amplify Hub listener, AppRouter) is already in place and working for happy-path flows. The work is concentrated in three areas: (1) fixing a network error handling bug that causes new users to be misrouted, (2) lifting `ProfileViewModel` from a locally-scoped object to a shared app-level instance, and (3) completing the onboarding quiz with a functional skills step and quiz-state persistence.

The most critical bug is in `AuthService.isFirstLogin()`: on network failure it currently returns `false`, which routes a new user to the main tab view skipping onboarding entirely. The fix is one line — return `true` on error. The second critical bug is in `ProfileViewModel.uploadResume()`: the metadata POST to `/users/{id}/profile` uses the in-memory `profile` struct which may not yet have `resumeFileName` if the S3 upload key differs from the local file name. The save chain needs a re-fetch after the POST to confirm persistence.

The `ProfileViewModel` duplication is structural: `FlashApplyApp.swift` creates only `authVM`, `MainTabView` creates its own `@StateObject private var profileVM`, and `PreferencesQuizView` creates yet another `@StateObject private var profileVM`. Each instance has independent state. The fix is to create one `@StateObject private var profileVM = ProfileViewModel()` in `FlashApplyApp.swift`, pass it as `.environmentObject(profileVM)` alongside `authVM`, then change both `MainTabView` and `PreferencesQuizView` to use `@EnvironmentObject var profileVM: ProfileViewModel`.

**Primary recommendation:** Fix the three bugs (isFirstLogin error path, ProfileViewModel duplication, resume save chain) in sequential tasks — each is a contained change to a known file. Complete onboarding with skills tags last.

---

## Standard Stack

### Core (already in project — no new dependencies needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 16+ | Declarative UI | Project standard |
| Amplify Swift | 2.x | Cognito auth, S3 storage | Already configured |
| AWSCognitoAuthPlugin | 2.x | Token management, custom attributes | Used for firstLogin attribute |
| Foundation | system | URLSession, Codable, UserDefaults | No third-party needed for quiz persistence |

### No New Dependencies Required

All functionality needed for this phase can be achieved with the existing stack. The skills tag picker can be built with SwiftUI `FlowLayout` (already used in `SkillsSection.swift`). Quiz state persistence requires only `UserDefaults` (Foundation). No new SPM packages are needed.

---

## Architecture Patterns

### Recommended Project Structure (changes only)

```
JobHarvest/
├── App/
│   └── FlashApplyApp.swift       # ADD: @StateObject profileVM, inject as .environmentObject
├── ViewModels/
│   └── ProfileViewModel.swift    # ADD: reset() method for sign-out cleanup
├── Views/Onboarding/
│   └── PreferencesQuizView.swift # CHANGE: @StateObject → @EnvironmentObject for profileVM
│                                 # ADD: skills tag step, UserDefaults persistence
└── Views/Main/
    └── MainTabView.swift         # CHANGE: remove @StateObject profileVM, use @EnvironmentObject
```

### Pattern 1: Shared EnvironmentObject at App Root

**What:** Create a single `ProfileViewModel` in `FlashApplyApp.body` alongside `AuthViewModel` and inject it into the root view.

**When to use:** Any ViewModel that must be shared across sibling subtrees (onboarding and main tabs are siblings under `AppRouter`, not parent-child).

**Example (exact change to FlashApplyApp.swift):**
```swift
// Source: direct code inspection of JobHarvest/App/FlashApplyApp.swift
@main
struct JobHarvestApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var profileVM = ProfileViewModel()   // ADD THIS

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authVM)
                .environmentObject(profileVM)                 // ADD THIS
                .preferredColorScheme(.light)
        }
    }
}
```

**Consuming side (PreferencesQuizView and MainTabView):**
```swift
// BEFORE (creates isolated instance):
@StateObject private var profileVM = ProfileViewModel()

// AFTER (uses shared instance):
@EnvironmentObject var profileVM: ProfileViewModel
```

### Pattern 2: VM Reset on Sign-Out

**What:** `AuthViewModel.handleSignOut()` must trigger a reset on all shared ViewModels. Since `ProfileViewModel` is now injected at the app root alongside `authVM`, the cleanest path is to give `ProfileViewModel` a `reset()` method and call it from `handleSignOut()` — or have `AppRouter` observe `authVM.isSignedIn` and reset the profile VM when it transitions to false.

**When to use:** Any time sign-out must guarantee a clean slate.

**Example:**
```swift
// In ProfileViewModel.swift — ADD:
func reset() {
    profile = UserProfile()
    isLoaded = false
    isLoading = false
    isSaving = false
    error = nil
}
```

The simplest wiring: pass `profileVM` into `AuthViewModel` or use the `.onChange(of: authVM.isSignedIn)` modifier in `AppRouter` to call `profileVM.reset()` when the user signs out.

### Pattern 3: isFirstLogin Error-Safe Routing (AUTH-02 fix)

**What:** Return `true` (new user) when the Cognito attribute fetch fails — guarantees onboarding is shown, not skipped.

**Current bug location:** `JobHarvest/Services/AuthService.swift`, line 195:
```swift
// CURRENT (wrong on error):
return false  // error path sends user to main tab — WRONG for new users

// FIXED:
return true   // on error, assume new user — worst case returning user sees quiz once more
```

### Pattern 4: Resume Save Chain Fix (PROF-04 prerequisite)

**What:** The current `uploadResume()` in `ProfileViewModel` sets `profile.resumeFileName = fileName` and then immediately POSTs `profile` to the backend. The bug risk: if the `profile` object doesn't yet reflect previous backend state (because `fetchProfile()` failed silently), the POST overwrites all other profile fields with empty/nil values.

**Fix pattern:**
```swift
// In ProfileViewModel.uploadResume() — after the POST succeeds:
// Re-fetch to confirm persistence and sync any server-side transformations
await fetchProfile()
```

This ensures the UI reflects the true backend state after the upload chain completes.

### Pattern 5: Codable Decode Debugging

**What:** `NetworkService.execute()` already logs raw response on decode failure. The bug is most likely a key name mismatch or a wrapper object the model doesn't expect. The diagnostic path is:

1. Enable DEBUG build and trigger `GET /users/{id}/profile`
2. The existing log at `NetworkService` line 147 will print `raw:` with the full JSON
3. Compare JSON keys to `UserProfile` property names in `Models/User.swift`
4. Common mismatches: snake_case backend (`resume_file_name`) vs camelCase Swift (`resumeFileName`) — `JSONDecoder()` uses default key strategy (no `convertFromSnakeCase`), so keys must match exactly

**Fix if snake_case backend:**
```swift
// In ProfileViewModel.fetchProfile() — switch decoder:
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let response = try decoder.decode(UserProfile.self, from: data)
```

Or: add `CodingKeys` enum to `UserProfile`. The approach depends on what the raw log reveals.

**Important:** `NetworkService.performRequest()` uses `JSONEncoder().encode(body)` with default key strategy (camelCase output). If the backend expects snake_case on POST, outgoing POSTs are also broken. Both the encoder and decoder strategies must match the API contract.

### Pattern 6: Quiz State Persistence (ONBD-04)

**What:** Save current quiz step and partially-entered values so the user can background and resume.

**Recommended approach:** UserDefaults (Claude's discretion). Store as a lightweight dict — avoids Codable complexity for transient quiz state.

**When to clear:** On `submitProfile()` success AND on skip. Never persist across sign-out (clear in `reset()` or on `handleSignOut()`).

```swift
// In PreferencesQuizView — save on any @State change:
.onChange(of: currentStep) { step in
    UserDefaults.standard.set(step, forKey: "quiz_currentStep")
}

// On appear — restore:
.onAppear {
    currentStep = UserDefaults.standard.integer(forKey: "quiz_currentStep")
}
```

### Pattern 7: Skills Tag Picker (ONBD-02)

**What:** Step 5 of the quiz (`step5_Preferences`) already has a `skills: [String]` state variable but shows no UI for it. The `FlowLayout` + tag chip pattern already exists in `SkillsSection.swift` — reuse it.

**Recommended tag list (pre-defined, not free-text for onboarding):**
```swift
private let suggestedSkills = [
    "Python", "JavaScript", "Swift", "Java", "SQL",
    "React", "Node.js", "AWS", "Machine Learning",
    "Project Management", "Data Analysis", "Excel",
    "Communication", "Leadership", "Marketing"
    // expand based on web app's tag list
]
```

Multi-select: tapping a tag toggles it in/out of the `skills` array. Include `skills` in the `submitProfile()` build when constructing the `UserProfile`.

### Anti-Patterns to Avoid

- **`@StateObject` for shared ViewModels:** Using `@StateObject` in a child view creates a new, isolated instance. Only use `@StateObject` in the view that owns the lifetime (app root). Everywhere else: `@EnvironmentObject`.
- **Optimistic update without re-fetch on resume upload:** `uploadResume()` sets `profile.resumeFileName` in memory and POSTs, but if the user force-quits and re-opens, only the backend state matters. Always re-fetch after a successful write to uploads.
- **Clearing `isLoaded = false` in `reset()` without also setting `profile = UserProfile()`:** The ProfileView has `if !profileVM.isLoaded { await profileVM.fetchProfile() }` — if `isLoaded` is left true after sign-out, the stale previous user's profile persists until next explicit fetch.
- **Silent Codable errors in production:** The current decoder throws `NetworkError.decodingFailed` which logs to `AppLogger` but never surfaces to the user. For profile fetch, this manifests as "blank profile" with no error message. Add a user-visible error state in `ProfileView` for when `profileVM.error != nil`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tag flow layout | Custom `HStack` wrapping with frame math | `FlowLayout` already in `SkillsSection.swift` | Already built and used in project |
| Document picker | Native file picker | `DocumentPickerView` already in `PreferencesQuizView.swift` | Already built, handles security-scoped resource access |
| Auth token injection | Manual token fetch per request | `NetworkService.request()` | Already handles token fetch, retry, header injection |
| S3 file upload | Manual multipart/presigned URL | `FileUploadService.uploadResume()` | Already wraps Amplify.Storage |
| Confirmation alert | Custom modal | SwiftUI `.confirmationDialog()` | Used throughout app — consistent pattern |

**Key insight:** This codebase has all infrastructure pieces in place. The phase is about wiring existing components correctly, not building new infrastructure.

---

## Common Pitfalls

### Pitfall 1: EnvironmentObject Not Injected for PreferencesQuizView

**What goes wrong:** `PreferencesQuizView` is rendered from `AppRouter` directly. After moving `profileVM` to `@EnvironmentObject`, if `AppRouter` doesn't propagate it (it currently only gets `authVM`), the app will crash at runtime with "No ObservableObject of type ProfileViewModel found."

**Why it happens:** `AppRouter` is injected with `authVM` in `FlashApplyApp.body`. `PreferencesQuizView` is a child of `AppRouter`. EnvironmentObjects propagate down the view hierarchy — `profileVM` must be injected at or above `AppRouter`.

**How to avoid:** Inject `profileVM` in `FlashApplyApp.body` at the same level as `authVM`. This propagates through `AppRouter` to both `PreferencesQuizView` and `MainTabView` automatically.

**Warning signs:** Crash on first login flow during testing.

### Pitfall 2: ProfileViewModel.reset() Called Before Amplify Sign-Out Completes

**What goes wrong:** `authVM.signOut()` calls `auth.signOut()` (async) then `handleSignOut()` (sync). If `profileVM.reset()` is wired to `handleSignOut()`, and `handleSignOut()` runs before Amplify has invalidated the session, subsequent `fetchProfile()` calls (triggered by `isLoaded = false`) could fire with a still-valid token fetching the old user's data.

**How to avoid:** Call `profileVM.reset()` inside `handleSignOut()` but do not trigger a new `fetchProfile()` from there. Let `profileVM.isLoaded = false` sit quietly — the next fetch only happens when the new user signs in and navigates to a profile-consuming view.

### Pitfall 3: JSONDecoder Key Strategy Mismatch

**What goes wrong:** `GET /users/{id}/profile` returns JSON with snake_case keys (e.g., `resume_file_name`). Swift's `Codable` with default `JSONDecoder()` expects exact key matches. All fields silently decode to `nil`. The response is `200 OK`, no error is thrown, but `UserProfile` is all-nil.

**Why it happens:** `NetworkService.execute()` uses `JSONDecoder()` with no key decoding strategy. `UserProfile` uses camelCase Swift properties with no `CodingKeys`.

**How to avoid:** Run the app in DEBUG, trigger a profile fetch, and read the `raw:` log in `NetworkService`. If keys are snake_case, either: (a) add `decoder.keyDecodingStrategy = .convertFromSnakeCase` to `NetworkService.execute()`, or (b) add explicit `CodingKeys` to `UserProfile`. Option (a) affects all responses globally — verify it doesn't break other decoders.

**Warning signs:** `completionPercentage` returns 0% for a user with a known complete profile.

### Pitfall 4: isFirstLogin Attribute Not Set for Cognito Users Created Before This App Version

**What goes wrong:** The `firstLogin` custom attribute is set during `AuthService.signUp()`. Users who signed up through the web app or before this attribute existed will not have `custom:firstLogin` in their Cognito user pool attributes. `isFirstLogin()` returns `attrs[key]` which will be `nil` for these users. `value != "false"` → `nil != "false"` → `true` → treated as new user.

**Why this matters:** AUTH-02 fix (return `true` on error) is correct. But returning `true` when the attribute is absent (not an error, just missing) will route all pre-existing web users through onboarding on first iOS sign-in. This is a known side-effect — the CONTEXT.md decision says "worst case returning user sees quiz again" which accepts this.

**How to avoid:** Accept the behavior per CONTEXT.md. The user will see the skip button. Ensure the skip path is clean (`markOnboardingComplete()` sets the attribute to "false" so it won't happen again).

### Pitfall 5: Quiz Skip + Shared ViewModel Interaction

**What goes wrong:** User taps Skip in the quiz. `markOnboardingComplete()` sets `authVM.isNewUser = false`. `AppRouter` transitions to `MainTabView`. `MainTabView` now uses the shared `profileVM`. If `profileVM.isLoaded` is `false` (never fetched during onboarding because user skipped), `ProfileView` triggers `fetchProfile()` on appear — which is correct behavior.

**Potential issue:** If `profileVM.profile` still has the partially-entered quiz state (firstName, etc. from step 2), and `isLoaded` is false, `fetchProfile()` will overwrite it. This is desirable — on skip, we want backend state.

**Warning signs:** None — this is correct behavior. Document it so implementers don't "fix" it.

### Pitfall 6: Resume Upload Chain Race Condition

**What goes wrong:** In the current `ProfileViewModel.uploadResume()`, after the metadata POST:
```swift
profile.resumeFileName = fileName        // (1) set in memory
let _: MessageResponse = try await network.request(...)  // (2) POST profile
```
If the POST uses `body: profile` which already has other fields, and those fields are nil/empty (because `fetchProfile()` never succeeded), the POST body overwrites the entire profile with nulls.

**How to avoid:** Before calling `uploadResume()` from `ResumeSection` or `PreferencesQuizView`, ensure `fetchProfile()` has been called at least once to populate the full `profile` object. In the shared VM model, `fetchProfile()` is called on app transition to main tabs — but in onboarding, this hasn't happened yet. The safest fix: in `uploadResume()`, only send the resume-specific fields (partial update), not the full `profile` struct.

---

## Code Examples

### Verified Pattern: Promoting profileVM to App-Level EnvironmentObject

```swift
// Source: direct inspection — FlashApplyApp.swift
// CURRENT state:
@StateObject private var authVM = AuthViewModel()
// profileVM is NOT here — it lives in MainTabView and PreferencesQuizView

// TARGET state:
@StateObject private var authVM = AuthViewModel()
@StateObject private var profileVM = ProfileViewModel()

var body: some Scene {
    WindowGroup {
        AppRouter()
            .environmentObject(authVM)
            .environmentObject(profileVM)
            .preferredColorScheme(.light)
    }
}
```

### Verified Pattern: Consuming EnvironmentObject (change in MainTabView)

```swift
// Source: direct inspection — MainTabView.swift line 10
// BEFORE:
@StateObject private var profileVM = ProfileViewModel()

// AFTER:
@EnvironmentObject var profileVM: ProfileViewModel

// Note: the .environmentObject(profileVM) calls on ApplyView and ProfileView
// can be REMOVED since it flows down from the root automatically.
// Or keep them for clarity — both work. Remove is cleaner.
```

### Verified Pattern: ProfileViewModel.reset() for sign-out

```swift
// Source: design based on ProfileViewModel.swift inspection
// ADD to ProfileViewModel:
func reset() {
    profile = UserProfile()
    isLoaded = false
    isLoading = false
    isSaving = false
    error = nil
}
```

### Verified Pattern: Wire reset() on sign-out in AppRouter

```swift
// Source: design based on AppRouter.swift inspection
struct AppRouter: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel  // ADD

    var body: some View {
        Group { ... }
        .onChange(of: authVM.isSignedIn) { isSignedIn in
            if !isSignedIn {
                profileVM.reset()
            }
        }
    }
}
```

### Verified Pattern: isFirstLogin Fix (AUTH-02)

```swift
// Source: AuthService.swift lines 188-199 — CURRENT:
func isFirstLogin() async -> Bool {
    do {
        let attrs = try await getUserAttributes()
        let key = AuthUserAttributeKey.custom("firstLogin")
        let value = attrs[key]
        return value != "false"
    } catch {
        AppLogger.auth.error("isFirstLogin: ... defaulting to false")
        return false   // BUG: new users get routed to main tab on network error
    }
}

// FIXED catch block:
    } catch {
        AppLogger.auth.error("isFirstLogin: ... defaulting to true (assume new user)")
        return true    // safe default — worst case returning user sees quiz once
    }
```

### Verified Pattern: Skills Tag Picker for Onboarding Step

```swift
// Source: design based on SkillsSection.swift FlowLayout pattern
// ADD inside step5_Preferences in PreferencesQuizView:
Text("Skills").font(.headline)
FlowLayout(items: suggestedSkills) { skill in
    Button(action: {
        if skills.contains(skill) {
            skills.removeAll { $0 == skill }
        } else {
            skills.append(skill)
        }
    }) {
        Text(skill)
            .font(.callout)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(skills.contains(skill) ? Color.flashTeal : Color.flashTeal.opacity(0.1))
            .foregroundColor(skills.contains(skill) ? .white : .flashTeal)
            .cornerRadius(20)
    }
    .buttonStyle(.plain)
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| Local `@StateObject profileVM` per view | Shared `@EnvironmentObject profileVM` at app root | Eliminates redundant fetches, data discards on view pop |
| `isFirstLogin` returns false on error | Returns true on error | New users correctly see onboarding even on flaky networks |
| Blind metadata POST with potentially empty profile | POST with known-complete profile + re-fetch | Resume upload persists reliably |
| Skills `@State var skills` with no UI | Tag-picker step in quiz | ONBD-02 satisfied |

**Known outdated in current codebase:**
- `PreferencesQuizView` uses `@StateObject` for profileVM — this is the wrong pattern for a shared resource
- `MainTabView` duplicates profileVM creation — this creates a second network fetch on every main-tab load
- `AuthService.isFirstLogin()` error path routes new users incorrectly

---

## Open Questions

1. **Backend JSON key format (snake_case vs camelCase)**
   - What we know: Profile fetch returns 200 but UI stays blank; `NetworkService` logs raw response on decode error
   - What's unclear: Whether backend uses `resume_file_name` or `resumeFileName` in the response body
   - Recommendation: First task must be to trigger a profile fetch in DEBUG and read the AppLogger output. This determines whether a `keyDecodingStrategy` fix is needed globally or per-decoder.

2. **Partial profile POST vs full profile POST**
   - What we know: `updateProfile()` sends the entire `UserProfile` struct in every POST
   - What's unclear: Whether the backend merges (patch semantics) or replaces (put semantics) on POST to `/users/{id}/profile`
   - Recommendation: If backend replaces, sending a profile with nil fields from a fresh onboarding submit would erase existing data. The implementer must verify: does a POST with `firstName: "Jake", resumeFileName: nil` clear the resume on the backend? If yes, the submit must first fetch, then merge, then POST.

3. **Skills tag list alignment with backend job-matching algorithm**
   - What we know: The `skills` field is `[String]?` in `UserProfile` — free-form strings
   - What's unclear: Whether the backend job-matching algorithm expects specific canonical skill strings
   - Recommendation: For Phase 2, use a reasonable predefined list in the tag picker. Backend alignment is not a Phase 2 blocker — the user can always add skills freely from the Profile tab's SkillsSection.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Swift Testing (native, Xcode 16+) — `import Testing` already in `JobHarvestTests.swift` |
| Config file | `JobHarvest/JobHarvestTests/JobHarvestTests.swift` (skeleton exists) |
| Quick run command | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:JobHarvestTests` |
| Full suite command | `xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-02 | `isFirstLogin()` returns `true` on attribute fetch error | unit | `xcodebuild test ... -only-testing:JobHarvestTests/AuthServiceTests/testIsFirstLoginReturnsTrueOnError` | ❌ Wave 0 |
| AUTH-05 | `ProfileViewModel.reset()` clears all state fields | unit | `xcodebuild test ... -only-testing:JobHarvestTests/ProfileViewModelTests/testResetClearsAllState` | ❌ Wave 0 |
| ONBD-02 | Skills array populated when tags are selected in quiz | unit | `xcodebuild test ... -only-testing:JobHarvestTests/PreferencesQuizTests/testSkillsTagToggle` | ❌ Wave 0 |
| ONBD-04 | Quiz step restored from UserDefaults after background | unit | `xcodebuild test ... -only-testing:JobHarvestTests/PreferencesQuizTests/testQuizStepPersistence` | ❌ Wave 0 |
| ONBD-05 | `canAdvance` is false when resume missing on step 0 | unit | `xcodebuild test ... -only-testing:JobHarvestTests/PreferencesQuizTests/testCanAdvanceRequiresResume` | ❌ Wave 0 |
| AUTH-01, AUTH-03, AUTH-04 | Sign-in routing, session persistence | manual-only | N/A — requires live Cognito/simulator | manual |
| ONBD-01, ONBD-03 | Full onboarding data saved to backend | manual-only | N/A — requires live backend | manual |

### Sampling Rate
- **Per task commit:** `xcodebuild test ... -only-testing:JobHarvestTests` (unit tests only, ~30s)
- **Per wave merge:** Full suite including UI tests
- **Phase gate:** All unit tests green + manual verification of auth flows before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `JobHarvest/JobHarvestTests/AuthServiceTests.swift` — covers AUTH-02 (`testIsFirstLoginReturnsTrueOnError`)
- [ ] `JobHarvest/JobHarvestTests/ProfileViewModelTests.swift` — covers AUTH-05 (`testResetClearsAllState`)
- [ ] `JobHarvest/JobHarvestTests/PreferencesQuizTests.swift` — covers ONBD-02, ONBD-04, ONBD-05

Note: `AuthService` and `ProfileViewModel` depend on `Amplify` singletons, making true unit tests difficult without protocols/mocks. The unit tests for AUTH-02 and AUTH-05 can test pure logic (the error-handling return values and the reset method's state changes) by calling the methods directly in a test context — they don't require a live Amplify instance for these specific assertions.

---

## Sources

### Primary (HIGH confidence — direct code inspection)
- `JobHarvest/App/FlashApplyApp.swift` — App root, EnvironmentObject injection point
- `JobHarvest/App/AppRouter.swift` — Auth routing logic, Hub listener
- `JobHarvest/ViewModels/AuthViewModel.swift` — Sign-in/out, checkAuthState, markOnboardingComplete
- `JobHarvest/ViewModels/ProfileViewModel.swift` — fetchProfile, updateProfile, uploadResume, reset gap
- `JobHarvest/Services/AuthService.swift` — isFirstLogin bug location (line 195), setFirstLoginFalse
- `JobHarvest/Models/User.swift` — UserProfile Codable struct, all fields
- `JobHarvest/Services/NetworkService.swift` — Decoder configuration, raw log on error
- `JobHarvest/Services/FileUploadService.swift` — S3 upload chain
- `JobHarvest/Views/Onboarding/PreferencesQuizView.swift` — Current 5-step wizard, skills state gap
- `JobHarvest/Views/Main/MainTabView.swift` — Duplicate profileVM creation
- `JobHarvest/Views/Main/Profile/ProfileView.swift` — isLoaded guard, refreshable pattern
- `JobHarvest/Views/Main/Profile/sections/ResumeSection.swift` — Resume upload UI
- `JobHarvest/Views/Main/Profile/sections/SkillsSection.swift` — FlowLayout tag pattern to reuse
- `JobHarvest/Views/Main/Apply/ApplyView.swift` — profileVM.isLoaded guard, hasResume check

### Secondary (MEDIUM confidence — SwiftUI/Amplify documented behavior)
- SwiftUI `@EnvironmentObject` propagation rules — object must be injected at or above first consumer in view tree
- Amplify Swift `fetchAuthSession()` — returns cached tokens; offline-capable for session persistence (AUTH-04)
- Swift `JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase` — standard Foundation API

---

## Metadata

**Confidence breakdown:**
- Bug locations: HIGH — confirmed by reading exact source lines
- Standard stack: HIGH — no new dependencies; existing stack confirmed sufficient
- Architecture patterns: HIGH — based on existing working patterns in the codebase
- Pitfalls: HIGH — derived from reading the actual code, not speculation
- Open questions (key format, POST semantics): LOW — requires runtime observation to resolve

**Research date:** 2026-03-15
**Valid until:** 2026-04-15 (stable SwiftUI + Amplify 2.x)
