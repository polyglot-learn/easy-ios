import Foundation

/// Parses and formats typed money amounts.
nonisolated enum Amount {
    /// Parses what the user typed, accepting the locale's decimal separator or
    /// a period, and ignoring grouping separators and spaces. Nil if it isn't a number.
    static func parse(_ text: String, locale: Locale = .current) -> Decimal? {
        var cleaned = text.filter { !$0.isWhitespace }
        if let grouping = locale.groupingSeparator, grouping != locale.decimalSeparator {
            cleaned = cleaned.replacingOccurrences(of: grouping, with: "")
        }
        if let separator = locale.decimalSeparator, separator != "." {
            cleaned = cleaned.replacingOccurrences(of: separator, with: ".")
        }
        guard !cleaned.isEmpty, cleaned.allSatisfy({ $0.isNumber || $0 == "." }),
            cleaned.filter({ $0 == "." }).count <= 1
        else { return nil }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    /// The amount as the user would type it, e.g. "1234.5" or "1234,5".
    static func editingText(_ amount: Decimal, locale: Locale = .current) -> String {
        amount.formatted(.number.grouping(.never).locale(locale))
    }

    static var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }
}
