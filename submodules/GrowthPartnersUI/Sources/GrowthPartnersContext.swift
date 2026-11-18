import Foundation
import SwiftSignalKit
import TelegramCore
import LocalizedPeerData

/// Data for the Partners tab of channel statistics. Everything comes from existing API:
/// - similar channels — `channels.getChannelRecommendations` (`TelegramEngine.Peers.recommendedChannels`);
/// - our size — `ParticipantCount`;
/// - swaps and who brought whom — our invite links titled "⇄ Partner" with their join counters (`messages.getExportedChatInvites`).
public final class GrowthPartnersContext {
    public struct State: Equatable {
        public var suggestions: [GrowthPartnerSuggestion]
        public var peers: [Int64: EnginePeer]
        public var summary: GrowthPartnersSummary
        public var offered: Set<Int64>
        public var hasLoaded: Bool

        public static let empty = State(suggestions: [], peers: [:], summary: .empty, offered: [], hasLoaded: false)
    }

    private let engine: TelegramEngine
    private let peerId: EnginePeer.Id
    private let invitesContext: PeerExportedInvitationsContext
    private let offeredPromise = ValuePromise<Set<Int64>>(Set(), ignoreRepeated: true)
    private var offeredValue = Set<Int64>()
    private let requestDisposable = MetaDisposable()

    public init(engine: TelegramEngine, peerId: EnginePeer.Id) {
        self.engine = engine
        self.peerId = peerId
        self.invitesContext = engine.peers.peerExportedInvitations(peerId: peerId, adminId: nil, revoked: false, forceUpdate: true)
        self.requestDisposable.set(engine.peers.requestRecommendedChannels(peerId: peerId, forceUpdate: false).start())
    }

    deinit {
        self.requestDisposable.dispose()
    }

    public var state: Signal<State, NoError> {
        let ownSubscribers = self.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.ParticipantCount(id: self.peerId))
        return combineLatest(
            self.engine.peers.recommendedChannels(peerId: self.peerId),
            ownSubscribers,
            self.invitesContext.state,
            self.offeredPromise.get()
        )
        |> map { recommended, ownSubscribers, invites, offered -> State in
            let links: [GrowthPartnersLink] = invites.invitations.compactMap { invitation in
                guard case let .link(link, title, _, _, isRevoked, _, date, _, _, _, count, _, _) = invitation else {
                    return nil
                }
                return GrowthPartnersLink(link: link, title: title, joined: count ?? 0, date: date, isRevoked: isRevoked)
            }
            let summary = GrowthPartners.summary(links: links)
            let swappedTitles = Set(GrowthPartners.swaps(links: links).map(\.partnerTitle))

            var peers: [Int64: EnginePeer] = [:]
            var candidates: [GrowthPartnerCandidate] = []
            for channel in recommended?.channels ?? [] {
                let id = channel.peer.id.id._internalGetInt64Value()
                peers[id] = channel.peer
                candidates.append(GrowthPartnerCandidate(id: id, title: channel.peer.compactDisplayTitle, subscribers: channel.subscribers))
            }
            let suggestions = GrowthPartners.suggestions(ownSubscribers: Int32(ownSubscribers ?? 0), candidates: candidates, swappedTitles: swappedTitles)

            return State(suggestions: suggestions, peers: peers, summary: summary, offered: offered, hasLoaded: recommended != nil && invites.hasLoadedOnce)
        }
        |> distinctUntilChanged
    }

    /// Creates our invite link for this partner ("⇄ Gift Radar") and returns it, ready to be sent in the offer.
    public func offerSwap(partner: EnginePeer) -> Signal<String?, NoError> {
        let partnerId = partner.id.id._internalGetInt64Value()
        let title = GrowthPartners.swapLinkTitle(partnerTitle: partner.compactDisplayTitle)
        return self.engine.peers.createPeerExportedInvitation(peerId: self.peerId, title: title, expireDate: nil, usageLimit: nil, requestNeeded: false, subscriptionPricing: nil)
        |> `catch` { _ -> Signal<ExportedInvitation?, NoError> in
            return .single(nil)
        }
        |> deliverOnMainQueue
        |> map { [weak self] invitation -> String? in
            guard let invitation, case let .link(link, _, _, _, _, _, _, _, _, _, _, _, _) = invitation else {
                return nil
            }
            if let self {
                self.invitesContext.add(invitation)
                self.offeredValue.insert(partnerId)
                self.offeredPromise.set(self.offeredValue)
            }
            return link
        }
    }
}
