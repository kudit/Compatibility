//
//  FieldView.swift
//  Compatibility
//
//  Created by Ben Ku on 7/14/26.
//

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))
import SwiftUI

@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
/// A SwiftUI representation of a structured ``Field`` value.
///
/// Boolean fields use the existing check-state presentation, symbol-bearing fields include their SF
/// Symbol, and other values use the Compatibility labeled-content backport for consistent presentation.
public struct FieldView: View {
    /// The structured field displayed by this view.
    public var field: Field

    /// Creates a view for a structured field.
    /// - Parameter field: The field whose optional label, symbol, and human-readable value should be displayed.
    public init(_ field: Field) {
        self.field = field
    }

    /// The field's human-readable SwiftUI presentation.
    public var body: some View {
        let label = field.label ?? ""
        let colonLabel = "\(label):"
        let valueString = field.value.description
        Group {
            if field.label == nil {
                Text(valueString)
                    .font(.footnote).backport.foregroundStyle(.gray)
            } else if let boolValue = field.value.boolValue {
                TestCheck(label, boolValue)
            } else if let symbol = field.symbol {
                HStack {
                    Text(colonLabel)
                    Spacer()
                    Image(systemName: symbol)
                        .backport.foregroundStyle(.gray)
                        .multilineTextAlignment(.trailing)
                    Text("\(valueString)")
                        .backport.foregroundStyle(.gray)
                        .multilineTextAlignment(.trailing)
                }
            } else {
                Backport.LabeledContent(colonLabel, value: valueString)
            }
        }.backport.focusable(true) // to allow scrolling in tvOS
    }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
public struct TestCheck: View {
    var label: String
    var state: Bool
    public init(_ label: String, _ state: Bool) {
        self.label = label
        self.state = state
    }
    public var body: some View {
        Label(label, systemImage: state ? "checkmark.circle.fill" : "x.square.fill").backport.foregroundStyle(state ? .green : .gray)
    }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
#Preview("Test Checks") {
    List {
        TestCheck("True", true)
        TestCheck("False", false)
        Label("True", systemImage: "checkmark.circle.fill").backport.foregroundStyle(.green)
        Label("False", systemImage: "x.square.fill").backport.foregroundStyle(.gray)
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
/// Displays ordered groups of structured fields as SwiftUI sections.
///
/// Section order follows the supplied ``OrderedDictionary`` so support and diagnostic screens can
/// maintain a predictable human-readable presentation.
public struct FieldSections: View {
    /// The ordered section titles and fields displayed by the view.
    public var sections: OrderedDictionary<String,[Field]>

    /// Creates a grouped field presentation.
    /// - Parameter sections: An ordered dictionary mapping each section title to the fields it contains.
    public init(_ sections: OrderedDictionary<String,[Field]>) {
        self.sections = sections
    }

    /// The SwiftUI sections generated from the ordered field groups.
    public var body: some View {
        ForEach(sections.keys.elements, id: \.self) { key in
            let data = sections[key] ?? []
            Section(key) {
                // Use collection indices so identical fields still receive distinct, stable identities within this section.
                ForEach(data.indices, id: \.self) { index in
                    FieldView(data[index])
                }
            }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview {
    FieldSections(
        [
            "Section A":[
                Field("Label 1", "Value 1"),
                Field("Label 2", "Value 2")
            ],
            "Section B":[
                Field("Label 1", "Value 1"),
                Field("Label 2", true),
                Field("Label 3", 55),
                Field("Label 4", Application.iCloudStatus),
            ]
        ]
    )
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 9, *)
#Preview {
    CompatibilityEnvironmentTestView()
}
#endif
