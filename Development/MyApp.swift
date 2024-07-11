#if canImport(SwiftUI)
import SwiftUI
#if canImport(Compatibility)
import Compatibility
#endif

@available(iOS 15.0, tvOS 17, watchOS 8, *)
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            AllTestsListView()
        }
    }
}

@available(macOS 12.0, iOS 15, tvOS 17, watchOS 8, *)
#Preview {
    AllTestsListView()
}

@available(iOS 13, *)
#Preview {
    RoundedRectangle(cornerRadius: 15)
        .frame(width: 50, height: 50)
        .foregroundColor(.green)
        .backport.overlay {
            Image(systemName: "applelogo")
                .imageScale(.large)
                .foregroundColor(.white)
        }
        .background(Color.yellow)
}

#endif
