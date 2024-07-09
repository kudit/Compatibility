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
