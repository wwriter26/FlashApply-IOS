# Milestones

## v1.0 MVP (Shipped: 2026-04-01)

**Phases completed:** 4 phases, 11 plans, 17 tasks

**Key accomplishments:**

- Fixed xcconfig API_DOMAIN typo routing all traffic to production, added #if DEBUG fatalError guards for misconfigured API_DOMAIN and Amplify config failure, and created developer onboarding templates.
- One-liner:
- 5-step onboarding wizard with FlowLayout skills tag picker, UserDefaults state persistence, and correct merge-before-upload profile submit ordering
- Error humanization extension, branded logo pulse LoadingView, reusable ErrorBannerView, and JobFilters Equatable — shared UX primitives consumed by all Plans 02-05
- One-liner:
- Plan bridge (PAY-02):
- One-liner:
- Humanized error strings in all user-facing catch blocks across ViewModels and Views; MailboxView ErrorBannerView added; all tabs confirmed to have loading, error, and empty states
- FIFO-bounded seenUrls (500-entry cap with Array+Set eviction) and Amplify Hub listener moved from SwiftUI AppRouter into AuthViewModel.init for exactly-once registration
- One-liner:

---
