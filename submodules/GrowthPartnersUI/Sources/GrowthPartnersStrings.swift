import Foundation

/// English and Russian texts, inlined so the module builds on its own.
/// Move them to `Localizable.strings` when merging.
public struct GrowthPartnersStrings {
    public let isRussian: Bool

    public init(languageCode: String) {
        self.isRussian = languageCode.lowercased().hasPrefix("ru")
    }

    public var tabTitle: String { self.isRussian ? "Партнёры" : "Partners" }
    public var overviewHeader: String { self.isRussian ? "ВЗАИМОПИАР" : "PROMO SWAPS" }
    public var swapsTitle: String { self.isRussian ? "Обменов" : "Swaps" }
    public var joinedTitle: String { self.isRussian ? "Подписчиков по обменам" : "Joined via swaps" }
    public var lastSwapTitle: String { self.isRussian ? "Последний обмен" : "Last swap" }
    public var suggestedHeader: String { self.isRussian ? "ПОДХОДЯЩИЕ КАНАЛЫ" : "SUGGESTED PARTNERS" }
    public var lastSwapHeader: String { self.isRussian ? "ПОСЛЕДНИЙ ОБМЕН" : "LAST SWAP" }
    public var offerSwap: String { self.isRussian ? "Предложить" : "Offer swap" }
    public var offerSent: String { self.isRussian ? "Отправлено" : "Offer sent" }
    public var noSuggestions: String {
        self.isRussian ? "Пока нет похожих каналов вашего размера. Они появятся, когда Telegram найдёт пересечение аудиторий." : "No similar channels of your size yet. They appear when Telegram finds channels with a similar audience."
    }
    public var footer: String {
        self.isRussian ? "Партнёры подобраны по теме и размеру канала. Для каждого обмена создаётся своя ссылка — поэтому видно, кто кого привёл." : "Partners are matched by topic and size. Every swap gets its own invite link, so you see exactly who brought whom."
    }

    public func offerText(channelTitle: String, link: String) -> String {
        if self.isRussian {
            return "Привет! Предлагаю взаимопиар: мой канал «\(channelTitle)» — \(link). Telegram подобрал нас как похожие каналы."
        } else {
            return "Hi! Let's swap promo posts: my channel “\(channelTitle)” — \(link). Telegram matched us as similar channels."
        }
    }

    public func subscribers(_ count: Int32) -> String {
        let number = GrowthPartnersStrings.grouped(count)
        if self.isRussian {
            return "\(number) \(GrowthPartnersStrings.russianPlural(count, one: "подписчик", few: "подписчика", many: "подписчиков"))"
        } else {
            return "\(number) \(count == 1 ? "subscriber" : "subscribers")"
        }
    }

    /// "≈ +38 per post" — shown in green under the channel name.
    public func estimate(_ joins: Int32) -> String {
        let number = GrowthPartnersStrings.grouped(joins)
        return self.isRussian ? "≈ +\(number) с поста" : "≈ +\(number) per post"
    }

    /// "+412 joined · Nov 12"
    public func swapResult(_ swap: GrowthPartnersSwap, dateText: String) -> String {
        let number = GrowthPartnersStrings.grouped(swap.joined)
        return self.isRussian ? "+\(number) по вашей ссылке · \(dateText)" : "+\(number) via your link · \(dateText)"
    }

    public static func grouped(_ value: Int32) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    public static func russianPlural(_ count: Int32, one: String, few: String, many: String) -> String {
        let n = abs(Int(count))
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 {
            return one
        } else if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            return few
        } else {
            return many
        }
    }
}
