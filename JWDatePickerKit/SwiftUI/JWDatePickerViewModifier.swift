import SwiftUI

#if SWIFT_PACKAGE
import JWDatePickerKit
#endif

public extension View {
    /// 以底部弹层形式呈现日期选择器，与 `.jwTextPicker` 用法对齐。
    @MainActor
    func jwDatePicker(
        isPresented: Binding<Bool>,
        selection: Binding<Date>,
        type: JWDatePickerType = .date,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        calendar: Calendar = .current,
        locale: Locale = .current,
        selectionPolicy: JWDatePickerSelectionPolicy = .preserveComponents,
        onConfirm: ((Date) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) -> some View {
        background(
            JWDatePickerPresenter(
                isPresented: isPresented,
                selection: selection,
                type: type,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                calendar: calendar,
                locale: locale,
                selectionPolicy: selectionPolicy,
                onConfirm: onConfirm,
                onCancel: onCancel
            )
            .frame(width: 0, height: 0)
        )
    }
}

private struct JWDatePickerPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selection: Date
    let type: JWDatePickerType
    let minimumDate: Date?
    let maximumDate: Date?
    let calendar: Calendar
    let locale: Locale
    let selectionPolicy: JWDatePickerSelectionPolicy
    let onConfirm: ((Date) -> Void)?
    let onCancel: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> JWDatePickerAnchorController {
        JWDatePickerAnchorController()
    }

    func updateUIViewController(_ anchor: JWDatePickerAnchorController, context: Context) {
        let coordinator = context.coordinator
        coordinator.isPresented = $isPresented
        coordinator.selection = $selection
        coordinator.type = type
        coordinator.minimumDate = minimumDate
        coordinator.maximumDate = maximumDate
        coordinator.calendar = calendar
        coordinator.locale = locale
        coordinator.selectionPolicy = selectionPolicy
        coordinator.onConfirm = onConfirm
        coordinator.onCancel = onCancel
        coordinator.updatePresentation(from: anchor)
    }

    @MainActor
    final class Coordinator {
        var isPresented = Binding.constant(false)
        var selection = Binding.constant(Date())
        var type: JWDatePickerType = .date
        var minimumDate: Date?
        var maximumDate: Date?
        var calendar: Calendar = .current
        var locale: Locale = .current
        var selectionPolicy: JWDatePickerSelectionPolicy = .preserveComponents
        var onConfirm: ((Date) -> Void)?
        var onCancel: (() -> Void)?
        private var presentedController: JWDatePickerViewController?

        func updatePresentation(from anchor: UIViewController) {
            guard anchor.viewIfLoaded?.window != nil else { return }

            guard isPresented.wrappedValue else {
                guard let controller = presentedController, !controller.isBeingDismissed else { return }
                controller.dismiss(animated: true) { [weak self] in
                    self?.presentedController = nil
                }
                return
            }

            guard presentedController == nil else { return }

            let controller = JWDatePickerViewController()
            let configuration = JWDatePickerConfiguration(
                type: type,
                selectedDate: selection.wrappedValue,
                minimumDate: minimumDate,
                maximumDate: maximumDate,
                calendar: calendar,
                locale: locale,
                selectionPolicy: selectionPolicy
            )
            try? controller.apply(configuration)
            controller.confirmHandler = { [weak self, weak controller] date in
                guard let self else { return }
                self.selection.wrappedValue = date
                self.onConfirm?(date)
                if let controller { self.finish(controller: controller) }
            }
            controller.cancelHandler = { [weak self, weak controller] in
                guard let self else { return }
                self.onCancel?()
                if let controller { self.finish(controller: controller) }
            }

            presentedController = controller
            anchor.present(controller, animated: true)
        }

        private func finish(controller: JWDatePickerViewController) {
            isPresented.wrappedValue = false
            Task { @MainActor [weak self, weak controller] in
                guard let self else { return }
                let done = { self.presentedController = nil }
                if let controller, controller.presentingViewController != nil, !controller.isBeingDismissed {
                    controller.dismiss(animated: true, completion: done)
                } else {
                    done()
                }
            }
        }
    }
}

private final class JWDatePickerAnchorController: UIViewController {
    override func loadView() {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        self.view = view
    }
}
