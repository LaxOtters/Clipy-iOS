//
//  AppOverlayContainerViewController.swift
//  Clipy
//
//  Created by 박민서 on 8/22/26.
//

import UIKit

import CoreDesignSystem

/// 기존 화면 위에 Dialog와 Snackbar를 올리는 root container입니다.
/// Status bar와 system gesture 설정은 감싼 화면이 계속 정합니다.
@MainActor
final class AppOverlayContainerViewController: UIViewController {
    private let contentViewController: UIViewController
    private let dialogLayer = UIView()
    private let snackbarLayer = PassthroughView()
    private weak var mountedDialog: UIView?
    private weak var mountedSnackbar: UIView?
    private var snackbarTopConstraint: NSLayoutConstraint?
    private var snackbarExclusionBottom: CGFloat?
    private var snackbarOutsideTapHandler: (() -> Void)?
    private var hostDetachHandler: (() -> Void)?

    init(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configurePassiveTapObservation()
    }

    override func loadView() {
        let rootView = AppOverlayRootView()
        rootView.onWindowDetach = { [weak self] in
            self?.hostDetachHandler?()
        }
        view = rootView
    }

    override var childForStatusBarStyle: UIViewController? {
        contentViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        contentViewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        contentViewController.supportedInterfaceOrientations
    }

    override var childForHomeIndicatorAutoHidden: UIViewController? {
        contentViewController
    }

    override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        contentViewController
    }

    func updateSnackbarExclusionBottom(_ bottom: CGFloat?) {
        snackbarExclusionBottom = bottom
        updateSnackbarTopConstraint()
    }
}

extension AppOverlayContainerViewController: AppOverlayHosting {
    var isOverlayHostAvailable: Bool {
        isViewLoaded && view.window != nil
    }

    func mountDialog(
        configuration: ClipyDialog.Configuration,
        onSelection: @escaping (ClipyDialog.Selection, String?) -> Void,
        completion: @escaping (AppOverlayMountResult) -> Void
    ) -> AppOverlayMountAdmission {
        guard isOverlayHostAvailable else {
            return .unavailable
        }
        guard mountedDialog == nil else {
            return .occupied
        }

        let dialogView = ClipyDialogView(configuration: configuration, onSelection: onSelection)
        mountedDialog = dialogView
        dialogLayer.isHidden = false
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        dialogLayer.addSubview(dialogView)
        let preferredWidth = dialogView.widthAnchor.constraint(
            equalTo: dialogLayer.widthAnchor,
            constant: -40
        )
        preferredWidth.priority = .defaultHigh
        let preferredVerticalCenter = dialogView.centerYAnchor.constraint(equalTo: dialogLayer.centerYAnchor)
        preferredVerticalCenter.priority = .defaultLow
        NSLayoutConstraint.activate([
            dialogView.centerXAnchor.constraint(equalTo: dialogLayer.centerXAnchor),
            preferredVerticalCenter,
            dialogView.topAnchor.constraint(
                greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 20
            ),
            dialogView.bottomAnchor.constraint(
                lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor,
                constant: -20
            ),
            dialogView.leadingAnchor.constraint(greaterThanOrEqualTo: dialogLayer.leadingAnchor, constant: 20),
            dialogView.trailingAnchor.constraint(lessThanOrEqualTo: dialogLayer.trailingAnchor, constant: -20),
            dialogView.widthAnchor.constraint(lessThanOrEqualToConstant: 384),
            preferredWidth
        ])

        dialogView.alpha = 0
        dialogView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
        ) {
            dialogView.alpha = 1
            dialogView.transform = .identity
        } completion: { _ in
            let didDisplay = dialogView.superview === self.dialogLayer && self.mountedDialog === dialogView
            completion(didDisplay ? .displayed : .unavailable)
        }
        return .accepted
    }

    func unmountDialog(animated: Bool, completion: @escaping () -> Void) {
        guard let dialogView = mountedDialog, dialogView.superview === dialogLayer else {
            completion()
            return
        }

        guard animated, isOverlayHostAvailable else {
            dialogView.removeFromSuperview()
            mountedDialog = nil
            dialogLayer.isHidden = true
            completion()
            return
        }

        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseIn]
        ) {
            dialogView.alpha = 0
        } completion: { [weak self] _ in
            dialogView.removeFromSuperview()
            if self?.mountedDialog === dialogView {
                self?.mountedDialog = nil
                self?.dialogLayer.isHidden = true
            }
            completion()
        }
    }

    func mountSnackbar(
        message: String,
        actionTitle: String?,
        onAction: (() -> Void)?,
        onDismiss: @escaping () -> Void,
        completion: @escaping (AppOverlayMountResult) -> Void
    ) -> AppOverlayMountAdmission {
        guard isOverlayHostAvailable else {
            return .unavailable
        }
        guard mountedSnackbar == nil else {
            return .occupied
        }

        let action = actionTitle.map { title in
            ClipySnackbar.Action(title: title) { onAction?() }
        }
        let snackbarView = ClipySnackbarView(message: message, action: action, onDismiss: onDismiss)
        mountedSnackbar = snackbarView
        snackbarOutsideTapHandler = onDismiss
        snackbarView.translatesAutoresizingMaskIntoConstraints = false
        snackbarLayer.addSubview(snackbarView)
        let topConstraint = snackbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
        snackbarTopConstraint = topConstraint
        let preferredWidth = snackbarView.widthAnchor.constraint(
            equalTo: snackbarLayer.widthAnchor,
            constant: -40
        )
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            topConstraint,
            snackbarView.bottomAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -10
            ),
            snackbarView.centerXAnchor.constraint(equalTo: snackbarLayer.centerXAnchor),
            snackbarView.leadingAnchor.constraint(greaterThanOrEqualTo: snackbarLayer.leadingAnchor, constant: 20),
            snackbarView.trailingAnchor.constraint(lessThanOrEqualTo: snackbarLayer.trailingAnchor, constant: -20),
            snackbarView.widthAnchor.constraint(lessThanOrEqualToConstant: 349),
            preferredWidth
        ])
        updateSnackbarTopConstraint()
        view.layoutIfNeeded()

        snackbarView.transform = CGAffineTransform(translationX: 0, y: -snackbarView.bounds.height - 20)
        snackbarView.alpha = 0
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseOut]
        ) {
            snackbarView.transform = .identity
            snackbarView.alpha = 1
        } completion: { _ in
            let didDisplay = snackbarView.superview === self.snackbarLayer && self.mountedSnackbar === snackbarView
            completion(didDisplay ? .displayed : .unavailable)
        }
        return .accepted
    }

    func unmountSnackbar(animated: Bool, completion: @escaping () -> Void) {
        guard let snackbarView = mountedSnackbar, snackbarView.superview === snackbarLayer else {
            completion()
            return
        }

        guard animated, isOverlayHostAvailable else {
            snackbarView.removeFromSuperview()
            mountedSnackbar = nil
            snackbarTopConstraint = nil
            snackbarOutsideTapHandler = nil
            completion()
            return
        }

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseIn]
        ) {
            snackbarView.transform = CGAffineTransform(translationX: 0, y: -snackbarView.bounds.height - 20)
            snackbarView.alpha = 0
        } completion: { [weak self] _ in
            snackbarView.removeFromSuperview()
            if self?.mountedSnackbar === snackbarView {
                self?.mountedSnackbar = nil
                self?.snackbarTopConstraint = nil
                self?.snackbarOutsideTapHandler = nil
            }
            completion()
        }
    }

    func setHostDetachHandler(_ handler: (() -> Void)?) {
        hostDetachHandler = handler
    }
}

