#if canImport(SwiftUI)
import SwiftUI
#if canImport(Compatibility)
import Compatibility
#endif

@available(iOS 15.0, macOS 12, tvOS 17, watchOS 8, *)
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            CompatibilityDemoView()
        }
    }
}

@available(iOS 15, macOS 12.0, tvOS 17, watchOS 8, *)
#Preview {
    CompatibilityDemoView()
}

#endif
