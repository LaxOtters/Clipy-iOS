//
//  SessionWebView+Navigation.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import WebKit

extension SessionWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        emitState()
    }

    /// didFinish는 browser state 갱신과 chrome 복원 신호가 함께 필요한 지점입니다.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        emitState()
        emitNavigationFinished()
    }

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
