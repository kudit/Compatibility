/// Enables ++ on any enum to get the next enum value (if it's the last value, wraps around to first)
public extension CaseIterable where Self: Equatable { // equatable required to find self in list of cases
    /// Replaces the variable with the next enum value (if it's the last value, wraps around to first)
    static postfix func ++(e: inout Self) {
        let allCases = Self.allCases
        let idx = allCases.firstIndex(of: e)! // not possible to have it not be found
        let next = allCases.index(after: idx)
        e = allCases[next == allCases.endIndex ? allCases.startIndex : next]
    }
    
    @available(*, deprecated, renamed: "++")
    mutating func rotate() {
        self++
    }
}
