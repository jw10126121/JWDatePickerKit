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
                wantsPresentation: isPresented.wrappedValue,
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
    let wantsPresentation: Bool
    @Binding var selection: Date
    let type: JWDatePickerType
    let minimumDate: Date?
    let maximumDate: Date?
    let calendar: Calendar
    let locale: Locale
    let selectionPolicy: JWDatePickerSelectionPolicy
    let onConfirm: ((Date) -> Void)?
    let onCancel: (() -> Void)?


    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> PickerPresentationAnchor { PickerPresentationAnchor() }

    func updateUIViewController(_ anchor: PickerPresentationAnchor, context: Context) {
        let coordinator = context.coordinator
        coordinator.isPresented = $isPresented
        coordinator.makeController = {
            let controller = JWDatePickerViewController()
            let configuration = JWDatePickerConfiguration(
                type: type, selectedDate: selection, minimumDate: minimumDate, maximumDate: maximumDate,
                calendar: calendar, locale: locale, selectionPolicy: selectionPolicy
            )
            do {
                try controller.apply(configuration)
                return controller
            } catch {
                return nil
            }
        }
        coordinator.deliver = { result, _ in
            switch result {
            case let .confirmed(date):
                selection = date
                onConfirm?(date)
            case .cancelled:
                onCancel?()
            }
        }
        anchor.onReady = { [weak coordinator, weak anchor] in
            guard let coordinator, let anchor else { return }
            coordinator.update(from: anchor)
        }
        Task { @MainActor [weak coordinator, weak anchor] in
            guard let coordinator, let anchor else { return }
            if wantsPresentation == coordinator.isPresented.wrappedValue { coordinator.update(from: anchor) }
        }
    }

    static func dismantleUIViewController(_ anchor: PickerPresentationAnchor, coordinator: Coordinator) {
        anchor.onReady = nil
        coordinator.remove()
    }

    @MainActor
    final class Coordinator {
        var isPresented = Binding.constant(false)
        var makeController: (() -> JWDatePickerViewController?)?
        var deliver: ((JWDatePickerResult, JWDatePickerViewController) -> Void)?
        private var presentedController: JWDatePickerViewController?
        private var isDismissing = false

        func update(from anchor: PickerPresentationAnchor) {
            guard anchor.viewIfLoaded?.window != nil else { return }
            if let controller = presentedController {
                if isDismissing { return }
                if controller.presentingViewController != nil {
                    if !isPresented.wrappedValue { dismiss(controller, from: anchor) }
                    return
                }
                presentedController = nil
            }
            guard isPresented.wrappedValue, let source = presentationSource(from: anchor),
                  let controller = makeController?() else { return }

            controller.onResult = { [weak self, weak controller, weak anchor] result in
                guard let self, let controller, let anchor else { return }
                if self.isPresented.wrappedValue { self.dismiss(controller, from: anchor, result: result) }
            }
            presentedController = controller
            source.present(controller, animated: true)
            if controller.presentingViewController == nil { presentedController = nil }
        }

        private func presentationSource(from anchor: PickerPresentationAnchor) -> UIViewController? {
            var parent = anchor.parent
            while let controller = parent {
                if controller.viewIfLoaded?.window != nil, controller.presentedViewController == nil,
                   !controller.isBeingDismissed { return controller }
                parent = controller.parent
            }
            return nil
        }

        private func dismiss(_ controller: JWDatePickerViewController, from anchor: PickerPresentationAnchor,
                             result: JWDatePickerResult? = nil) {
            guard presentedController === controller, !isDismissing else { return }
            isDismissing = true
            if controller.isBeingPresented,
               controller.transitionCoordinator?.animate(alongsideTransition: nil, completion: { [weak self, weak anchor] _ in
                   guard let self, let anchor else { return }
                   self.isDismissing = false
                   self.dismiss(controller, from: anchor, result: result)
               }) == true { return }

            let done = { [weak self, weak anchor] in
                guard let self, self.presentedController === controller else { return }
                self.isDismissing = false
                self.presentedController = nil
                if let result, self.isPresented.wrappedValue {
                    self.isPresented.wrappedValue = false
                    self.deliver?(result, controller)
                }
                if let anchor { self.update(from: anchor) }
            }
            if controller.isBeingDismissed {
                if controller.transitionCoordinator?.animate(alongsideTransition: nil, completion: { _ in done() }) == true { return }
                done()
            } else if controller.presentingViewController != nil {
                controller.dismiss(animated: true, completion: done)
            } else {
                done()
            }
        }

        func remove() {
            guard let controller = presentedController else { return }
            presentedController = nil
            controller.onResult = nil
            if controller.presentingViewController != nil && !controller.isBeingDismissed {
                controller.dismiss(animated: false)
            }
        }
    }
}

private final class PickerPresentationAnchor: UIViewController {
    var onReady: (() -> Void)?

    override func loadView() {
        let anchorView = PickerPresentationAnchorView()
        anchorView.isUserInteractionEnabled = false
        anchorView.onAttach = { [weak self] in self?.onReady?() }
        view = anchorView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onReady?()
    }
}

private final class PickerPresentationAnchorView: UIView {
    var onAttach: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            Task { @MainActor [weak self] in self?.onAttach?() }
        }
    }
}
