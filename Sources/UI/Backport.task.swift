//
//  Backport.task.swift
//  Compatibility
//

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

/// Backports SwiftUI's asynchronous task modifier to the package's minimum OS versions.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public extension Backport where Content: View {
	/// Starts an asynchronous task when the view appears and cancels it when the view disappears.
	///
	/// On iOS 15, macOS 12, tvOS 15, and watchOS 8 or later, this uses SwiftUI's native
	/// `View.task(priority:_:)` modifier. Earlier systems start the task from `onAppear` and
	/// cooperatively cancel it from `onDisappear`, matching the native modifier's view-lifetime
	/// behavior as closely as the older SwiftUI lifecycle allows. Like SwiftUI's modifier, the
	/// action inherits the actor context where this method is called.
	///
	/// Cancellation is cooperative: the operation must observe task cancellation to stop promptly.
	///
	/// - Parameters:
	///   - priority: The priority to use for the task. Defaults to `.userInitiated`.
	///   - action: The asynchronous operation to run while the view is present.
	/// - Returns: A view that manages the asynchronous operation with its appearance.
	@ViewBuilder
	func task(
		priority: TaskPriority = .userInitiated,
		@_inheritActorContext _ action: @escaping @Sendable () async -> Void
	) -> some View {
		if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
			content.task(priority: priority, action)
		} else {
			legacyTask(priority: priority, action)
		}
	}

	/// Creates the appearance-managed modifier directly for exercising pre-native task behavior on modern hosts.
	@ViewBuilder
	func legacyTask(
		priority: TaskPriority = .userInitiated,
		@_inheritActorContext _ action: @escaping @Sendable () async -> Void
	) -> some View {
		content.modifier(LegacyTaskModifier(priority: priority, action: action))
	}
}

/// Owns and cancels the task for SwiftUI releases before the native task modifier existed.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor

struct LegacyTaskModifier: ViewModifier {
	let priority: TaskPriority
	let action: @Sendable () async -> Void
	@State private var task: Task<Void, Never>?

	init(priority: TaskPriority, action: @escaping @Sendable () async -> Void) {
		self.priority = priority
		self.action = action
	}

	func body(content: Content) -> some View {
		content
			.onAppear {
				startTask()
			}
			.onDisappear {
				cancelTask()
			}
	}

	/// Starts or replaces the legacy view-lifetime task.
	func startTask() {
		task?.cancel()
		task = Task(priority: priority, operation: action)
	}

	/// Cancels and releases the legacy task when its view disappears.
	func cancelTask() {
		task?.cancel()
		task = nil
	}
}

#endif
