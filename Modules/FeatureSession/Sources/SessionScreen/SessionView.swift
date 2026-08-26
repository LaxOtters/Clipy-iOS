//
//  SessionView.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation
import UIKit

import CoreDesignSystem
import RxCocoa
import RxSwift

/// Session 화면의 Top Bar, WebView, Bottom Sheet를 한 UIKit tree로 묶습니다.
/// 사용자의 입력을 밖으로 열고, 내려온 chrome state는 그대로 화면에 그립니다.
final class SessionView: UIView {
    fileprivate let topBarView = SessionTopBarView()
    fileprivate let browserView: SessionWebView
    fileprivate let bottomSheetView = SessionBottomSheetView()
    private var topBarFoldedConstraints: [NSLayoutConstraint] = []
    private var topBarUnfoldedConstraints: [NSLayoutConstraint] = []
    private var bottomSheetScreenBottomConstraint: NSLayoutConstraint!
    private var bottomSheetKeyboardTopConstraint: NSLayoutConstraint!
    private var renderedBottomSheetState = SessionChromeState.newSession.bottomSheetState
    private var isTrackingDockedKeyboard = false

    init(overlayRequester: any ClipyOverlayRequesting) {
        browserView = SessionWebView(overlayRequester: overlayRequester)
        super.init(frame: .zero)
        configureHierarchy()
        configureStyle()
        configureLayout()
        configureKeyboardObservation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureHierarchy() {
        addSubview(browserView)
        addSubview(topBarView)
        addSubview(bottomSheetView)
    }

    private func configureStyle() {
        backgroundColor = .systemBackground
    }

    private func configureLayout() {
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        browserView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false

        topBarFoldedConstraints = [
            topBarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            topBarView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
            topBarView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor)
        ]
        topBarUnfoldedConstraints = [
            topBarView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ]
        bottomSheetScreenBottomConstraint = bottomSheetView.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomSheetKeyboardTopConstraint = bottomSheetView.bottomAnchor.constraint(
            equalTo: keyboardLayoutGuide.topAnchor
        )

        NSLayoutConstraint.activate([
            browserView.topAnchor.constraint(equalTo: topAnchor),
            browserView.leadingAnchor.constraint(equalTo: leadingAnchor),
            browserView.trailingAnchor.constraint(equalTo: trailingAnchor),
            browserView.bottomAnchor.constraint(equalTo: bottomAnchor),

            topBarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),

            bottomSheetView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            bottomSheetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ] + topBarUnfoldedConstraints + [bottomSheetScreenBottomConstraint])
    }

    private func configureKeyboardObservation() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }

    @objc
    private func keyboardFrameWillChange(_ notification: Notification) {
        guard
            window != nil,
            let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else {
            return
        }

        let keyboardFrame = convert(frameValue.cgRectValue, from: nil)
        if isTrackingDockedKeyboard, keyboardFrame.minY >= bounds.maxY {
            // Dismiss 중에는 keyboard guide를 유지하고 didHide 이후 화면 하단으로 돌아갑니다.
            return
        }

        isTrackingDockedKeyboard = keyboardFrame.minY < bounds.maxY
            && keyboardFrame.maxY >= bounds.maxY - 1
        updateBottomSheetBottomConstraint()
    }

    @objc
    private func keyboardDidHide(_: Notification) {
        isTrackingDockedKeyboard = false
        updateBottomSheetBottomConstraint()
    }

    private func updateTopBarConstraints(for state: SessionTopBarState) {
        let isFolded = state == .folded
        NSLayoutConstraint.deactivate(isFolded ? topBarUnfoldedConstraints : topBarFoldedConstraints)
        NSLayoutConstraint.activate(isFolded ? topBarFoldedConstraints : topBarUnfoldedConstraints)
    }

    private func updateBottomSheetBottomConstraint() {
        let avoidsKeyboard = renderedBottomSheetState.avoidsDockedKeyboard
            && isTrackingDockedKeyboard

        bottomSheetScreenBottomConstraint.isActive = !avoidsKeyboard
        bottomSheetKeyboardTopConstraint.isActive = avoidsKeyboard
        layoutIfNeeded()
    }
}

// MARK: - Interface

extension SessionView {
    var onWebRecoveryGoHome: (() -> Void)? {
        get { browserView.onRecoveryGoHome }
        set { browserView.onRecoveryGoHome = newValue }
    }

    func endSession() {
        browserView.endSession()
    }

    func load(url: URL) {
        browserView.load(url: url)
    }

    func goBack() {
        browserView.goBack()
    }

    func goForward() {
        browserView.goForward()
    }

    func reload() {
        browserView.reload()
    }

    /// 하나의 chrome state를 Top Bar와 Bottom Sheet에 같이 그립니다.
    func render(chromeState: SessionChromeState, animated: Bool) {
        topBarView.render(state: chromeState.topBarState)
        updateTopBarConstraints(for: chromeState.topBarState)
        renderedBottomSheetState = chromeState.bottomSheetState
        updateBottomSheetBottomConstraint()
        bottomSheetView.render(state: chromeState.bottomSheetState, animated: animated)
    }

    func render(browserState: SessionBrowserState) {
        bottomSheetView.render(browserState: browserState)
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionView {
    var homeTap: ControlEvent<Void> {
        base.topBarView.rx.homeTap
    }

    var topBarToggleTap: ControlEvent<Void> {
        base.topBarView.rx.toggleTap
    }

    var webRootScroll: Signal<SessionWebRootScrollInput> {
        base.browserView.rx.rootScroll
    }

    var navigationFinished: Signal<Void> {
        base.browserView.rx.navigationFinished
    }

    var browserState: Driver<SessionBrowserState> {
        base.browserView.rx.browserState
    }

    var backTap: ControlEvent<Void> {
        base.bottomSheetView.rx.backTap
    }

    var forwardTap: ControlEvent<Void> {
        base.bottomSheetView.rx.forwardTap
    }

    var reloadTap: ControlEvent<Void> {
        base.bottomSheetView.rx.reloadTap
    }

    var bottomSheetDragEnded: Signal<SessionBottomSheetAction> {
        base.bottomSheetView.rx.dragEnded
    }
}
