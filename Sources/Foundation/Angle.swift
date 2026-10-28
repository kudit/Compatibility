/// SwiftUI-shaped angle that remains nameable on iOS 8, watchOS 4, and servers.
public struct Angle: Hashable, Codable, Sendable, Comparable {
	public var radians: Double
	public var degrees: Double {
		get { radians * 180 / .pi }
		set { radians = newValue * .pi / 180 }
	}
	public init(radians: Double) { self.radians = radians }
	public init(degrees: Double) { radians = degrees * .pi / 180 }
	public static func radians(_ value: Double) -> Self { Self(radians: value) }
	public static func degrees(_ value: Double) -> Self { Self(degrees: value) }
	public static let zero = Self(radians: 0)
	public static func < (lhs: Self, rhs: Self) -> Bool { lhs.radians < rhs.radians }
}
#if compiler(>=5.9) && canImport(Foundation)
import Foundation

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Angle {
    @MainActor
    static let tests: [TestCase] = [
        TestCase("Angle degree and radian conversions") {
            let quarterTurn = Angle.degrees(90)
            try expect(abs(quarterTurn.radians - .pi / 2) < 0.000_000_000_001)
            try expect(abs(quarterTurn.degrees - 90) < 0.000_000_000_001)

            var mutableAngle = Angle.radians(.pi / 2)
            mutableAngle.degrees = 180
            try expect(abs(mutableAngle.radians - .pi) < 0.000_000_000_001)
            try expectEqual(Angle.zero, Angle.radians(0))
        },
        TestCase("Angle comparison, hashing, and Codable") {
            let smaller = Angle.degrees(45)
            let larger = Angle.degrees(90)
            try expect(smaller < larger)
            try expect(Set([smaller, smaller, larger]).count == 2)

            let encoded = try JSONEncoder().encode(larger)
            let decoded = try JSONDecoder().decode(Angle.self, from: encoded)
            try expectEqual(decoded, larger)
        },
    ]
}
#endif
