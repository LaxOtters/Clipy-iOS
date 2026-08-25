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
        if Self.shouldLoadNewWindowRequestInMain(navigationAction.request.url) {
            webView.load(navigationAction.request)
        }

        return nil
    }

    static func shouldLoadNewWindowRequestInMain(_ url: URL?) -> Bool {
        guard let scheme = url?.scheme?.lowercased() else {
            return false
        }

        return scheme == "http" || scheme == "https"
    }
}
