#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI
#if canImport(Compatibility) // since this is needed in XCode but is unavailable in Playgrounds.
import Compatibility
#endif

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@main
struct MyApp: App {
    init() {
        /* Copy these settings at the beginning of your init() code to configure Compatibility debug behavior.
        // Configure debug settings
        Compatibility.settings.debugLevelCurrent = .SILENT
        Compatibility.settings.debugLevelDefault = DebugLevel.ERROR
        Compatibility.settings.debugEmojiSupported = false
        Compatibility.settings.debugLevelsToIncludeContext = DebugLevels.all
        Compatibility.settings.debugIncludeTimestamp = true
        let defaultImplementation = Compatibility.settings.debugFormat
        Compatibility.settings.debugFormat = { (message: String, level: DebugLevel, isMainThread: Bool, emojiSupported: Bool, includeContext: Bool, includeTimestamp: Bool, file: String, function: String, line: Int, column: Int) -> String in
            let formatted = defaultImplementation(
                message,
                level,
                isMainThread,
                emojiSupported,
                includeContext,
                includeTimestamp,
                file, function, line, column)
            return "🔹\(formatted)"
        }
         */

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
#if compiler(>=5.9)
            CompatibilityDemoView()
#else
            Text("Please upgrade to Swift 5.9 for demo app.")
#endif
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

#if compiler(>=5.9)
@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview {
    CompatibilityDemoView()
}
#endif
#endif
