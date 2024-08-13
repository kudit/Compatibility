//
//  ObservableObject.swift
//  
//
//  Created by Ben Ku on 7/7/24.
//

#if !canImport(Combine) // for Linux and older OS support so we can use @CloudStorage but fall back to UserDefaults.
// Add stub here to make sure we can compile
public protocol ObservableObject {
    associatedtype ObjectWillChangePublisher : Publisher = ObservableObjectPublisher where Self.ObjectWillChangePublisher.Failure == Never
    var objectWillChange: ObjectWillChangePublisher { get }
}
public protocol ObjectWillChangePublisher: ObservableObjectPublisher, Sendable {
    func send()
}
public extension ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    var objectWillChange: ObjectWillChangePublisher {
        return ObservableObjectPublisher()
    }
}

@propertyWrapper public struct Published<Value> {
    public var wrappedValue: Value
    
    /// Creates the published instance with an initial wrapped value.
    ///
    /// Don't use this initializer directly. Instead, create a property with the `@Published` attribute, as shown here:
    ///
    ///     @Published var lastUpdated: Date = Date()
    ///
    /// - Parameter wrappedValue: The publisher's initial value.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    /// Creates the published instance with an initial value.
    ///
    /// Don't use this initializer directly. Instead, create a property with the `@Published` attribute, as shown here:
    ///
    ///     @Published var lastUpdated: Date = Date()
    ///
    /// - Parameter initialValue: The publisher's initial value.
    public init(initialValue: Value) {
        self.wrappedValue = initialValue
    }
}

public protocol DynamicProperty {}


@propertyWrapper @frozen public struct ObservedObject<ObjectType> where ObjectType : ObservableObject {
    /// Creates an observed object with an initial value.
    ///
    /// This initializer has the same behavior as the ``init(wrappedValue:)``
    /// initializer. See that initializer for more information.
    ///
    /// - Parameter initialValue: An initial value.
    @MainActor
    public init(initialValue: ObjectType) {
        wrappedValue = initialValue
    }

    /// Creates an observed object with an initial wrapped value.
    ///
    /// Don't call this initializer directly. Instead, declare
    /// an input to a view with the `@ObservedObject` attribute, and pass a
    /// value to this input when you instantiate the view. Unlike a
    /// ``StateObject`` which manages data storage, you use an observed
    /// object to refer to storage that you manage elsewhere, as in the
    /// following example:
    ///
    ///     class DataModel: ObservableObject {
    ///         @Published var name = "Some Name"
    ///         @Published var isEnabled = false
    ///     }
    ///
    ///     struct MyView: View {
    ///         @StateObject private var model = DataModel()
    ///
    ///         var body: some View {
    ///             Text(model.name)
    ///             MySubView(model: model)
    ///         }
    ///     }
    ///
    ///     struct MySubView: View {
    ///         @ObservedObject var model: DataModel
    ///
    ///         var body: some View {
    ///             Toggle("Enabled", isOn: $model.isEnabled)
    ///         }
    ///     }
    ///
    /// Explicitly calling the observed object initializer in `MySubView` would
    /// behave correctly, but would needlessly recreate the same observed object
    /// instance every time SwiftUI calls the view's initializer to redraw the
    /// view.
    ///
    /// - Parameter wrappedValue: An initial value for the observable object.
    @MainActor
    public init(wrappedValue: ObjectType) { self.wrappedValue = wrappedValue }

    /// The underlying value that the observed object references.
    ///
    /// The wrapped value property provides primary access to the observed
    /// object's data. However, you don't typically access it by name. Instead,
    /// SwiftUI accesses this property for you when you refer to the variable
    /// that you create with the `@ObservedObject` attribute.
    ///
    ///     struct MySubView: View {
    ///         @ObservedObject var model: DataModel
    ///
    ///         var body: some View {
    ///             Text(model.name) // Reads name from model's wrapped value.
    ///         }
    ///     }
    ///
    /// When you change a wrapped value, you can access the new value
    /// immediately. However, SwiftUI updates views that display the value
    /// asynchronously, so the interface might not update immediately.
    @MainActor public var wrappedValue: ObjectType
}



