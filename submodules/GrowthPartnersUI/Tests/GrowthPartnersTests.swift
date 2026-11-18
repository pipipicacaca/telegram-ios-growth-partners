import XCTest
@testable import GrowthPartnersUI

final class GrowthPartnersTests: XCTestCase {
    func testSwapLinkTitleRoundTrip() {
        let title = GrowthPartners.swapLinkTitle(partnerTitle: "Gift Radar")
        XCTAssertEqual(title, "⇄ Gift Radar")
        XCTAssertEqual(GrowthPartners.partnerTitle(fromLinkTitle: title), "Gift Radar")
        XCTAssertNil(GrowthPartners.partnerTitle(fromLinkTitle: "Instagram bio"))
        XCTAssertNil(GrowthPartners.partnerTitle(fromLinkTitle: nil))
    }

    func testSwapLinkTitleFitsInviteLimit() {
        let title = GrowthPartners.swapLinkTitle(partnerTitle: String(repeating: "Very Long Channel Name ", count: 4))
        XCTAssertLessThanOrEqual(title.count, GrowthPartners.maxLinkTitleLength)
        XCTAssertTrue(title.hasSuffix("…"))
    }

    func testSizeScore() {
        XCTAssertEqual(GrowthPartners.sizeScore(ownSubscribers: 1000, partnerSubscribers: 1000), 1.0, accuracy: 0.0001)
        XCTAssertEqual(GrowthPartners.sizeScore(ownSubscribers: 1000, partnerSubscribers: 2000), 0.5, accuracy: 0.0001)
        XCTAssertEqual(GrowthPartners.sizeScore(ownSubscribers: 1000, partnerSubscribers: 500), 0.5, accuracy: 0.0001)
        XCTAssertEqual(GrowthPartners.sizeScore(ownSubscribers: 1000, partnerSubscribers: 4000), 0.0, accuracy: 0.0001)
        XCTAssertEqual(GrowthPartners.sizeScore(ownSubscribers: 0, partnerSubscribers: 4000), 0.0)
    }

    func testSuggestionsPreferSimilarSize() {
        let candidates = [
            GrowthPartnerCandidate(id: 1, title: "Huge", subscribers: 900_000),
            GrowthPartnerCandidate(id: 2, title: "Gift Radar", subscribers: 2140),
            GrowthPartnerCandidate(id: 3, title: "Motion Club", subscribers: 1310),
            GrowthPartnerCandidate(id: 4, title: "Mini App Daily", subscribers: 820),
            GrowthPartnerCandidate(id: 5, title: "NFT Notes", subscribers: 900),
            GrowthPartnerCandidate(id: 4, title: "Mini App Daily", subscribers: 820)
        ]
        let result = GrowthPartners.suggestions(ownSubscribers: 820, candidates: candidates, swappedTitles: ["NFT Notes"])
        XCTAssertEqual(result.map(\.candidate.id), [4, 3, 2])
        XCTAssertFalse(result.contains { $0.candidate.title == "Huge" })
        XCTAssertFalse(result.contains { $0.candidate.title == "NFT Notes" })
    }

    func testEstimatedJoins() {
        XCTAssertEqual(GrowthPartners.estimatedJoins(partnerSubscribers: 10_000), 105)
        XCTAssertEqual(GrowthPartners.estimatedJoins(partnerSubscribers: 0), 0)
        XCTAssertEqual(GrowthPartners.estimatedJoins(partnerSubscribers: -5), 0)
    }

    func testSummaryCountsOnlySwapLinks() {
        let links = [
            GrowthPartnersLink(link: "t.me/+a", title: "⇄ NFT Notes", joined: 412, date: 200, isRevoked: false),
            GrowthPartnersLink(link: "t.me/+b", title: "⇄ Gift Radar", joined: 600, date: 100, isRevoked: false),
            GrowthPartnersLink(link: "t.me/+c", title: "Instagram bio", joined: 9000, date: 300, isRevoked: false),
            GrowthPartnersLink(link: "t.me/+d", title: nil, joined: 50, date: 400, isRevoked: false)
        ]
        let summary = GrowthPartners.summary(links: links)
        XCTAssertEqual(summary.swaps, 2)
        XCTAssertEqual(summary.joined, 1012)
        XCTAssertEqual(summary.lastSwap?.partnerTitle, "NFT Notes")
        XCTAssertEqual(summary.lastSwap?.joined, 412)
    }

    func testStrings() {
        let en = GrowthPartnersStrings(languageCode: "en")
        let ru = GrowthPartnersStrings(languageCode: "ru")
        XCTAssertEqual(en.subscribers(1), "1 subscriber")
        XCTAssertEqual(en.subscribers(2140), "2,140 subscribers")
        XCTAssertEqual(ru.subscribers(1), "1 подписчик")
        XCTAssertEqual(ru.subscribers(3), "3 подписчика")
        XCTAssertEqual(ru.subscribers(11), "11 подписчиков")
        XCTAssertEqual(ru.subscribers(1312), "1,312 подписчиков")
        XCTAssertEqual(en.estimate(38), "≈ +38 per post")
        XCTAssertEqual(en.tabTitle, "Partners")
        XCTAssertEqual(ru.tabTitle, "Партнёры")
    }
}
