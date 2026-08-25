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

/// 세션 화면에서 사용하는 WKWebView를 감싸고 브라우저 입력과 화면 표시값을 연결합니다.
final class SessionWebView: UIView {
    private let webView: WKWebView
    fileprivate let browserStateRelay = ReplayRelay<SessionBrowserState>.create(bufferSize: 1)
    fileprivate let navigationFailureRelay = PublishRelay<SessionWebNavigationFailure>()
    fileprivate let rootScrollRelay = PublishRelay<SessionWebRootScrollInput>()
    fileprivate let navigationFinishedRelay = PublishRelay<Void>()
    private var observations: [NSKeyValueObservation] = []
    private let rootScrollAdapter = SessionWebRootScrollAdapter()
    private var browserStateProjector = SessionBrowserStateProjector()

    override init(frame: CGRect) {
        webView = WKWebView(frame: .zero)
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
        guard webView.url != nil else {
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
