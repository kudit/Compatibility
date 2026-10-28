//
//  EnvironmentsView.swift
//
//
//  Created by Ben Ku on 4/21/24.
//

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI

private struct EnvironmentExpansionProgressKey: EnvironmentKey {
	static let defaultValue: CGFloat = 0
}

private extension EnvironmentValues {
	var environmentExpansionProgress: CGFloat {
		get { self[EnvironmentExpansionProgressKey.self] }
		set { self[EnvironmentExpansionProgressKey.self] = newValue }
	}
}

/// Supplies the interpolated animation value to layout as well as to visual effects.
private struct EnvironmentExpansionProgressModifier: AnimatableModifier {
	var progress: CGFloat

	var animatableData: CGFloat {
		get { progress }
		set { progress = newValue }
	}

	func body(content: Content) -> some View {
		content.environment(\.environmentExpansionProgress, progress)
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private struct EnvironmentExpansionRows: View {
	@Environment(\.environmentExpansionProgress) private var progress
	let environmentSet: [Build.Environment]

	private let rowHeight: CGFloat = 32
	private let compactHeight: CGFloat = 36
	private let compactIconPitch: CGFloat = 24

	var body: some View {
		GeometryReader { geometry in
			let environments = Build.Environment.allCases
			let count = max(environments.count, 1)
			let compactPitch = min(compactIconPitch, geometry.size.width / CGFloat(count))
			let compactStart = (geometry.size.width - compactPitch * CGFloat(count)) / 2 + compactPitch / 2
			let contentHeight = compactHeight + (CGFloat(count) * rowHeight - compactHeight) * progress

			ZStack(alignment: .topLeading) {
				ForEach(environments.indices, id: \.self) { index in
					let environment = environments[index]
					let enabled = environmentSet.contains(environment)
					let collapsedX = compactStart + CGFloat(index) * compactPitch
					let iconX = collapsedX + (13 - collapsedX) * progress
					let rowY = CGFloat(index) * rowHeight + rowHeight / 2
					let iconY = compactHeight / 2 + (rowY - compactHeight / 2) * progress

					Backport.Image(systemName: environment.symbolName)
						.font(.system(size: 12 + 4 * progress))
						// Keep wide symbols from pushing the labels out of alignment.
						.frame(width: 18 + 8 * progress, alignment: .center)
						.opacity(enabled ? 1.0 : 0.2)
						.foregroundColor(enabled ? environment.color : .gray)
						.help("\(environment.label) environment: \(enabled ? "active" : "inactive") in this build")
						// Scaling provides the visual handoff without matched-geometry sources,
						// which produced duplicate-source diagnostics in list rows.
						.scaleEffect(0.92 + 0.08 * progress)
						.frame(width: 18 + 8 * progress, height: 18 + 8 * progress)
						.position(x: iconX, y: iconY)
						.accessibilityHidden(true)

					Text(environment.label)
						.font(.body)
						.fontWeight(enabled ? .semibold : .regular)
						.foregroundColor(enabled ? environment.color : .gray)
						.lineLimit(1)
						.frame(width: max(0, geometry.size.width - 46), alignment: .leading)
						.position(x: 46 + max(0, geometry.size.width - 46) / 2, y: iconY)
						.opacity(progress)
						.offset(x: -8 * (1 - progress))
						.accessibilityElement(children: .ignore)
						.backport.accessibilityLabel((enabled ? "Is" : "Not") + " " + environment.label)
						.backport.accessibilityIdentifier("environment.\(environment.caseName)")
						.accessibilityHidden(progress < 0.5)
#if os(tvOS)
						.backport.focusable(true) // Keep expanded labels focusable for tvOS scrolling.
#endif
				}
			}
			.frame(width: geometry.size.width, height: contentHeight)
			.contentShape(Rectangle())
		}
		.frame(height: EnvironmentsView.rowHeight(for: progress))
		// Keep the complete row rectangle as the pointer hit target in both states.
		.background(Color.primary.opacity(0.001))
		.contentShape(Rectangle())
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public struct EnvironmentsView: View {
    public var environmentSet: [Build.Environment]
    @State private var localExpansionProgress: CGFloat = 0
    private let expansionProgressBinding: Binding<CGFloat>?

    public init(_ environmentSet: [Build.Environment]) {
        self.environmentSet = environmentSet
        self.expansionProgressBinding = nil
    }

    init(_ environmentSet: [Build.Environment], expansionProgress: Binding<CGFloat>) {
        self.environmentSet = environmentSet
        self.expansionProgressBinding = expansionProgress
    }

    static let expansionAnimation = Animation.spring(response: 0.55, dampingFraction: 0.82)

    static func rowHeight(for progress: CGFloat) -> CGFloat {
        let compactHeight: CGFloat = 36
        let rowHeight: CGFloat = 32
        return compactHeight + (CGFloat(Build.Environment.allCases.count) * rowHeight - compactHeight) * progress
    }

    private var expansionProgress: CGFloat {
        expansionProgressBinding?.wrappedValue ?? localExpansionProgress
    }

    private var isExpanded: Bool { expansionProgress >= 0.5 }

	private var environmentAccessibilitySummary: String {
		Build.Environment.allCases.map { environment in
			(environmentSet.contains(environment) ? "Is " : "Not ") + environment.label
		}.joined(separator: ", ")
	}

    private func toggleExpanded() {
        // One animating value drives row height, icon position/scale, and label reveal together.
        withAnimation(Self.expansionAnimation) {
            let nextProgress: CGFloat = isExpanded ? 0 : 1
            if let expansionProgressBinding {
                expansionProgressBinding.wrappedValue = nextProgress
            } else {
                localExpansionProgress = nextProgress
            }
        }
    }

    public var body: some View {
        Button(action: toggleExpanded) {
            EnvironmentExpansionRows(environmentSet: environmentSet)
                .modifier(EnvironmentExpansionProgressModifier(progress: expansionProgress))
        }
#if os(macOS)
        .buttonStyle(.borderless)
#else
        .buttonStyle(.plain)
#endif
        .backport.accessibilityLabel(isExpanded ? "Collapse environments" : "Expand environments")
        .backport.accessibilityValue(isExpanded ? environmentAccessibilitySummary : "Collapsed")
        .backport.accessibilityIdentifier("environments.toggle")
    }

}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Environments") {
    EnvironmentsView(Build.environments())
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Environments ALL") {
    EnvironmentsView(Build.Environment.allCases)
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension EnvironmentsView {
    /// Verifies the deterministic environment list used by both compact and expanded rendering.
    @MainActor
    internal static let tests: [TestCase] = [
        TestCase("Environment view inventory") {
            let environments = Build.Environment.allCases
            try expect(!environments.isEmpty)
            try expect(environments.allSatisfy { !$0.label.isEmpty && !$0.symbolName.isEmpty })
        },
    ]
}
#endif
