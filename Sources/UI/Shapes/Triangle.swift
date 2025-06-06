//
//  SwiftUIView.swift
//  
//
//  Created by Ben Ku on 7/19/24.
//

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

@available(iOS 13, tvOS 13, watchOS 6, *)
public struct Triangle: Shape {
    public var flatEdge: Edge
    public init(flatEdge: Edge) {
        self.flatEdge = flatEdge
    }
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // start at point
        switch flatEdge {
        case .top:
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        case .bottom:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        case .leading: // TODO: determine left to right as this will flip if that is flipped
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        case .trailing:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        }
        path.closeSubpath() // added so the point is pointy and not two lines meeting
        
        return path
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public struct TriangleShowcaseView: View {
    @State var showDetail = false
    public init() {}
    public var body: some View {
        VStack {
            ForEach(Edge.allCases, id: \.self) { edge in
                Button {
                    showDetail = true
                } label: {
                    Color.blue
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .backport.overlay {
                            Triangle(flatEdge: edge)
                                .fill(.green, strokeBorder: .yellow, lineWidth: 4)
                                .backport.background(.red)
                                .padding()
                        }
                }
                .frame(size: 100)
            }
        }
        .backport.navigationDestination(isPresented: $showDetail) {
            Button("Navigation Destination Test") {
                showDetail = false
            }
        }
        .navigationWrapper()
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview("Triangles") {
    TriangleShowcaseView()
}
#endif
