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

/// Session 안에서 웹 탐색을 담당하고 WebKit detail을 wrapper 뒤에 숨깁니다.
final class SessionWebView: UIView {
    /// 실제 웹 탐색을 수행하는 WebKit view입니다.
    private let webView: WKWebView
    /// WebView의 현재 URL, loading, back 가능 상태를 보관하는 relay입니다.
    fileprivate let stateRelay = BehaviorRelay(value: SessionBrowserState.empty)
    /// WebKit navigation 실패를 feature-owned event로 내보내는 relay입니다.
    fileprivate let navigationFailureRelay = PublishRelay<SessionWebNavigationFailure>()
    /// WebKit KVO lifecycle을 SessionWebView 생명주기에 묶어두는 token 목록입니다.
    private var observations: [NSKeyValueObservation] = []

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

    /// WKWebView를 wrapper 전체에 채우고 navigation delegate를 연결합니다.
    private func configureView() {
        backgroundColor = .systemBackground

        webView.navigationDelegate = self
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

    /// WebKit KVO 값을 감지해 browser state output으로 갱신합니다.
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

    /// 현재 WebView 값을 읽어 `SessionBrowserState`로 방출합니다.
    private func emitState() {
        stateRelay.accept(
            SessionBrowserState(
                currentURL: webView.url,
                isLoading: webView.isLoading,
                canGoBack: webView.canGoBack
            )
        )
    }
}

// MARK: - Interface

extension SessionWebView {
    /// WebView가 현재 표시 중인 URL입니다.
    var currentURL: URL? {
        webView.url
    }

    /// WebView history에서 뒤로 이동할 수 있는지 나타냅니다.
    var canGoBack: Bool {
        webView.canGoBack
    }

    /// 주어진 URL을 WebView에 load합니다.
    func load(url: URL) {
        webView.load(URLRequest(url: url))
    }

    /// WebView history가 있으면 이전 페이지로 이동합니다.
    func goBack() {
        guard webView.canGoBack else {
            return
        }

        webView.goBack()
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionWebView {
    /// WebView의 URL, loading, back 가능 상태를 UI binding용 state로 제공합니다.
    var state: Driver<SessionBrowserState> {
        base.stateRelay.asDriver()
    }

    /// WebKit navigation 실패를 ViewModel이나 ViewController가 처리할 수 있는 event로 제공합니다.
    var navigationFailure: Signal<SessionWebNavigationFailure> {
        base.navigationFailureRelay.asSignal()
    }
}

extension SessionWebView: WKNavigationDelegate {
    /// WebKit provisional navigation 시작 시 최신 browser state를 방출합니다.
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        emitState()
    }

    /// WebKit navigation 완료 시 최신 browser state를 방출합니다.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        emitState()
    }

    /// Commit 이후 navigation 실패를 feature-owned failure event로 변환합니다.
    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        emitState()
        navigationFailureRelay.accept(
            .committed(SessionWebNavigationFailureContext(error: error))
        )
    }

    /// Provisional navigation 실패를 feature-owned failure event로 변환합니다.
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        emitState()
        navigationFailureRelay.accept(
            .provisional(SessionWebNavigationFailureContext(error: error))
        )
    }
}