/// A publisher that publishes changes from observable objects.
final public class ObservableObjectPublisher : Publisher {
    /// The kind of values published by this publisher.
    public typealias Output = Void

    /// The kind of errors this publisher might publish.
    ///
    /// Use `Never` if this `Publisher` does not publish errors.
    public typealias Failure = Never

    /// Creates an observable object publisher instance.
    public init() {} // dummy

    /// Attaches the specified subscriber to this publisher.
    ///
    /// Implementations of ``Publisher`` must implement this method.
    ///
    /// The provided implementation of ``Publisher/subscribe(_:)-4u8kn``calls this method.
    ///
    /// - Parameter subscriber: The subscriber to attach to this ``Publisher``, after which it can receive values.
    final public func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Never, S.Input == () {}

    /// Sends the changed value to the downstream subscriber.
    final public func send() {}
}

public protocol Subscriber<Input, Failure> {
    /// The kind of values this subscriber receives.
    associatedtype Input

    /// The kind of errors this subscriber might receive.
    ///
    /// Use `Never` if this `Subscriber` cannot receive errors.
    associatedtype Failure : Error

    /// Tells the subscriber that it has successfully subscribed to the publisher and may request items.
    ///
    /// Use the received ``Subscription`` to request items from the publisher.
    /// - Parameter subscription: A subscription that represents the connection between publisher and subscriber.
    func receive(subscription: any Subscription)

    /// Tells the subscriber that the publisher has produced an element.
    ///
    /// - Parameter input: The published element.
    /// - Returns: A `Subscribers.Demand` instance indicating how many more elements the subscriber expects to receive.
    func receive(_ input: Self.Input) -> Subscribers.Demand

    /// Tells the subscriber that the publisher has completed publishing, either normally or with an error.
    ///
    /// - Parameter completion: A ``Subscribers/Completion`` case indicating whether publishing completed normally or with an error.
    func receive(completion: Subscribers.Completion<Self.Failure>)
}

public protocol Subscription : Cancellable {
    /// Tells a publisher that it may send more values to the subscriber.
    func request(_ demand: Subscribers.Demand)
}

public enum Subscribers {
    /// A requested number of items, sent to a publisher from a subscriber through the subscription.
    @frozen public struct Demand : Equatable, Hashable, Codable {}
    
    /// A signal that a publisher doesn’t produce additional elements, either due to normal completion or an error.
    @frozen public enum Completion<Failure> where Failure : Error {
        /// The publisher finished normally.
        case finished
        /// The publisher stopped publishing due to the indicated error.
        case failure(Failure)
    }
}

public protocol Cancellable {
    /// Cancel the activity.
    ///
    /// When implementing ``Cancellable`` in support of a custom publisher, implement `cancel()` to request that your publisher stop calling its downstream subscribers. Combine doesn't require that the publisher stop immediately, but the `cancel()` call should take effect quickly. Canceling should also eliminate any strong references it currently holds.
    ///
    /// After you receive one call to `cancel()`, subsequent calls shouldn't do anything. Additionally, your implementation must be thread-safe, and it shouldn't block the caller.
    ///
    /// > Tip: Keep in mind that your `cancel()` may execute concurrently with another call to `cancel()` --- including the scenario where an ``AnyCancellable`` is deallocating --- or to ``Subscription/request(_:)``.
    func cancel()
}


public protocol Publisher<Output, Failure> {
    /// The kind of values published by this publisher.
    associatedtype Output

    /// The kind of errors this publisher might publish.
    ///
    /// Use `Never` if this `Publisher` does not publish errors.
    associatedtype Failure : Error

//    /// Attaches the specified subscriber to this publisher.
//    ///
//    /// Implementations of ``Publisher`` must implement this method.
//    ///
//    /// The provided implementation of ``Publisher/subscribe(_:)-4u8kn``calls this method.
//    ///
//    /// - Parameter subscriber: The subscriber to attach to this ``Publisher``, after which it can receive values.
//    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
}

#endif
