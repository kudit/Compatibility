//
//  Symbols.swift
//  Compatibility
//
//  Created by Ben Ku on 6/28/26.
//

/// Primarily for Enums which can be represented by an SF Symbol.
public protocol SymbolRepresentable {
    /// An SF Symbol name string.
    var symbolName: String { get }
}

public extension String {
    static let defaultUnknownSymbol = "questionmark.square.fill"
}
