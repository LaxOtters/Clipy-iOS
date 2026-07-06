//
//  SessionWebView+Navigation.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import WebKit

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
        emitNavigationFailure(
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
        emitNavigationFailure(
            .provisional(SessionWebNavigationFailureContext(error: error))
        )
    }
}
