#if canImport(SwiftUI)
import SwiftUI
#if canImport(Compatibility) // since this is needed in XCode but is unavailable in Playgrounds.
import Compatibility
#endif

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            CompatibilityDemoView()
        }
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview {
    CompatibilityDemoView()
}

#endif
