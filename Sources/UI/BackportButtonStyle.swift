#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI

/// Button styles whose newest system appearance can be used through Compatibility's backport surface.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public enum BackportButtonStyle: Sendable {
    /// Uses the system Liquid Glass button style when available and a material-backed circular fallback otherwise.
    case glass
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public extension Backport where Content: View {
    /// Applies a Compatibility-managed button style whose appearance degrades gracefully on older systems.
    ///
    /// Use `.backport.buttonStyle(.glass)` instead of repeating availability checks at each call site.
    @ViewBuilder
    func buttonStyle(_ style: BackportButtonStyle) -> some View {
        switch style {
        case .glass:
            if #available(iOS 26, macOS 26, tvOS 26, watchOS 26, *) {
                content
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
            } else if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
                content
                    .buttonStyle(.plain)
                    .background(.regularMaterial, in: Circle())
                    .contentShape(Circle())
            } else {
                content
                    .buttonStyle(.plain)
                    .background(Circle().fill(Color.secondary.opacity(0.15)))
                    .contentShape(Circle())
            }
        }
    }
}
#endif
