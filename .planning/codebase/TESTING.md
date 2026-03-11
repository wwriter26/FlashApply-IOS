# Testing Patterns

**Analysis Date:** 2026-03-11

## Test Framework

**Unit Test Runner:**
- Swift Testing framework (`import Testing`) — Xcode 16 / Swift 5.10+ native macro-based framework
- Target: `JobHarvestTests` in `JobHarvest/JobHarvestTests/`
- Config: Xcode scheme `JobHarvest` — no separate config file

**UI Test Runner:**
- XCTest (`import XCTest`) — Apple's UIAutomation framework
- Target: `JobHarvestUITests` in `JobHarvest/JobHarvestUITests/`
- Two test files: `JobHarvestUITests.swift`, `JobHarvestUITestsLaunchTests.swift`

**Assertion Library:**
- Unit tests: Swift Testing `#expect(...)` macro
- UI tests: `XCTAssert` and related `XCT*` functions

**Run Commands:**
```bash
# Run all tests
xcodebuild test -project JobHarvest/JobHarvest.xcodeproj -scheme JobHarvest -destination 'platform=iOS Simulator,name=iPhone 16'

# Open in Xcode (use Product > Test or Cmd+U)
open JobHarvest/JobHarvest.xcodeproj
```

No `xcodebuild test-without-building` or `fastlane` configuration is present.

## Test File Organization

**Location:**
- Unit tests: `JobHarvest/JobHarvestTests/` — separate directory from source, not co-located
- UI tests: `JobHarvest/JobHarvestUITests/` — separate directory

**Naming:**
- Unit test file: `JobHarvestTests.swift`
- UI test files: `JobHarvestUITests.swift`, `JobHarvestUITestsLaunchTests.swift`

**Structure:**
```
JobHarvest/
├── JobHarvestTests/
│   └── JobHarvestTests.swift          # Swift Testing unit tests (@testable import JobHarvest)
└── JobHarvestUITests/
    ├── JobHarvestUITests.swift         # XCTest UI interaction tests
    └── JobHarvestUITestsLaunchTests.swift  # Launch + screenshot tests
```

## Current Test State

**Critical context:** The project has test targets set up but contains no substantive tests. All test files contain only the Xcode-generated stub methods. There are zero assertions against app logic.

`JobHarvestTests.swift` (unit tests):
```swift
import Testing
@testable import JobHarvest

struct JobHarvestTests {
    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
}
```

`JobHarvestUITests.swift` (UI tests):
```swift
final class JobHarvestUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
        // No assertions
    }
}
```

`JobHarvestUITestsLaunchTests.swift` — captures a launch screenshot only:
```swift
@MainActor
func testLaunch() throws {
    let app = XCUIApplication()
    app.launch()
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Launch Screen"
    attachment.lifetime = .keepAlways
    add(attachment)
}
```

## Test Structure (Prescribed Patterns)

When writing new unit tests, use the Swift Testing macro style already present in the project:

```swift
import Testing
@testable import JobHarvest

struct NetworkErrorTests {
    @Test func serverErrorDescription() {
        let error = NetworkError.serverError(404, "Not found")
        #expect(error.errorDescription == "Not found")
    }

    @Test func unauthorizedDescription() {
        let error = NetworkError.unauthorized
        #expect(error.errorDescription == "Session expired. Please sign in again.")
    }
}
```

For async tests, Swift Testing supports `async throws` natively:
```swift
@Test func fetchJobsFiltersEmpty() async throws {
    // arrange + act + assert with #expect(...)
}
```

## Mocking

**No mocking framework is configured.** The project has no `MockNetworkService`, protocol-based injection, or test doubles of any kind.

**What this means in practice:**
- `NetworkService`, `AuthService`, and `FileUploadService` are all concrete singletons with `private init()`, making them impossible to swap out in tests without restructuring
- ViewModels hold hard references to `NetworkService.shared` and `AuthService.shared` — no constructor injection

**To add mocking capability**, the recommended approach consistent with the existing code style would be to introduce protocols:
```swift
protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: String, method: String, body: Encodable?) async throws -> T
}
```
Then inject via initializer, keeping `.shared` for production use.

## Fixtures and Factories

**No test fixtures, factories, or test data helpers exist.** There are no `TestFixtures.swift`, `MockData.swift`, or builder patterns in either test target.

The `Models/` layer (`Job.swift`, `User.swift`, `AppliedJob.swift`) contains straightforward `Codable` structs with all-optional properties, making inline construction for tests relatively straightforward:

```swift
// Example of constructing test data (no factory exists — create inline)
let job = Job(
    jobUrl: "https://example.com/job",
    jobTitle: "iOS Engineer",
    companyName: "Acme Corp",
    // ... all other fields nil
)
```

## Coverage

**Requirements:** None enforced. No minimum coverage threshold is configured.

**View Coverage Report:**
Coverage is available via Xcode's built-in report navigator after running tests with `xcodebuild test`. No external coverage tooling (Codecov, SonarQube) is configured.

## Test Types

**Unit Tests (`JobHarvestTests`):**
- Framework: Swift Testing
- Scope: Logic-level — model validation, error description strings, computed properties (e.g., `UserProfile.completionPercentage`, `PayEstimate.formattedString`, `PipelineStage.backendKey`)
- Currently: Stub only, no real tests

**UI Tests (`JobHarvestUITests`):**
- Framework: XCTest + XCUIApplication
- `continueAfterFailure = false` — stop on first failure
- `runsForEachTargetApplicationUIConfiguration = true` in launch tests (runs for light/dark mode, accessibility sizes)
- Currently: App launch + screenshot only, no navigation or assertion tests

**E2E Tests:** Not present. No Maestro, Detox, or similar framework configured.

## What to Test First (Highest Value Areas)

Based on the codebase, the highest-value unit test targets are pure logic with no network/auth dependencies:

1. **`UserProfile.completionPercentage`** — computed property in `Models/User.swift` with multiple conditional branches
2. **`PayEstimate.formattedString`** — currency formatting logic in `Utils/Extensions.swift`
3. **`NetworkError.errorDescription`** — all enum cases in `Services/NetworkService.swift`
4. **`AuthError.errorDescription`** — all enum cases in `Services/AuthService.swift`
5. **`PipelineStage.backendKey` and `.isActive`** — enum computed properties in `Models/AppliedJob.swift`
6. **`String.isValidEmail`** — regex validation in `Utils/Extensions.swift`
7. **`Date.fromISO(_:)`** — ISO date parsing with fallback in `Utils/Extensions.swift`

---

*Testing analysis: 2026-03-11*
