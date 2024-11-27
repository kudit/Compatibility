//
//  SwiftUIView.swift
//  
//
//  Created by Ben Ku on 7/5/24.
//

#if canImport(SwiftUI)
import SwiftUI

// MARK: - Menu compatibility for watchOS
#if os(watchOS)
@available(watchOS 6, *)
public struct Menu<Content: View, LabelView: View>: View {
    var content: () -> Content
    var label: () -> LabelView
    public init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder label: @escaping () -> LabelView
    ) {
        self.content = content
        self.label = label
    }
    public var body: some View {
        NavigationLink(destination: {
            content().scrollWrapper()
        }, label: label)
    }
}
@available(watchOS 6, *)
public extension Menu where LabelView == Text {
    init(
        _ title: some StringProtocol,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(content: content, label: {
            Text(title)
        })
    }
}
@available(watchOS 6, *)
public extension Menu where LabelView == Image {
    init(
        _ title: some StringProtocol,
        symbolName: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(content: content, label: {
            Image(systemName: symbolName)
        })
    }
}
#endif

@available(iOS 14, macOS 12, tvOS 17, watchOS 7, *)
public struct MenuTest: View {
    public var body: some View {
        Menu("Symbols") {
            ForEach(["suit.diamond", "star", "suit.spade.fill","suit.heart","suit.club","star.fill"], id: \.self) { symbol in
                Button {
                    // Perform an action here.
                    print(String(describing: symbol))
                } label: {
                    // TODO: Figure out why this doesn't show images in macOS and doesn't work at all in tvOS. work on macOS and make sure does work for watchOS
                    Label(symbol, systemImage: symbol)
                }
            }
        }
    }
}

#if swift(>=5.9)
@available(iOS 14, macOS 12, tvOS 17, watchOS 7, *)
#Preview("Watch Menu test") {
    MenuTest().navigationWrapper()
}
#endif

#endif
