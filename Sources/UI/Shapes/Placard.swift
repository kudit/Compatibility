//
//  Placard.swift
//  Tracker
//
//  Created by Ben Ku on 10/30/20.
//

#if canImport(SwiftUI) && compiler(>=5.9)

import SwiftUI

@available(iOS 13, tvOS 13, watchOS 6, *)
public struct Placard: Shape {
    public init() {} // necessary for creation like Circle()
    public func path(in rect: CGRect) -> Path {
        let baseline = CGFloat(0.5)
        let cornerRadius = 0.1 * rect.size.width
        let heightCornerPercent = cornerRadius / rect.size.height
        let bottomEdge = baseline + heightCornerPercent

        func scaledValue(origin: CGFloat, bound: CGFloat, scale: CGFloat, value: CGFloat) -> CGFloat {
            return origin + bound * value * scale / 100.0
        }
        func adjustedPoint(x: CGFloat, y: CGFloat) -> CGPoint {
            let adjustedX = scaledValue(origin: rect.origin.x, bound: rect.size.width, scale: 100.0, value: x)
            let adjustedY = scaledValue(origin: rect.origin.y, bound: rect.size.height, scale: 100.0, value: y)
            return CGPoint(x: adjustedX, y: adjustedY)
        }
        //// Bezier Drawing
        var path = Path()
        /// Not sure why clockwise is the reverse of what would make sense...
        path.move(to: adjustedPoint(x: 1, y: heightCornerPercent))
        path.addLine(to: adjustedPoint(x: 1, y: baseline))
        path.addArc(center: adjustedPoint(x: 0.9, y: baseline), radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: adjustedPoint(x: 0.62, y: bottomEdge))
        path.addLine(to: adjustedPoint(x: 0.5, y: 1))
        path.addLine(to: adjustedPoint(x: 0.38, y: bottomEdge))
        path.addLine(to: adjustedPoint(x: 0.1, y: bottomEdge))
        path.addArc(center: adjustedPoint(x: 0.1, y: baseline), radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: adjustedPoint(x: 0, y: heightCornerPercent))
        path.addArc(center: adjustedPoint(x: 0.1, y: heightCornerPercent), radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(-90), clockwise: false)
        path.addLine(to: adjustedPoint(x: 0.9, y: 0))
        path.addArc(center: adjustedPoint(x: 0.9, y: heightCornerPercent), radius: cornerRadius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.closeSubpath()
        return path
    }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
public struct PlacardShowcaseView: View {
    public init() {}
    public var body: some View {
        VStack {
            Placard()
                .backport.overlay {
                    Text("Hello World!")
                        .bold()
                        .offset(y: -70)
                        .font(.largeTitle)
                        .backport.foregroundStyle(.background)
                }
            HStack {
                ForEach([Color.red, .green, .blue, .yellow, .pink, .orange], id: \.self) { color in
                    Placard().fill(color, strokeBorder: .gray, lineWidth: 3)
                }
            }
            .frame(height: 50)
            .padding(20)
HStack {
                Placard().fill(.green)
                    .backport.background(.yellow)
                Placard().fill(.red)
                Placard().fill(.blue)
                Placard().fill(.green)
                Placard().fill(.red)
                Placard()
                    .fill(.blue, strokeBorder: .yellow, lineWidth: 2)
                Placard().fill(.green)
                Placard().fill(.red)
                Placard().fill(.blue)
                Placard().fill(.green)
            }
            .frame(minWidth: 0, idealWidth: 500, maxWidth: .infinity, minHeight: 0, idealHeight: 20, maxHeight: 20, alignment: .top)
            .padding(20)
            Placard()
                .fill(Color.yellow)
        }.padding()
    }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
#Preview("Showcase") {
    PlacardShowcaseView()
}
#endif
