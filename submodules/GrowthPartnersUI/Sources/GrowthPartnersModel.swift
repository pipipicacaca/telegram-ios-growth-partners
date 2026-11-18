import Foundation

/// A channel that could swap promo posts with ours. Built from `RecommendedChannels.Channel`.
public struct GrowthPartnerCandidate: Equatable {
    public let id: Int64
    public let title: String
    public let subscribers: Int32

    public init(id: Int64, title: String, subscribers: Int32) {
        self.id = id
        self.title = title
        self.subscribers = subscribers
    }
}

public struct GrowthPartnerSuggestion: Equatable {
    public let candidate: GrowthPartnerCandidate
    /// Subscribers we can expect from one promo post in the partner channel.
    public let estimatedJoins: Int32
    /// 0…1, how close the two channels are in size.
    public let score: Double

    public init(candidate: GrowthPartnerCandidate, estimatedJoins: Int32, score: Double) {
        self.candidate = candidate
        self.estimatedJoins = estimatedJoins
        self.score = score
    }
}

/// An invite link of the channel. Mirrors the fields of `ExportedInvitation.link` that we need.
public struct GrowthPartnersLink: Equatable {
    public let link: String
    public let title: String?
    public let joined: Int32
    public let date: Int32
    public let isRevoked: Bool

    public init(link: String, title: String?, joined: Int32, date: Int32, isRevoked: Bool) {
        self.link = link
        self.title = title
        self.joined = joined
        self.date = date
        self.isRevoked = isRevoked
    }
}

/// One finished or running swap: our invite link that was posted in the partner channel.
public struct GrowthPartnersSwap: Equatable {
    public let partnerTitle: String
    public let link: String
    public let joined: Int32
    public let date: Int32

    public init(partnerTitle: String, link: String, joined: Int32, date: Int32) {
        self.partnerTitle = partnerTitle
        self.link = link
        self.joined = joined
        self.date = date
    }
}

public struct GrowthPartnersSummary: Equatable {
    public let swaps: Int32
    public let joined: Int32
    public let lastSwap: GrowthPartnersSwap?

    public init(swaps: Int32, joined: Int32, lastSwap: GrowthPartnersSwap?) {
        self.swaps = swaps
        self.joined = joined
        self.lastSwap = lastSwap
    }

    public static let empty = GrowthPartnersSummary(swaps: 0, joined: 0, lastSwap: nil)
}

public enum GrowthPartners {
    /// Swap links are ordinary invite links whose title starts with this mark, e.g. "⇄ Gift Radar".
    /// Telegram counts joins per link, so the numbers below are real, not estimates.
    public static let swapLinkMark = "⇄ "
    /// `messages.exportChatInvite` accepts titles up to 32 characters.
    public static let maxLinkTitleLength = 32

    /// Share of partner subscribers that see a promo post.
    public static let viewRate = 0.35
    /// Share of viewers that join a channel from a promo post.
    public static let joinRate = 0.03
    /// A partner can be from 4 times smaller to 4 times larger than we are.
    public static let maxSizeRatio = 4.0

    public static func swapLinkTitle(partnerTitle: String) -> String {
        let limit = self.maxLinkTitleLength - self.swapLinkMark.count
        var name = partnerTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.count > limit {
            name = String(name.prefix(limit - 1)) + "…"
        }
        return self.swapLinkMark + name
    }

    public static func partnerTitle(fromLinkTitle title: String?) -> String? {
        guard let title, title.hasPrefix(self.swapLinkMark) else {
            return nil
        }
        let name = String(title.dropFirst(self.swapLinkMark.count)).trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    public static func estimatedJoins(partnerSubscribers: Int32) -> Int32 {
        return Int32((Double(max(0, partnerSubscribers)) * self.viewRate * self.joinRate).rounded())
    }

    /// 1 when the partner is our size, 0 at `maxSizeRatio` in either direction.
    public static func sizeScore(ownSubscribers: Int32, partnerSubscribers: Int32) -> Double {
        guard ownSubscribers > 0, partnerSubscribers > 0 else {
            return 0.0
        }
        let ratio = Double(partnerSubscribers) / Double(ownSubscribers)
        let distance = abs(log2(ratio)) / log2(self.maxSizeRatio)
        return max(0.0, 1.0 - distance)
    }

    /// Similar channels (from `channels.getChannelRecommendations`) of a comparable size that we haven't swapped with yet.
    public static func suggestions(ownSubscribers: Int32, candidates: [GrowthPartnerCandidate], swappedTitles: Set<String>, limit: Int = 3) -> [GrowthPartnerSuggestion] {
        var seen = Set<Int64>()
        var result: [GrowthPartnerSuggestion] = []
        for candidate in candidates {
            if seen.contains(candidate.id) || swappedTitles.contains(candidate.title) {
                continue
            }
            seen.insert(candidate.id)
            let score = self.sizeScore(ownSubscribers: ownSubscribers, partnerSubscribers: candidate.subscribers)
            if score <= 0.0 {
                continue
            }
            result.append(GrowthPartnerSuggestion(candidate: candidate, estimatedJoins: self.estimatedJoins(partnerSubscribers: candidate.subscribers), score: score))
        }
        result.sort { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }
            return lhs.candidate.subscribers > rhs.candidate.subscribers
        }
        return Array(result.prefix(limit))
    }

    public static func swaps(links: [GrowthPartnersLink]) -> [GrowthPartnersSwap] {
        return links.compactMap { link -> GrowthPartnersSwap? in
            guard let partnerTitle = self.partnerTitle(fromLinkTitle: link.title) else {
                return nil
            }
            return GrowthPartnersSwap(partnerTitle: partnerTitle, link: link.link, joined: link.joined, date: link.date)
        }.sorted { $0.date > $1.date }
    }

    public static func summary(links: [GrowthPartnersLink]) -> GrowthPartnersSummary {
        let swaps = self.swaps(links: links)
        return GrowthPartnersSummary(
            swaps: Int32(swaps.count),
            joined: swaps.reduce(0) { $0 + $1.joined },
            lastSwap: swaps.first
        )
    }
}
