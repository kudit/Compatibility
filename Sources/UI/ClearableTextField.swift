//
//  SwiftUIView.swift
//  
//
//  Created by Ben Ku on 7/30/24.
//
#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

// https://fatbobman.com/en/posts/textfield-event-focus-keyboard/

// TODO: Allow selection when tapping? https://stackoverflow.com/questions/67502138/select-all-text-in-textfield-upon-click-swiftui
@available(iOS 15, macOS 12, tvOS 15, watchOS 9, *)
public struct ClearableTextField: View {
    @State var label: String
    @Binding var text: String?
    @State private var fieldText: String// = "initial" - including an initial value causes this not to work?  Perhaps using synthesized initializer instead?
    // https://fatbobman.medium.com/advanced-swiftui-textfield-events-focus-keyboard-c99bc9f57c91
    @FocusState var isFocused:Bool
    public init(label: String, text: Binding<String?>) {
        self.label = label
        _text = text
        fieldText = text.wrappedValue ?? ""
    }
    func persistChanges() {
        let originalValue = _text.wrappedValue
        let newValue = fieldText
        guard originalValue != newValue else {
            // don't actually do anything if we just focus the field and nothing has changed
            return
        }
        if newValue == "" {
            text = nil
        } else {
            text = newValue
        }
    }
    
    public var body: some View {
        HStack {
            TextField(label, text: Binding(get: {
                fieldText
            }, set: {
                fieldText = $0
                #if os(watchOS)
                // since watchOS doesn't seem to use onEditingChanged or focused:
                    persistChanges()
                #endif
            }), onEditingChanged: {
                focused in
                // only set change when focus is lost and the value is changed, not while editing to prevent lots of noisy spam.  If we need to know as people are typing, we should install a hook here...
                if !focused {
                    persistChanges()
                }
            })
            .focused($isFocused)
            if fieldText != "" {
                Button {
                    fieldText = ""
                    isFocused = true
                } label: {
                    Group {
                        if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
                            Image(systemName: "multiply.circle.fill")
                        } else {
                            // Fallback on earlier versions
                            Text("🅧")
                        }
                    }
                    .foregroundColor(.gray) // since we have this, buttonStyle can be .plain
                    #if os(watchOS) // clear button is hard to target on watch
                    .padding(.leading, 10)
                    #endif
                }
                .buttonStyle(.plain)                        // ensures the clear button isn't automatically invoked when tapping on row.
            }
        }
        // ensure that outside changes appear here
        .backport.onChange(of: text) { oldValue, newValue in
            if let newValue {
                fieldText = newValue
            }
        }
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
struct TestClearer: View {
    @State var text: String? = "Foobar"
    
    var body: some View {
        List {
            Section("Section Header") {
                ClearableTextField(label: "Hello", text: $text)
                Text(text ?? "<nil>")
                    .foregroundStyle(text != nil ? .primary : .tertiary)
            }
        }
    }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
#Preview("Test Clearer") {
    TestClearer()
}

#endif
