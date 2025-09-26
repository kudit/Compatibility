/// Enables ++ on any enum to get the next enum value (if it's the last value, wraps around to first)
public extension CaseIterable where Self: Equatable { // equatable required to find self in list of cases
    /// Replaces the variable with the next enum value (if it's the last value, wraps around to first)
    static postfix func ++(e: inout Self) {
        let allCases = Self.allCases
        let idx = allCases.firstIndex(of: e)! // not possible to have it not be found
        let next = allCases.index(after: idx)
        e = allCases[next == allCases.endIndex ? allCases.startIndex : next]
    }
    
#if !DEBUG // for excluding from Testing code coverage https://www.christopherthiebaut.com/posts/exclude_swiftui_previews_from_code_coverage/
    @available(*, deprecated, renamed: "++")
    mutating func rotate() {
        self++
    }
#endif
}

public protocol CaseNameConvertible {
    var caseName: String { get }
}
#if !(os(WASM) || os(WASI))
public extension CaseNameConvertible {
    /// exposes the case name for an enum without having to have a string rawValue.
    var caseName: String {
        // for enums
        (Mirror(reflecting: self).children.first?.label ?? String(describing: self))
    }
}
#endif