private extension AppOverlayContainerViewController {
    func configureHierarchy() {
        view.backgroundColor = .systemBackground

        contentViewController.loadViewIfNeeded()
        guard let contentView = contentViewController.view else {
            assertionFailure("The content view controller must provide a root view.")
            return
        }

        addChild(contentViewController)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        contentViewController.didMove(toParent: self)

        dialogLayer.backgroundColor = ClipyColor.Foundation.overlayBackground
        dialogLayer.isHidden = true
        dialogLayer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dialogLayer)

        snackbarLayer.backgroundColor = .clear
        snackbarLayer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(snackbarLayer)

        [contentView, dialogLayer, snackbarLayer].forEach { layerView in
            NSLayoutConstraint.activate([
                layerView.topAnchor.constraint(equalTo: view.topAnchor),
                layerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                layerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                layerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }

    func configurePassiveTapObservation() {
        // 바깥 탭으로 Snackbar만 닫되, 같은 탭은 아래 화면에서도 받을 수 있게 둡니다.
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didObserveTap(_:)))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delaysTouchesBegan = false
        gestureRecognizer.delaysTouchesEnded = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }

    @objc func didObserveTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .ended else {
            return
        }
        let location = gestureRecognizer.location(in: snackbarLayer)
        observeSnackbarOutsideTap(at: location)
    }

    func observeSnackbarOutsideTap(at location: CGPoint) {
        guard let mountedSnackbar, !mountedSnackbar.frame.contains(location) else {
            return
        }
        snackbarOutsideTapHandler?()
    }

    func updateSnackbarTopConstraint() {
        guard let snackbarTopConstraint else {
            return
        }
        let safeAreaTop = view.safeAreaInsets.top
        let exclusionOffset = snackbarExclusionBottom.map { max(10, $0 - safeAreaTop + 10) } ?? 10
        snackbarTopConstraint.constant = exclusionOffset
    }
}

extension AppOverlayContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

/// Snackbar view 밖의 터치는 아래 레이어로 넘깁니다.
private final class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let target = super.hitTest(point, with: event)
        return target === self ? nil : target
    }
}

private final class AppOverlayRootView: UIView {
    var onWindowDetach: (() -> Void)?
    private var wasAttachedToWindow = false

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // root view가 한 번 window에 붙은 뒤 떨어질 때만 detach로 봅니다.
        if window != nil {
            wasAttachedToWindow = true
        } else if wasAttachedToWindow {
            wasAttachedToWindow = false
            onWindowDetach?()
        }
    }
}
