//
//  ObservableObject.swift
//  
//
//  Created by Ben Ku on 7/7/24.
//

#if !canImport(Combine)
// Add stub here to make sure we can compile
public protocol ObservableObject {
    var objectWillChange: ObjectWillChangePublisher { get }
}
public struct ObjectWillChangePublisher: Sendable {
    func send() {} // dummy for calls
    static let dummyPublisher = ObjectWillChangePublisher()
}
public extension ObservableObject {
    var objectWillChange: ObjectWillChangePublisher {
        return .dummyPublisher
    }
}
#endif