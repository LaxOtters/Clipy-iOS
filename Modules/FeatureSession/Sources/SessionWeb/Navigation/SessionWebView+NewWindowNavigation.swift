//
//  SessionWebView+NewWindowNavigation.swift
//  Clipy
//
//  Created by 박민서 on 8/25/26.
//

import WebKit

extension SessionWebView: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith _: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures _: WKWindowFeatures
    ) -> WKWebView? {
        if Self.shouldLoadNewWindowRequestInMain(
            navigationAction.request.url,
            shouldPerformDownload: navigationAction.shouldPerformDownload
        ) {
            webView.load(navigationAction.request)
        }

        return nil
    }

    static func shouldLoadNewWindowRequestInMain(
        _ url: URL?,
        shouldPerformDownload: Bool = false
    ) -> Bool {
        SessionWebNavigationPolicy.shouldLoadNewWindowRequestInMain(
            url,
            shouldPerformDownload: shouldPerformDownload
        )
    }
}
