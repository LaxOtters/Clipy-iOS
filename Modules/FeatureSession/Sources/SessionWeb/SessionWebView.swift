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

final class SessionWebView: UIView {
    var state: Driver<SessionBrowserState> {
        stateRelay.asDriver()
    }


    var currentURL: URL? {
        webView.url
    }

    var canGoBack: Bool {
        webView.canGoBack
    }

    private let webView: WKWebView
    private let stateRelay = BehaviorRelay(value: SessionBrowserState.empty)
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

    func load(url: URL) {
        webView.load(URLRequest(url: url))
    }

    func goBack() {
        guard webView.canGoBack else {
            return
        }

        webView.goBack()
    }

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

extension SessionWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        emitState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        emitState()
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        emitState()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        emitState()
    }
}
