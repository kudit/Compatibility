//
//  Pasteboard.swift
//  Compatibility
//
//  Created by Ben Ku on 5/4/25.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A platform-neutral pasteboard item containing one or more typed byte representations.
///
/// Type names use platform pasteboard identifiers such as `public.utf8-plain-text`. Raw bytes keep this
/// value portable and allow callers to preserve rich system pasteboard contents without importing UIKit
/// or AppKit.
public struct PasteboardItem: Equatable, Sendable {
    /// Raw data keyed by uniform pasteboard type identifier.
    public var representations: [String: [UInt8]]

    /// Creates a pasteboard item from typed byte representations.
    ///
    /// - Parameter representations: Raw bytes keyed by uniform pasteboard type identifier.
    public init(representations: [String: [UInt8]]) {
        self.representations = representations
    }

    /// Creates a plain-text pasteboard item.
    ///
    /// - Parameter string: UTF-8 text to store.
    public init(string: String) {
        self.representations = [Pasteboard.plainTextType: Array(string.utf8)]
    }

    /// The first UTF-8 plain-text representation in this item, when available.
    public var string: String? {
        if let bytes = representations[Pasteboard.plainTextType] {
            return String(decoding: bytes, as: UTF8.self)
        }
        // Accept related platform text identifiers when reading content written by another application.
        for (type, bytes) in representations where type.lowercased().contains("text") {
            return String(decoding: bytes, as: UTF8.self)
        }
        return nil
    }
}

/// A pasteboard interface that uses the system clipboard where supported and in-memory storage elsewhere.
///
/// ``system`` bridges `UIPasteboard` on iOS, iPadOS, visionOS, and Mac Catalyst, and `NSPasteboard` on
/// macOS. watchOS, tvOS, WASM, and other pure-Swift environments do not expose a system pasteboard API,
/// so the same interface provides process-local storage there.
@MainActor
public final class Pasteboard {
    /// Uniform type identifier used for UTF-8 plain text.
    nonisolated public static let plainTextType = "public.utf8-plain-text"

    /// Shared system pasteboard, or a process-local substitute on unsupported platforms.
    public static let system = Pasteboard(usesSystemPasteboard: true)

    /// Whether this build has an operating-system pasteboard implementation.
    public static var isSystemPasteboardAvailable: Bool {
#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        return true
#elseif canImport(AppKit)
        return true
#else
        return false
#endif
    }

    private let usesSystemPasteboard: Bool
    private var storedItems = [PasteboardItem]()

    /// Creates an isolated in-memory pasteboard suitable for deterministic tests and temporary workflows.
    public convenience init() {
        self.init(usesSystemPasteboard: false)
    }

    /// Selects system or process-local storage for the shared and isolated instances.
    private init(usesSystemPasteboard: Bool) {
        self.usesSystemPasteboard = usesSystemPasteboard
    }

    /// Replaces the pasteboard contents with typed items.
    ///
    /// - Parameter items: Items to write in their existing order.
    public func copy(_ items: [PasteboardItem]) {
        copyToPasteboard(items)
    }

    /// Replaces the pasteboard contents with one plain-text item.
    ///
    /// - Parameter string: UTF-8 text to copy.
    public func copy(_ string: String) {
        copy([PasteboardItem(string: string)])
    }

    /// Replaces the pasteboard contents with typed items on every supported platform.
    ///
    /// Unsupported system-pasteboard platforms retain the values in process-local memory so reads through
    /// this instance remain consistent without pretending to communicate with other applications.
    ///
    /// - Parameter items: Items to write in their existing order.
    public func copyToPasteboard(_ items: [PasteboardItem]) {
        guard usesSystemPasteboard else {
            storedItems = items
            return
        }
#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        // UIKit accepts pasteboard dictionaries keyed by uniform type identifier.
        UIPasteboard.general.items = items.map { item in
            item.representations.reduce(into: [String: Any]()) { result, representation in
                result[representation.key] = Data(representation.value)
            }
        }
#elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let platformItems = items.map { item in
            let platformItem = NSPasteboardItem()
            for (type, bytes) in item.representations {
                platformItem.setData(Data(bytes), forType: NSPasteboard.PasteboardType(type))
            }
            return platformItem
        }
        if !platformItems.isEmpty {
            pasteboard.writeObjects(platformItems)
        }
#else
        storedItems = items
#endif
    }

    /// Reads every typed item currently stored on this pasteboard.
    ///
    /// - Returns: Items in pasteboard order with their available raw representations.
    public func read() -> [PasteboardItem] {
        return readFromPasteboard()
    }

    /// Reads the first available plain-text value.
    ///
    /// - Returns: The first readable UTF-8 string, or `nil` when no text is available.
    public func readString() -> String? {
        for item in readFromPasteboard() {
            if let string = item.string {
                return string
            }
        }
        return nil
    }

    /// Reads every typed item through a common API on all supported platforms.
    ///
    /// - Returns: System pasteboard items, or process-local items where no system API exists.
    public func readFromPasteboard() -> [PasteboardItem] {
        guard usesSystemPasteboard else {
            return storedItems
        }
#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        let pasteboard = UIPasteboard.general
        return pasteboard.items.enumerated().map { index, platformItem in
            var representations = [String: [UInt8]]()
            for type in platformItem.keys {
                // Ask UIKit for the raw representation so images, URLs, and other registered types are retained.
                if let data = pasteboard.data(forPasteboardType: type, inItemSet: IndexSet(integer: index))?.first {
                    representations[type] = Array(data)
                } else if let string = platformItem[type] as? String {
                    // Some text providers expose a String rather than raw Data, so retain its UTF-8 bytes.
                    representations[type] = Array(string.utf8)
                }
            }
            return PasteboardItem(representations: representations)
        }
#elseif canImport(AppKit)
        return (NSPasteboard.general.pasteboardItems ?? []).map { platformItem in
            var representations = [String: [UInt8]]()
            for type in platformItem.types {
                if let data = platformItem.data(forType: type) {
                    representations[type.rawValue] = Array(data)
                }
            }
            return PasteboardItem(representations: representations)
        }
#else
        return storedItems
#endif
    }
}

public extension Compatibility {
    /// Copies text to the system pasteboard.
    ///
    /// - Parameter string: Text to copy.
    @available(*, deprecated, message: "Use Pasteboard.system.copy(_:) instead.")
    @MainActor
    static func copyToPasteboard(_ string: String) {
        // Forward legacy callers to the platform-neutral pasteboard facade.
        Pasteboard.system.copy(string)
    }
}

#if compiler(>=5.9) && !(os(WASM) || os(WASI))
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
extension Pasteboard {
    /// Deterministic pasteboard tests shared by the in-app runner and Swift Testing.
    @MainActor
    internal static let tests: [TestCase] = [
        TestCase("In-memory text pasteboard") { @MainActor in
            let pasteboard = Pasteboard()
            pasteboard.copy("Compatibility pasteboard test")
            try expect(pasteboard.readString() == "Compatibility pasteboard test", "Expected the copied text to round-trip")
        },
        TestCase("In-memory typed pasteboard items") { @MainActor in
            let pasteboard = Pasteboard()
            let items = [
                PasteboardItem(representations: [
                    Pasteboard.plainTextType: Array("First".utf8),
                    "com.kudit.test": [0, 1, 2, 3],
                ]),
                PasteboardItem(string: "Second"),
            ]
            pasteboard.copy(items)
            try expect(pasteboard.read() == items, "Expected typed pasteboard items to retain bytes and ordering")
            try expect(pasteboard.readString() == "First", "Expected the first text representation")
        },
    ]
}
#endif
