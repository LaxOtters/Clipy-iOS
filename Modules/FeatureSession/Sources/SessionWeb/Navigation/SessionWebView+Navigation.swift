//
//  SessionWebView+Navigation.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import WebKit

extension SessionWebView: WKNavigationDelegate {
    // 페이지 이동 완료를 기존 Session chrome 복원 입력으로 전달합니다.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        emitNavigationFinished()
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        emitNavigationFailure(
            .committed(SessionWebNavigationFailureContext(error: error))
        )
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        emitNavigationFailure(
            .provisional(SessionWebNavigationFailureContext(error: error))
        )
    }
}
