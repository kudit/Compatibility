//
//  Field.swift
//  Compatibility
//
//  Created by Ben Ku on 7/13/26.
//

/// A labeled, structured value suitable for diagnostics, support information, and reusable displays.
///
/// A field preserves its value as a ``MixedTypeField`` so clients retain the original primitive or
/// collection type while still having a human-readable description for presentation.
public struct Field: Hashable, Sendable {
    /// Human-readable field label.
    public var label: String?

    /// Field value. Keep this as a MixedTypeField so information can always
    /// be represented without a specific schema.
    public var value: MixedTypeField

    /// An optional SF Symbol name to display alongside the field.
    public var symbol: String? = nil

    /// Creates a field from an existing mixed-type value.
    /// - Parameters:
    ///   - label: An optional human-readable label describing the value.
    ///   - value: The structured value to preserve in the field.
    ///   - symbol: An optional SF Symbol name suitable for displaying with the value.
    public init(label: String?, value: MixedTypeField, symbol: String? = nil) {
        self.label = label
        self.value = value
        self.symbol = symbol
    }

    /// Creates a labeled string field.
    /// - Parameters:
    ///   - label: An optional human-readable label describing the value.
    ///   - value: The string value to store.
    ///   - symbol: An optional SF Symbol name suitable for displaying with the value.
    public init(_ label: String?, _ value: String, symbol: String? = nil) {
        self.init(label: label, value: .string(value), symbol: symbol)
    }
    /// Creates an unlabeled string field for explanatory text or notes.
    /// - Parameters:
    ///   - value: The string value to store.
    ///   - symbol: An optional SF Symbol name suitable for displaying with the value.
    public init(_ value: String, symbol: String? = nil) {
        self.init(nil, value, symbol: symbol)
    }
    /// Creates a labeled integer field.
    /// - Parameters:
    ///   - label: An optional human-readable label describing the value.
    ///   - value: The integer value to store.
    ///   - symbol: An optional SF Symbol name suitable for displaying with the value.
    public init(_ label: String?, _ value: Int, symbol: String? = nil) {
        self.init(label: label, value: .int(value), symbol: symbol)
    }
    /// Creates a labeled floating-point field.
    /// - Parameters:
    ///   - label: An optional human-readable label describing the value.
    ///   - value: The floating-point value to store.
    ///   - symbol: An optional SF Symbol name suitable for displaying with the value.
    public init(_ label: String?, _ value: Double, symbol: String? = nil) {
        self.init(label: label, value: .double(value), symbol: symbol)
    }
    /// Creates a labeled Boolean field.
    /// - Parameters:
    ///   - label: An optional human-readable label describing the value.
    ///   - value: The Boolean value to store.
    ///   - symbol: An optional SF Symbol name suitable for displaying with the value.
    public init(_ label: String?, _ value: Bool, symbol: String? = nil) {
        self.init(label: label, value: .bool(value), symbol: symbol)
    }

    /// Creates a field from a value that supplies its own human-readable description.
    /// - Parameters:
    ///   - label: An optional human-readable label describing the value.
    ///   - value: A value whose `description` should be stored as a string.
    ///   - symbol: An optional SF Symbol name suitable for displaying with the value.
    public init<T: CustomStringConvertible>(_ label: String?, _ value: T, symbol: String? = nil) {
        self.init(label, value.description, symbol: symbol)
    }
    /// Creates a field whose value supplies both human-readable text and an SF Symbol name.
    /// - Parameters:
    ///   - label: The human-readable label describing the value.
    ///   - value: A value whose `description` and `symbolName` should populate the field.
    public init<T: SymbolRepresentable & CustomStringConvertible>(_ label: String, _ value: T) {
        self.init(label, value, symbol: value.symbolName)
    }

//    /// Can be used to provide additional metadata or information relevant to the information.
//    /// Currently unused.
//    public var flags: [String:String] = [:]

    /// A human-readable representation of the labeled value.
    ///
    /// Boolean fields use a checkmark or `x` prefix, while other values use `Label: Value`. This output
    /// is intended for interfaces and support reports rather than stable serialization.
    public var description: String {
        let blankLabel = "Unlabeled"
        let cleanLabel = label ?? blankLabel

        if let boolValue = value.boolValue {
            return (boolValue ? "√" : "x") + " \(cleanLabel)"
        } else {
            return "\(cleanLabel): \(value.description)"
        }
    }
}

#if canImport(Foundation) && !hasFeature(Embedded)
/// Adds standard coding support wherever Foundation and the full Swift runtime provide coding.
///
/// Full-runtime WebAssembly includes Codable; only Embedded mode excludes the dynamic coding
/// implementation used by ``MixedTypeField``.
extension Field: Codable {}

public extension [Field] {
    /// Human-readable field descriptions separated by newlines.
    ///
    /// This preserves array order for display and support reports. It is not a stable serialization format.
    var description: String {
        return self.map{ $0.description }.joined(separator: "\n")
    }
}
#endif
