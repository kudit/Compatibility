#if canImport(SwiftUI)
import SwiftUI
#if canImport(Compatibility) // since this is needed in XCode but is unavailable in Playgrounds.
import Compatibility
#endif

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@main
struct MyApp: App {
    init() {
        //Application.iCloudSupported = false
        Application.track() // ensures Application.main.isFirstRun and Application.main.versions variables are properly set.
        if Application.main.isFirstRun {
            debug("First Run!")
        }
        debug("All versions run: \(Application.main.versionsRun)")
        background {
            debug("Run background task (for testing)")
        }
    }
    var body: some Scene {
        WindowGroup {
            CompatibilityDemoView()
        }

        #if os(macOS)
        Settings { // For settings/preferences screen within the app
            TabView {
                Group{
                    //ContentsOf the preferences view
                    Text("Test Settings")
                }
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
                
            }
            .frame(width: 500, height: 280)
        }
        #endif
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview {
    CompatibilityDemoView()
}

#endif
