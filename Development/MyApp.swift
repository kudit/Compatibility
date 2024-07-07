#if canImport(SwiftUI)
import SwiftUI
#if canImport(Compatibility)
import Compatibility
#endif

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            AllTestsListView()
        }
    }
}

@available(macOS 12.0, *)
#Preview {
    AllTestsListView()
}

#endif
