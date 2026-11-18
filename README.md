# Growth Partners — promo swaps in channel statistics

Small channels grow by swapping promo posts, but today it happens in DMs and spreadsheets.
**Statistics** of a channel gets a new tab, **Partners**: similar channels of your size to swap with, one-tap offers, and how many subscribers each swap really brought.

## How it works

| Step | Behaviour | Code |
|---|---|---|
| Tab | *Statistics · Boosts · Monetization · **Partners*** in the title of channel statistics. Shown for broadcast channels whose stats you can view. | `ChannelStatsSection.partners`, `.textWithTabs` |
| Overview | **Swaps** and **Joined via swaps** — in the same card as the other stats. | `GrowthPartnersSummary` → `StatsOverviewItem` |
| Suggested partners | Similar channels that Telegram already recommends for yours, filtered to 4× smaller … 4× larger, closest size first, already-swapped ones hidden. Each row: subscribers and *≈ +N per post*. | `TelegramEngine.Peers.recommendedChannels` (`channels.getChannelRecommendations`), `GrowthPartners.suggestions` |
| Offer swap | Tap a partner → a dedicated invite link **“⇄ Gift Radar”** is created for this swap and a share sheet opens with a ready offer. The row turns into *Offer sent*. | `createPeerExportedInvitation(title:)`, `ShareControllerParams(.text)` |
| Who brought whom | Every swap is its own invite link, so Telegram already counts the joins. The tab sums links titled “⇄ …” and shows the last swap: *+412 via your link · Nov 12*. | `peerExportedInvitations` → `ExportedInvitation.link(count:)`, `GrowthPartners.summary` |

No new server methods: suggestions, sizes and join counters come from existing API.
Not in this code: the 7-day retention and the partner's side of a swap (*They got*) from the demo — they need the partner's stats, i.e. a server method.
The per-post estimate is `subscribers × 35 % views × 3 % joins` (`GrowthPartners.viewRate`, `joinRate`); the numbers in the demo are illustrative.

Strings: English and Russian.

## Files

```
submodules/GrowthPartnersUI/                       new module (Bazel swift_library)
  Sources/GrowthPartnersModel.swift                matching by size, swap links, summary
  Sources/GrowthPartnersContext.swift              recommendations + invite links → state, offerSwap
  Sources/GrowthPartnersEntries.swift              rows of the Partners tab
  Sources/GrowthPartnersStrings.swift              en / ru, plurals, number grouping
  Tests/GrowthPartnersTests.swift                  matching, link titles, summary, strings
patches/0001-growth-partners-integration.patch     StatisticsUI
```

The patch (`StatisticsUI` only):
- `ChannelStatsController` — the `.partners` section and tab, `StatsEntry.partners`, the context in the state signal, *Offer swap* and opening a partner;
- `StatsOverviewItem` — draws `GrowthPartnersSummary`;
- `BUILD` — depends on `GrowthPartnersUI`.

## Install

Base: `TelegramMessenger/Telegram-iOS` master `24638bc` (the patch applies cleanly).

```bash
cd Telegram-iOS
cp -R /path/to/telegram-ios-growth-partners/submodules/GrowthPartnersUI submodules/
git apply /path/to/telegram-ios-growth-partners/patches/0001-growth-partners-integration.patch
```

`GrowthPartnersStrings` inlines en/ru so the module builds standalone; move the texts to `Localizable.strings` when merging.
For the tests add an `ios_unit_test` target for `Tests/`, like `ChatListUITests` in `ChatListUI/BUILD`.

Written against the sources of `24638bc`; not built locally (matching, summary and strings were checked with `swiftc`, all sources pass `swiftc -parse`).
