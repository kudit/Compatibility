#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
struct EmbossedModifier: ViewModifier {
    @State var offset = 4.0
    @State var blur = 4.0
    @State var lightColor = Color.white.opacity(0.5)
    @State var darkColor = Color.black.opacity(0.5)
    func body(content: Content) -> some View {
        content
            .shadow(color: darkColor, radius: blur, x: offset, y: offset)
            .shadow(color: lightColor, radius: blur, x: -offset, y: -offset)
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension View {
    func embossed(offset: Double = 4.0, blur: Double = 4.0) -> some View {
        modifier(EmbossedModifier(offset: offset, blur: blur))
    }
}

#if compiler(>=5.9)
@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview("Embossed") {
    ZStack {
        Color.yellow.backport.ignoresSafeArea()
        VStack {
            ForEach(Edge.allCases, id: \.self) { edge in
                Triangle(flatEdge: edge)
                    .fill(.yellow)
                    .embossed(blur: 0)
                    .padding()
                    .padding()
                    .padding()
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}
#endif

#endif
