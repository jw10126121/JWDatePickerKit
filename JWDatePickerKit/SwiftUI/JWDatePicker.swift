import SwiftUI
#if SWIFT_PACKAGE
import JWDatePickerKit
#endif

/// SwiftUI wrapper for the inline UIKit date picker.
@MainActor
public struct JWDatePicker: UIViewRepresentable {
    @Binding private var selection: Date

    public var type: JWDatePickerType
    public var minimumDate: Date?
    public var maximumDate: Date?
    public var calendar: Calendar
    public var locale: Locale
    public var selectionPolicy: JWDatePickerSelectionPolicy

    public init(
        selection: Binding<Date>,
        type: JWDatePickerType = .date,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        calendar: Calendar = .current,
        locale: Locale = .current,
        selectionPolicy: JWDatePickerSelectionPolicy = .preserveComponents
    ) {
        _selection = selection
        self.type = type
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.calendar = calendar
        self.locale = locale
        self.selectionPolicy = selectionPolicy
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    public func makeUIView(context: Context) -> JWDatePickerView {
        let picker = JWDatePickerView()
        picker.onSelectionChanged = { [weak coordinator = context.coordinator] date in
            coordinator?.selection.wrappedValue = date
        }
        applyConfiguration(to: picker)
        return picker
    }

    public func updateUIView(_ picker: JWDatePickerView, context: Context) {
        context.coordinator.selection = $selection
        applyConfiguration(to: picker)
    }

    private func applyConfiguration(to picker: JWDatePickerView) {
        let configuration = JWDatePickerConfiguration(
            type: type,
            selectedDate: selection,
            minimumDate: minimumDate,
            maximumDate: maximumDate,
            calendar: calendar,
            locale: locale,
            selectionPolicy: selectionPolicy
        )
        let current = picker.configuration
        guard current.type != configuration.type
                || current.selectedDate != configuration.selectedDate
                || current.minimumDate != configuration.minimumDate
                || current.maximumDate != configuration.maximumDate
                || current.calendar != configuration.calendar
                || current.locale != configuration.locale
                || current.selectionPolicy != configuration.selectionPolicy else { return }
        try? picker.apply(configuration)
    }

    @MainActor
    public final class Coordinator {
        fileprivate var selection: Binding<Date>

        fileprivate init(selection: Binding<Date>) {
            self.selection = selection
        }
    }
}
