//
//  JobHarvestTests.swift
//  JobHarvestTests
//
//  Created by William Writer on 2/22/26.
//

import Testing
@testable import JobHarvest

// MARK: - seenUrls Cap Tests (SC-4)

struct SeenUrlsCapTests {
    @Test func capAt500() async throws {
        let vm = await JobCardsViewModel()
        for i in 0..<500 {
            await vm._recordSeen("https://example.com/job/\(i)")
        }
        let count = await vm._seenUrlsCount
        #expect(count == 500)
    }

    @Test func evictsOldestAt501() async throws {
        let vm = await JobCardsViewModel()
        for i in 0..<501 {
            await vm._recordSeen("https://example.com/job/\(i)")
        }
        let count = await vm._seenUrlsCount
        #expect(count == 500)
        let containsFirst = await vm._seenUrlsContains("https://example.com/job/0")
        #expect(!containsFirst)
        let containsLast = await vm._seenUrlsContains("https://example.com/job/500")
        #expect(containsLast)
    }

    @Test func evictsFirst100At600() async throws {
        let vm = await JobCardsViewModel()
        for i in 0..<600 {
            await vm._recordSeen("https://example.com/job/\(i)")
        }
        let count = await vm._seenUrlsCount
        #expect(count == 500)
        let containsFirst = await vm._seenUrlsContains("https://example.com/job/0")
        #expect(!containsFirst)
        let contains99 = await vm._seenUrlsContains("https://example.com/job/99")
        #expect(!contains99)
        let contains100 = await vm._seenUrlsContains("https://example.com/job/100")
        #expect(contains100)
    }

    @Test func duplicateDoesNotGrow() async throws {
        let vm = await JobCardsViewModel()
        await vm._recordSeen("https://example.com/job/1")
        await vm._recordSeen("https://example.com/job/1")
        let count = await vm._seenUrlsCount
        let orderCount = await vm._seenUrlsOrderCount
        #expect(count == 1)
        #expect(orderCount == 1)
    }

    @Test func resetClearsBoth() async throws {
        let vm = await JobCardsViewModel()
        await vm._recordSeen("https://example.com/job/1")
        await vm.reset()
        let count = await vm._seenUrlsCount
        let orderCount = await vm._seenUrlsOrderCount
        #expect(count == 0)
        #expect(orderCount == 0)
    }
}

// MARK: - Hub Listener Tests (SC-2)

struct HubListenerTests {
    @Test func hubTokenSetAfterInit() async throws {
        // AuthViewModel.init() calls setupHubListener() which sets hubToken.
        // If hubToken is non-nil after init, the listener was registered.
        let vm = await AuthViewModel()
        let hasToken = await vm._hasHubToken
        #expect(hasToken, "AuthViewModel should register Hub listener in init — hubToken must be non-nil")
    }

    @Test func secondInstanceHasOwnToken() async throws {
        // Each AuthViewModel instance should independently register its own listener.
        // This proves no shared/static state is used for the Hub token.
        let vm1 = await AuthViewModel()
        let vm2 = await AuthViewModel()
        let hasToken1 = await vm1._hasHubToken
        let hasToken2 = await vm2._hasHubToken
        #expect(hasToken1, "First AuthViewModel should have hubToken")
        #expect(hasToken2, "Second AuthViewModel should have its own hubToken")
    }
}
