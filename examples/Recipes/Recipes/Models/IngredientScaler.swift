import Foundation

/// Scales the quantity at the start of an ingredient line, e.g.
/// "1 1/2 cups flour" × 2 → "3 cups flour". Lines without a leading
/// quantity ("salt to taste") are left unchanged.
nonisolated enum IngredientScaler {
    private static let unicodeFractions: [Character: Double] = [
        "⅛": 1.0 / 8, "¼": 1.0 / 4, "⅓": 1.0 / 3, "⅜": 3.0 / 8, "½": 1.0 / 2,
        "⅝": 5.0 / 8, "⅔": 2.0 / 3, "¾": 3.0 / 4, "⅞": 7.0 / 8,
    ]

    static func scale(_ line: String, by factor: Double, locale: Locale = .current) -> String {
        guard factor != 1, let (quantity, rest) = parse(line) else { return line }
        let amount = format(quantity * factor, locale: locale)
        return rest.isEmpty ? amount : "\(amount) \(rest)"
    }

    /// Splits a line into its leading quantity and the rest.
    static func parse(_ line: String) -> (quantity: Double, rest: String)? {
        var tokens = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard let first = tokens.first, var quantity = number(first) else { return nil }
        tokens.removeFirst()
        // A mixed number like "1 1/2" or "1 ½".
        if quantity == quantity.rounded(), let second = tokens.first, isFraction(second), let fraction = number(second) {
            quantity += fraction
            tokens.removeFirst()
        }
        return (quantity, tokens.joined(separator: " "))
    }

    /// Whole and common fractional amounts as fractions ("1½"), anything else as a short decimal.
    static func format(_ quantity: Double, locale: Locale = .current) -> String {
        let whole = (quantity + 0.0001).rounded(.down)
        let remainder = quantity - whole
        if remainder < 0.01 { return String(Int(whole)) }
        if remainder > 0.99 { return String(Int(whole) + 1) }
        if let (symbol, _) = unicodeFractions.first(where: { abs($0.value - remainder) < 0.01 }) {
            return whole > 0 ? "\(Int(whole))\(symbol)" : String(symbol)
        }
        return quantity.formatted(.number.precision(.fractionLength(0...2)).locale(locale))
    }

    private static func isFraction(_ token: String) -> Bool {
        token.contains("/") || (token.count == 1 && unicodeFractions[token.first!] != nil)
    }

    private static func number(_ token: String) -> Double? {
        if let value = Double(token.replacingOccurrences(of: ",", with: ".")), value >= 0 {
            return value
        }
        let parts = token.split(separator: "/")
        if parts.count == 2, let top = Double(parts[0]), let bottom = Double(parts[1]), bottom != 0 {
            return top / bottom
        }
        // "½" or "1½"
        if let last = token.last, let fraction = unicodeFractions[last] {
            let wholePart = token.dropLast()
            if wholePart.isEmpty { return fraction }
            if let whole = Double(wholePart) { return whole + fraction }
        }
        return nil
    }
}
