import Foundation
import UIKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import ItemListUI
import ItemListPeerItem

/// Rows of the Partners tab. The summary card itself is drawn by `StatsOverviewItem` in StatisticsUI
/// (see the patch), every other row is built here from standard ItemList items.
public enum GrowthPartnersEntry: Equatable {
    public enum Group: Int32 {
        case overview
        case suggested
        case lastSwap
    }

    case overviewHeader(String)
    case overview(GrowthPartnersSummary)
    case suggestedHeader(String)
    case partner(Int32, EnginePeer, String, String, Bool)
    case noPartners(String)
    case lastSwapHeader(String)
    case lastSwap(String, String)
    case footer(String)

    public var group: Group {
        switch self {
        case .overviewHeader, .overview:
            return .overview
        case .suggestedHeader, .partner, .noPartners:
            return .suggested
        case .lastSwapHeader, .lastSwap, .footer:
            return .lastSwap
        }
    }

    public var stableId: Int32 {
        switch self {
        case .overviewHeader:
            return 0
        case .overview:
            return 1
        case .suggestedHeader:
            return 2
        case let .partner(index, _, _, _, _):
            return 10 + index
        case .noPartners:
            return 9
        case .lastSwapHeader:
            return 100
        case .lastSwap:
            return 101
        case .footer:
            return 102
        }
    }

    /// `nil` for `.overview` — StatisticsUI renders it with `StatsOverviewItem`.
    public func item(presentationData: ItemListPresentationData, context: AccountContext, sectionId: ItemListSectionId, offerSwap: @escaping (EnginePeer) -> Void, openPeer: @escaping (EnginePeer) -> Void) -> ListViewItem? {
        switch self {
        case let .overviewHeader(text), let .suggestedHeader(text), let .lastSwapHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: sectionId)
        case .overview:
            return nil
        case let .partner(_, peer, subscribers, estimate, offered):
            let strings = GrowthPartnersStrings(languageCode: presentationData.strings.primaryComponent.languageCode)
            let theme = presentationData.theme
            let label: ItemListPeerItemLabel = .text(offered ? strings.offerSent : strings.offerSwap, .standard, offered ? theme.list.itemSecondaryTextColor : theme.list.itemAccentColor, false)
            return ItemListPeerItem(
                presentationData: presentationData,
                systemStyle: .glass,
                dateTimeFormat: presentationData.dateTimeFormat,
                nameDisplayOrder: .firstLast,
                context: context,
                peer: peer,
                height: .generic,
                aliasHandling: .standard,
                nameColor: .primary,
                nameStyle: .plain,
                presence: nil,
                text: .text("\(subscribers) · \(estimate)", .constructive),
                label: label,
                editing: ItemListPeerItemEditing(editable: false, editing: false, revealed: false),
                revealOptions: nil,
                switchValue: nil,
                enabled: true,
                highlighted: false,
                selectable: true,
                sectionId: sectionId,
                action: {
                    if offered {
                        openPeer(peer)
                    } else {
                        offerSwap(peer)
                    }
                },
                setPeerIdWithRevealedOptions: { _, _ in },
                removePeer: { _ in }
            )
        case let .noPartners(text), let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: sectionId)
        case let .lastSwap(title, result):
            return ItemListTextItem(presentationData: presentationData, text: .markdown("**\(title)**\n\(result)"), sectionId: sectionId)
        }
    }
}

public func growthPartnersEntries(state: GrowthPartnersContext.State, strings: GrowthPartnersStrings, channelTitle: String) -> [GrowthPartnersEntry] {
    var entries: [GrowthPartnersEntry] = []

    entries.append(.overviewHeader(strings.overviewHeader))
    entries.append(.overview(state.summary))

    entries.append(.suggestedHeader(strings.suggestedHeader))
    if state.suggestions.isEmpty {
        entries.append(.noPartners(strings.noSuggestions))
    } else {
        for (index, suggestion) in state.suggestions.enumerated() {
            guard let peer = state.peers[suggestion.candidate.id] else {
                continue
            }
            entries.append(.partner(Int32(index), peer, strings.subscribers(suggestion.candidate.subscribers), strings.estimate(suggestion.estimatedJoins), state.offered.contains(suggestion.candidate.id)))
        }
    }

    if let swap = state.summary.lastSwap {
        entries.append(.lastSwapHeader(strings.lastSwapHeader))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: strings.isRussian ? "ru_RU" : "en_US")
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        let dateText = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(swap.date)))
        entries.append(.lastSwap("\(channelTitle) ⇄ \(swap.partnerTitle)", strings.swapResult(swap, dateText: dateText)))
    }
    entries.append(.footer(strings.footer))
    return entries
}
