public enum CloudStatus: CustomStringConvertible, Sendable, CaseIterable, SymbolRepresentable {
    case notSupported, available, unavailable
    public var description: String {
        switch self {
        case .notSupported:
            return "Not Supported"
        case .available:
            return "Available"
        case .unavailable:
            return "Unavailable"
        }
    }
    /// Returns an SFSymbolName for the given status.
    public var symbolName: String {
        switch self {
        case .notSupported:
            return "icloud.slash.fill"
        case .available:
            return "checkmark.icloud.fill"
        case .unavailable:
            return "xmark.icloud.fill"
        }
    }
}

#if compiler(>=5.9) && !(os(WASM) || os(WASI))
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
public extension CloudStatus {
    /// Shared enum behavior tests available to both the in-app test UI and Swift Testing bridge.
    @MainActor
    static let tests = [
        Test("CloudStatus rotation") {
            // Verify the shared postfix rotation operator advances through every case and wraps to the beginning.
            var status = CloudStatus.notSupported
            try expect(status == .notSupported)
            status++
            try expect(status == .available)
            status++
            try expect(status == .unavailable)
            status++
            try expect(status == .notSupported)
        },
    ]
}
#endif

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))
import SwiftUI
@available(iOS 13, macOS 11, tvOS 13, watchOS 6, *)
#Preview {
    List {
        ForEach(CloudStatus.allCases, id: \.self) { status in
            HStack {
                Text(status.description)
                Image(systemName: status.symbolName)
            }
        }
    }
}
#endif
