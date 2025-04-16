// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription

let version = "1.9.3"
let packageLibraryName = "Compatibility"

// Products define the executables and libraries a package produces, making them visible to other packages.
var products = [
	Product.library(
		name: "\(packageLibraryName) Library", // has to be named different from the iOSApplication or Swift Playgrounds won't open correctly
		targets: [packageLibraryName]
	),
]

// Targets are the basic building blocks of a package, defining a module or a test suite.
// Targets can depend on other targets in this package and products from dependencies.
var targets = [
	Target.target(
		name: packageLibraryName,
		dependencies: [
//			.product(name: "Compatibility Library", package: "compatibility"), // apparently needs to be lowercase.  Also note this is "Compatibility Library" not "Compatibility"
		],
		path: "Sources"
		// If resources need to be included in the module, include here
//		,resources: [ // unfortuantely cannot be conditionally compiled based on Swift version since the tool seems to be run on latest version.
//			Resource.process("Resources"),
//		]
//		,swiftSettings: [
//			.enableUpcomingFeature("BareSlashRegexLiterals")
//		]
	),
]

var platforms: [SupportedPlatform] = [
	.macOS("10.15"), // minimum for sleep, SwiftUI, ObservableObject, & @Published, 12 minimum for Date.now
	.tvOS("11"), // 13 minimum for SwiftUI, 15 minimum for Date.now, 17 minimum for Menu
	.watchOS("4"), // 6 minimum for SwiftUI, watchOS 7 typically needed for most UI, 8 for Date.now, however (for #buildAvailability) so really should be watchOS 9+.
]

#if canImport(PlaygroundSupport)
platforms += [
	.iOS("15.2"), // minimum for Swift Playgrounds support (maximum version for test iPhone 7)
]
#else
platforms += [
	.iOS("11"), // 13 minimum for Combine/SwiftUI, 15 minimum for Date.now, (maximum version for test iPhone 7)
]
#endif

#if compiler(>=5.9)
#if os(visionOS)
platforms += [
	.visionOS("1.0"), // unavailable in Swift Playgrounds so has to be separate
]
#endif
#endif

#if canImport(AppleProductTypes) // swift package dump-package fails because of this
import AppleProductTypes

let executableTargetName = "\(packageLibraryName)TestAppModule"

products += [
	.iOSApplication(
		name: "\(packageLibraryName) App", // needs to match package name to open properly in Swift Playgrounds <v4.5, but must be different to run in v4.6 and greater.
		targets: [executableTargetName],
//		bundleIdentifier: "com.kudit.compatibility", // ignored in playgrounds
		teamIdentifier: "3QPV894C33",
		displayVersion: version,
		bundleVersion: "1",
		appIcon: .asset("AppIcon"),
		accentColor: .presetColor(.orange),
		supportedDeviceFamilies: [
			.pad,
			.phone
		],
		supportedInterfaceOrientations: [
			.portrait,
			.landscapeRight,
			.landscapeLeft,
			.portraitUpsideDown(.when(deviceFamilies: [.pad]))
		],
		capabilities: [
			.outgoingNetworkConnections() // for networking tests
		],
		appCategory: .developerTools
	),
]

targets += [
	.executableTarget(
		name: executableTargetName,
		dependencies: [
			.init(stringLiteral: packageLibraryName), // have to use init since normally would be assignable by string literal but we're not using a string literal
		],
		path: "Development"
		,exclude: ["Resources"]
		// Include test app resources.
		,resources: [
//            .process("PlaygroundsAssets.xcassets")
		]
//		,swiftSettings: [
//            .define("COMPATIBILITY_CUSTOM_SETTINGS"),
//			.enableUpcomingFeature("BareSlashRegexLiterals"),
//		]
	),
//	.testTarget(
//		name: "\(packageLibraryName)Tests",
//		dependencies: [
//			.init(stringLiteral: packageLibraryName), // have to use init since normally would be assignable by string literal but we're not using a string literal
//		],
//		path: "Tests"
//	),
]

#endif // for Swift Package compiling for https://swiftpackageindex.com/add-a-package

let package = Package(
	name: packageLibraryName,
	platforms: platforms,
	products: products,
	// include dependencies
	dependencies: [
		// Dependencies declare other packages that this package depends on.
//		.package(url: "https://github.com/kudit/Compatibility", "1.1.0"..<"2.0.0"),
	],
	targets: targets
)
