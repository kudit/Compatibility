import SwiftUI

@available(iOS 13.0, tvOS 13, watchOS 6, *)
public struct BytesView: View {
    public var label: String?
    public var bytes: (any BinaryInteger)?
    public var font: Font? = .headline
    public var countStyle: ByteCountFormatter.CountStyle? = .file
    public var round = false
    public var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            if let label {
                Text(label).opacity(0.5) // debugging: "label (\(String(describing: bytes))"
                Spacer()
            }
            if let capacity = bytes {
                let parts = capacity.byteParts(countStyle ?? .file)
                let number = round ? "\(Int(Double(parts.count) ?? -1))" : "\(parts.count)"
                Text(number).font(font)
                if countStyle != nil {
                    Text(parts.units).opacity(0.5)
                }
            }
        }
    }
}

@available(iOS 13.0, tvOS 13, watchOS 6, *)
public struct RandomBytesTestView: View {
    public init() {}
    public var body: some View {
        List {
            ForEach(0..<10, id: \.self) { index in
                let pow = Int(pow(10, index).description) ?? 1
                let bytes = Int.random(max: 123456) * pow
                BytesView(label: "\"\(bytes)\"", bytes: bytes)
            }
        }
    }
}

@available(iOS 13.0, tvOS 13, watchOS 6, *)
#Preview {
    RandomBytesTestView()
}
