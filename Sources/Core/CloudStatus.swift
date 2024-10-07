public enum CloudStatus: CustomStringConvertible, Sendable, CaseIterable {
    case notSupported, available, unavailable
    public var description: String {
        switch self {
        case .notSupported:
            "Not Supported"
        case .available:
            "Available"
        case .unavailable:
            "Unavailable"
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

#if canImport(SwiftUI)
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