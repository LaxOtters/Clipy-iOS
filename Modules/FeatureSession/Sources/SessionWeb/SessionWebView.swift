//
//  SessionWebView.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import UIKit
import WebKit

import CoreDesignSystem
import RxCocoa
import RxRelay
import RxSwift

/// 세션 화면에서 사용하는 WKWebView를 감싸고 브라우저 입력과 화면 표시값을 연결합니다.
final class SessionWebView: UIView {
    private let webView: WKWebView
    private let overlayRequester: any ClipyOverlayRequesting
    private let openURL: @MainActor (URL) async -> Bool
    private var acceptedDialogRequestIDs: Set<ClipyDialog.RequestID> = []
    private var isSessionActive = true
    private var recoveryHostView: UIView?
    private var isRecoveryActionClaimed = false
    fileprivate let browserStateRelay = ReplayRelay<SessionBrowserState>.create(bufferSize: 1)
    fileprivate let navigationFailureRelay = PublishRelay<SessionWebNavigationFailure>()
    fileprivate let rootScrollRelay = PublishRelay<SessionWebRootScrollInput>()
    fileprivate let navigationFinishedRelay = PublishRelay<Void>()
    private var observations: [NSKeyValueObservation] = []
    private let rootScrollAdapter = SessionWebRootScrollAdapter()
    private var browserStateProjector = SessionBrowserStateProjector()
    var onRecoveryGoHome: (() -> Void)?

