//
//  EnvironmentsView.swift
//
//
//  Created by Ben Ku on 4/21/24.
//

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI

@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
@MainActor
public struct EnvironmentsView: View {
    public var environmentSet: [Build.Environment]
    @State private var isExpanded = false

    public init(_ environmentSet: [Build.Environment]) {
        self.environmentSet = environmentSet
    }

    private func toggleExpanded() {
        // Animate the compact icon row into the expanded labeled list so the icon
        // reveal instead of using matched geometry, which emits duplicate-source
        // diagnostics in SwiftUI list rows when both branches are inserted together.
        withAnimation(.easeInOut(duration: 0.25)) {
            isExpanded.toggle()
        }
    }

    public var body: some View {
        Group {
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Build.Environment.allCases, id: \.self) { environment in
                        let enabled = environmentSet.contains(environment)
                        environmentItem(environment: environment, enabled: enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 6) {
                    ForEach(Build.Environment.allCases, id: \.self) { environment in
                        let enabled = environmentSet.contains(environment)
                        environmentIcon(environment: environment, enabled: enabled)
                    }
                }
                // The compact state fills the list row for tapping but keeps the icon
                // group centered instead of spreading the symbols across the whole row.
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .backport.onTapGesture {
            // Tapping anywhere in the view toggles the same inline content instead of
            // navigating away, which keeps this useful in dense Device Info layouts.
            toggleExpanded()
        }
        .accessibilityAddTraits(.isButton)
    }

    private func environmentIcon(environment: Build.Environment, enabled: Bool) -> some View {
        Image(systemName: environment.symbolName)
            .font(isExpanded ? .body : .caption)
            // Fixed width keeps wide symbols, such as the Mac Catalyst icon, from pushing
            // labels farther right than narrower status icons in the expanded list.
            .frame(width: isExpanded ? 26 : 18, alignment: .center)
            .opacity(enabled ? 1.0 : 0.2)
            .foregroundColor(enabled ? environment.color : .gray)
            // Scaling gives the state change a small visual handoff without relying on
            // matched geometry, whose duplicate-source diagnostics were breaking layout.
            .scaleEffect(isExpanded ? 1.0 : 0.92)
    }

    private func environmentItem(environment: Build.Environment, enabled: Bool) -> some View {
        HStack(spacing: 6) {
            environmentIcon(environment: environment, enabled: enabled)
            if isExpanded {
                Text(environment.label)
                    .font(.body)
                    .fontWeight(enabled ? .semibold : .regular)
                    // Match the text color to the icon color so disabled entries read as
                    // disabled instead of borrowing the active environment tint.
                    .foregroundColor(enabled ? environment.color : .gray)
                    .lineLimit(1)
                    .offset(x: isExpanded ? 0 : -8)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .leading)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                    .backport.focusable(true) // to allow scrolling in tvOS
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel((enabled ? "Is" : "Not") + " " + environment.label)
    }
}

@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Environments") {
    EnvironmentsView(Build.environments())
}
@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Environments ALL") {
    EnvironmentsView(Build.Environment.allCases)
}
#endif
