//
//  Compatibility.swift
//
//  Created by Ben Ku on 7/5/2024.
//  Copyright © 2024 Kudit, LLC. All rights reserved.
//

public struct Compatibility {
    public static let version = "1.0.8"
}

// TODO: UNAVAILABLE
//@available(*, unavailable, message: "use native function rather than backport?")

/*
 
 For module checks to conditionally compile for versions:
 
 canImport(StoreKit)
     iOS 3.0+
     iPadOS 3.0+
     macOS 10.7+
     Mac Catalyst 13.0+
     tvOS 9.0+
     watchOS 6.2+
     visionOS 1.0+

 2015 (for OperatingSystemVersion)
 canImport(HealthKit) || canImport(Metal)
     iOS 8.0+ // Health, Metal
     iPadOS 8.0+ // Health, Metal
     macOS 10.10+
     Mac Catalyst 13.0+ // Metal
     tvOS 9.0+ // Metal
     watchOS 2.0+ // Health
     visionOS 1.0+ // Health, Metal
 
 2019
 canImport(SwiftUI) || canImport(Combine)
     iOS 13.0+
     iPadOS 13.0+
     macOS 10.15+
     Mac Catalyst 13.0+
     tvOS 13.0+
     watchOS 6.0+
     visionOS 1.0+

 2020
 canImport(AppleArchive)
     iOS 14.0+
     iPadOS 14.0+
     macOS 11.0+
     Mac Catalyst 14.0+
     tvOS 14.0+
     watchOS 7.0+
     visionOS 1.0+
 
 2021
 canImport(GroupActivities)
     iOS 15.0+
     iPadOS 15.0+
     macOS 12.0+
     Mac Catalyst 15.0+
     tvOS 15.0+
    NOTE: NO WATCH OS
     visionOS 1.0+
 
 2022 Swift 5.7 (September)
 canImport(Charts) canImport(AppIntents)
     iOS 16.0+
     iPadOS 16.0+
     macOS 13.0+
     Mac Catalyst 16.0+
     tvOS 16.0+
     watchOS 9.0+
     visionOS 1.0+

 2023 Swift 5.8 (March), Swift 5.9 (September) (added #Preview syntax)
 canImport(SwiftData)
     iOS 17.0+
     iPadOS 17.0+
     macOS 14.0+
     Mac Catalyst 17.0+
     tvOS 17.0+
     watchOS 10.0+
     visionOS 1.0+

2024 Swift 5.10 (March), Swift 6 (September)
canImport(Testing)
    iOS 18+
    iPadOS 18+
    macOS 15+
    Mac Catalyst 18+
    tvOS 18+
    watchOS 11+
    visionOS 2+
 
 */

// This has been a godsend! https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/
