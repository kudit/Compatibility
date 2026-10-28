//
//  LegacyList.swift
//  Compatibility
//

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

/// A scrollable, stack-based list for layouts that need their rows to report animated sizes.
///
/// `LegacyList` uses a `ScrollView` and `LazyVStack` on systems that support lazy stack sections.
/// Older systems retain the native `List` implementation. Rows can use `LegacyListRow` for the
/// inset and separator treatment used by Compatibility's diagnostic list. Use
/// ``LegacyListSection`` for section headers that retain native-list hierarchy and emphasis.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct LegacyList<Content: View>: View {
	private let content: Content

	/// Creates a list from section and row content.
	public init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	public var body: some View {
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			ScrollView {
				LazyVStack(alignment: .leading, spacing: 0) {
					content
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}
		} else {
			List {
				content
			}
		}
	}
}

/// A titled section for ``LegacyList`` with the hierarchy and spacing of a native list section.
///
/// In the stack-backed presentation, the heading is rendered explicitly because `Section` has no
/// list container to provide its platform styling. On older systems, the heading remains a native
/// `Section` header inside `List`.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct LegacyListSection<Content: View>: View {
	private let title: Text
	private let content: Content

	/// Creates a titled section.
	public init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
		self.title = Text(title)
		self.content = content()
	}

	/// Creates a titled section from an already-resolved string.
	public init<S: StringProtocol>(_ title: S, @ViewBuilder content: () -> Content) {
		self.title = Text(title)
		self.content = content()
	}

	public var body: some View {
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			VStack(alignment: .leading, spacing: 0) {
				title
					.font(.headline)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.horizontal, 16)
					.padding(.top, 16)
					.padding(.bottom, 6)
				content
			}
		} else {
			Section(header: title) {
				content
			}
		}
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct LegacyListFieldSections: View {
    public let sections: OrderedDictionary<String, [Field]>

    public init(sections: OrderedDictionary<String, [Field]>) {
        self.sections = sections
    }

    public var body: some View {
        ForEach(sections.keys.elements, id: \.self) { key in
            let fields = sections[key] ?? []
            LegacyListSection(key) {
                ForEach(fields.indices, id: \.self) { index in
                    LegacyListRow {
                        FieldView(fields[index])
                    }
                }
            }
        }
    }
}

/// Applies the inset, minimum height, and separator treatment used by `LegacyList` rows.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct LegacyListRow<Content: View>: View {
	private let content: Content

	public init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	public var body: some View {
		content
			.padding(.horizontal, 16)
			.frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
			.overlay(alignment: .bottom) {
				Rectangle()
					.fill(Color.primary.opacity(0.12))
					.frame(height: 0.5)
					.padding(.leading, 16)
					.accessibilityHidden(true)
			}
	}
}

#endif
