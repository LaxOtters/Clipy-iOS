//
//  SessionWebView.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import UIKit
import WebKit

import RxCocoa
import RxRelay
import RxSwift

/// Session 안의 WebKit detail을 감싸고, 밖으로는 FeatureSession에서 쓰는 event만 엽니다.
final class SessionWebView: UIView {
    private let webView: WKWebView
    fileprivate let stateRelay = BehaviorRelay(value: SessionBrowserState.empty)
    fileprivate let navigationFailureRelay = PublishRelay<SessionWebNavigationFailure>()
    fileprivate let rootScrollRelay = PublishRelay<SessionWebRootScrollInput>()
    fileprivate let navigationFinishedRelay = PublishRelay<Void>()
    private var observations: [NSKeyValueObservation] = []
    private let rootScrollAdapter = SessionWebRootScrollAdapter()

    override init(frame: CGRect) {
        webView = WKWebView(frame: .zero)
        super.init(frame: frame)
        configureView()
        observeBrowserState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func configureView() {
        backgroundColor = .systemBackground

        webView.navigationDelegate = self
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

    private func observeBrowserState() {
        observations = [
            webView.observe(\.url, options: [.new]) { [weak self] _, _ in
                self?.emitState()
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in
                self?.emitState()
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
                self?.emitState()
            }
        ]
    }

    func emitState() {
        stateRelay.accept(
            SessionBrowserState(
                currentURL: webView.url,
                isLoading: webView.isLoading,
                canGoBack: webView.canGoBack
            )
        )
    }

    func emitNavigationFailure(_ failure: SessionWebNavigationFailure) {
        navigationFailureRelay.accept(failure)
    }

    func emitNavigationFinished() {
        navigationFinishedRelay.accept(())
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
    var currentURL: URL? {
        webView.url
    }

    var canGoBack: Bool {
        webView.canGoBack
    }

    func load(url: URL) {
        webView.load(URLRequest(url: url))
    }

    func goBack() {
        guard webView.canGoBack else {
            return
        }

        webView.goBack()
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionWebView {
    var state: Driver<SessionBrowserState> {
        base.stateRelay.asDriver()
    }

    var navigationFailure: Signal<SessionWebNavigationFailure> {
        base.navigationFailureRelay.asSignal()
    }

    /// WebView의 root scroll을 chrome 판단용 drag 흐름으로 제공합니다.
    var rootScroll: Signal<SessionWebRootScrollInput> {
        base.rootScrollRelay.asSignal()
    }

    /// navigation finish를 Session chrome 흐름에서 쓸 수 있게 엽니다.
    var navigationFinished: Signal<Void> {
        base.navigationFinishedRelay.asSignal()
    }
}