    init(
        frame: CGRect = .zero,
        dependencies: SessionFeature.Dependencies
    ) {
        webView = WKWebView(frame: .zero)
        overlayRequester = dependencies.overlayRequester
        openURL = dependencies.openURL
        super.init(frame: frame)
        configureView()
        observeBrowserStateChanges()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func configureView() {
        backgroundColor = .systemBackground

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func observeBrowserStateChanges() {
        observations = [
            webView.observe(\.url, options: [.new]) { [weak self] _, _ in
                self?.emitBrowserState()
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
                self?.emitBrowserState()
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
                self?.emitBrowserState()
            }
        ]
    }

    private var currentBrowserSnapshot: SessionBrowserSnapshot {
        SessionBrowserSnapshot(
            url: webView.url,
            canGoBack: webView.canGoBack,
            canGoForward: webView.canGoForward
        )
    }

    private func emitBrowserState(requestedURL: URL? = nil) {
        browserStateRelay.accept(
            browserStateProjector.project(
                snapshot: currentBrowserSnapshot,
                requestedURL: requestedURL
            )
        )
    }

    func emitNavigationFailure(_ failure: SessionWebNavigationFailure) {
        navigationFailureRelay.accept(failure)
    }

    func emitNavigationFinished() {
        navigationFinishedRelay.accept(())
    }

    func handleNavigationFailure(_ failure: SessionWebNavigationFailure) {
        present(
            SessionWebRecoveryPolicy.presentation(
                failure: failure,
                snapshot: recoverySnapshot
            )
        )
    }

    func handleWebContentProcessTermination() {
        guard isSessionActive else {
            return
        }

        cancelAcceptedDialogs()
        guard isSessionActive else {
            return
        }

        present(
            SessionWebRecoveryPolicy.processTerminationPresentation(snapshot: recoverySnapshot)
        )
    }

    private func cancelAcceptedDialogs() {
        let requestIDs = acceptedDialogRequestIDs
        acceptedDialogRequestIDs.removeAll()
        requestIDs.forEach(overlayRequester.cancelDialog)
    }

    func clearRecoveryPresentation() {
        recoveryHostView?.removeFromSuperview()
        recoveryHostView = nil
        isRecoveryActionClaimed = false
        webView.isUserInteractionEnabled = true
        webView.accessibilityElementsHidden = false
    }

    func beginRootDragging(snapshot: SessionWebRootScrollSnapshot) {
        emitRootScroll(rootScrollAdapter.beginDragging(snapshot: snapshot))
    }

    func emitRootDraggingIfNeeded(snapshot: SessionWebRootScrollSnapshot) {
        emitRootScroll(rootScrollAdapter.scrollInput(snapshot: snapshot))
    }

    func prepareRootDragEnd(
        releaseVelocityY: CGFloat,
        targetOffsetY: CGFloat,
        currentOffsetY: CGFloat
    ) {
        rootScrollAdapter.prepareDragEnd(
            releaseVelocityY: releaseVelocityY,
            targetOffsetY: targetOffsetY,
            currentOffsetY: currentOffsetY
        )
    }

    func endRootDragging(snapshot: SessionWebRootScrollSnapshot) {
        emitRootScroll(rootScrollAdapter.endDragging(snapshot: snapshot))
    }

    func emitRootScroll(_ input: SessionWebRootScrollInput) {
        rootScrollRelay.accept(input)
    }

    private func present(_ presentation: SessionWebRecoveryPolicy.Presentation) {
        switch presentation {
        case .none:
            return
        case let .snackbar(message):
            overlayRequester.enqueueSnackbar(.init(message: message))
        case let .error(content):
            showRecoveryContent(content)
        }
    }

    private var recoverySnapshot: SessionWebRecoveryPolicy.Snapshot {
        SessionWebRecoveryPolicy.Snapshot(
            isSessionActive: isSessionActive,
            hasMountedErrorContent: recoveryHostView != nil,
            currentURL: webView.url,
            currentItemURL: webView.backForwardList.currentItem?.url,
            canGoBack: webView.canGoBack
        )
    }

    private func showRecoveryContent(_ content: SessionWebRecoveryPolicy.ErrorContent) {
        recoveryHostView?.removeFromSuperview()

        let hostView = UIView()
        hostView.backgroundColor = .systemBackground
        hostView.isOpaque = true
        hostView.translatesAutoresizingMaskIntoConstraints = false

        let contentView = ClipyErrorContentView(
            title: content.title,
            body: content.body,
            action: .init(title: content.actionTitle) { [weak self] in
                self?.performRecoveryAction(content.action)
            }
        )
        contentView.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(contentView)
        addSubview(hostView)

        NSLayoutConstraint.activate([
            hostView.topAnchor.constraint(equalTo: topAnchor),
            hostView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.topAnchor.constraint(equalTo: hostView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])

        recoveryHostView = hostView
        isRecoveryActionClaimed = false
        webView.isUserInteractionEnabled = false
        webView.accessibilityElementsHidden = true
    }

    private func performRecoveryAction(_ action: SessionWebRecoveryPolicy.Action) {
        guard isSessionActive, !isRecoveryActionClaimed else {
            return
        }
        isRecoveryActionClaimed = true

        switch action {
        case .reload, .reopenPage:
            reload()
        case .goBack:
            goBack()
        case .goHome:
            endSession()
            onRecoveryGoHome?()
        }
    }

    func scrollSnapshot(from scrollView: UIScrollView) -> SessionWebRootScrollSnapshot {
        SessionWebRootScrollSnapshot(
            offsetY: scrollView.contentOffset.y,
            contentHeight: scrollView.contentSize.height,
            viewportHeight: scrollView.bounds.height,
            adjustedContentInsetTop: scrollView.adjustedContentInset.top,
            adjustedContentInsetBottom: scrollView.adjustedContentInset.bottom
        )
    }

}

// MARK: - Interface

extension SessionWebView {
    func endSession() {
        guard isSessionActive else {
            return
        }

        isSessionActive = false
        clearRecoveryPresentation()
        cancelAcceptedDialogs()
    }

    func presentDialog(
        _ configuration: ClipyDialog.Configuration,
        onResponse: @escaping @MainActor (ClipyDialog.Response) -> Void,
        onUnavailable: @escaping @MainActor () -> Void
    ) {
        guard isSessionActive else {
            onUnavailable()
            return
        }

        var acceptedRequestID: ClipyDialog.RequestID?
        var didReceiveResponse = false
        let result = overlayRequester.presentDialog(configuration) { [weak self] response in
            didReceiveResponse = true
            if let acceptedRequestID {
                self?.acceptedDialogRequestIDs.remove(acceptedRequestID)
            }
            onResponse(response)
        }

        switch result {
        case let .accepted(requestID):
            acceptedRequestID = requestID
            guard !didReceiveResponse else {
                return
            }
            guard isSessionActive else {
                overlayRequester.cancelDialog(requestID)
                return
            }
            acceptedDialogRequestIDs.insert(requestID)

        case .rejected:
            onUnavailable()
        }
    }

    func externalOpenAction(for url: URL) -> @MainActor () -> Void {
        // primary 선택 뒤에는 Session이 닫혀도 openURL 요청은 진행하고, 늦은 실패 안내만 버립니다.
        let openURL = openURL
        return { [weak self] in
            Task { [weak self, openURL] in
                let didOpen = await openURL(url)
                guard let self, !didOpen, isSessionActive else {
                    return
                }
                overlayRequester.enqueueSnackbar(.init(message: "Couldn't open external app"))
            }
        }
    }

    func showUnsupportedDownloadMessage() {
        guard isSessionActive else {
            return
        }
        overlayRequester.enqueueSnackbar(.init(message: "Downloads aren't supported"))
    }

    var currentURL: URL? {
        webView.url
    }

    func load(url: URL) {
        emitBrowserState(requestedURL: url)

        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url)
        } else {
            webView.load(URLRequest(url: url))
        }
    }

    func goBack() {
        guard webView.canGoBack else {
            return
        }

        webView.goBack()
    }

    func goForward() {
        guard webView.canGoForward else {
            return
        }

        webView.goForward()
    }

    func reload() {
        guard webView.url != nil || webView.backForwardList.currentItem != nil else {
            return
        }

        webView.reload()
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionWebView {
    var browserState: Driver<SessionBrowserState> {
        base.browserStateRelay
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
    }

    var navigationFailure: Signal<SessionWebNavigationFailure> {
        base.navigationFailureRelay.asSignal()
    }

    /// WebView의 root scroll을 chrome 판단용 drag 흐름으로 제공합니다.
    var rootScroll: Signal<SessionWebRootScrollInput> {
        base.rootScrollRelay.asSignal()
    }

    /// Navigation 완료 시점을 Session chrome 복원 흐름으로 내보냅니다.
    var navigationFinished: Signal<Void> {
        base.navigationFinishedRelay.asSignal()
    }
}
