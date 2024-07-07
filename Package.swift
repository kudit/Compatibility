// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription

let version = "1.0.1"
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
//            .product(name: "Collections", package: "swift-collections"),
//            .product(name: "OrderedCollections", package: "swift-collections"),
//			.product(name: "CustomType", package: "customtype"), // apparently needs to be lowercase.  Also note this is "Device Library" not "Device"
		],
		path: "Sources"
	),
]

var platforms: [SupportedPlatform] = [
	.iOS("15.2"), // minimum for Swift Playgrounds support
	.macOS("10.15"), // minimum for sleep, SwiftUI, ObservableObject, & @Published
	.tvOS("17"), // 13 minimum for SwiftUI, 17 minimum for Menu
	.watchOS("6"), // minimum for SwiftUI, watchOS 7 typically needed for most UI, however (for #buildAvailability) so really should be watchOS 9+.
]

#if os(visionOS)
platforms += [
    .visionOS("1.0"), // unavailable in Swift Playgrounds
]
#endif

#if canImport(AppleProductTypes) // swift package dump-package fails because of this
import AppleProductTypes

products += [
	.iOSApplication(
		name: packageLibraryName, // needs to match package name to open properly in Swift Playgrounds
		targets: ["\(packageLibraryName)TestAppModule"],
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
		appCategory: .developerTools
	),
]

targets += [
	.executableTarget(
		name: "\(packageLibraryName)TestAppModule",
		dependencies: [
			.init(stringLiteral: packageLibraryName), // have to use init since normally would be assignable by string literal but we're not using a string literal
		],
		path: "Development",
		resources: [
			.process("Resources")
		]
	),
]

#endif // for Swift Package compiling for https://swiftpackageindex.com/add-a-package

let package = Package(
    name: packageLibraryName,
    platforms: platforms,
    products: products,
    dependencies: [
        // Dependencies declare other packages that this package depends on.
//        .package(url: "https://github.com/apple/swift-collections", "1.1.1"..<"2.0.0")
//        .package(url: "https://github.com/kudit/CustomType", "1.0.0"..<"2.0.0"),
    ],
    targets: targets
)
