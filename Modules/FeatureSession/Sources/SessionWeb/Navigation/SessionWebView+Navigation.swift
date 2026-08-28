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
        clearRecoveryPresentation()
        emitNavigationFinished()
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        let failure = SessionWebNavigationFailure.committed(
            SessionWebNavigationFailureContext(error: error)
        )
        emitNavigationFailure(failure)
        guard !isWebKitPolicyInterruption(error) else { return }
        handleNavigationFailure(failure)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let failure = SessionWebNavigationFailure.provisional(
            SessionWebNavigationFailureContext(error: error)
        )
        emitNavigationFailure(failure)
        guard !isWebKitPolicyInterruption(error) else { return }
        handleNavigationFailure(failure)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        handleWebContentProcessTermination()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let frame: SessionWebNavigationPolicy.Frame
        if navigationAction.targetFrame == nil {
            frame = .newWindow
        } else if navigationAction.targetFrame?.isMainFrame == true {
            frame = .main
        } else {
            frame = .subframe
        }

        switch SessionWebNavigationPolicy.action(
            url: navigationAction.request.url,
            frame: frame,
            shouldPerformDownload: navigationAction.shouldPerformDownload
        ) {
        case .allow:
            decisionHandler(.allow)
        case .cancel:
            decisionHandler(.cancel)
        case let .confirmExternalOpen(url):
            decisionHandler(.cancel)
            presentExternalOpenConfirmation(url: url)
        case let .confirmBrowserFallback(url):
            decisionHandler(.cancel)
            presentBrowserFallbackConfirmation(url: url)
        case .showUnsupportedDownloadMessage:
            decisionHandler(.cancel)
            showUnsupportedDownloadMessage()
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        let contentDisposition = (navigationResponse.response as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Content-Disposition")

        switch SessionWebNavigationPolicy.response(
            isForMainFrame: navigationResponse.isForMainFrame,
            canShowMIMEType: navigationResponse.canShowMIMEType,
            contentDisposition: contentDisposition
        ) {
        case .allow:
            decisionHandler(.allow)
        case .cancel:
            decisionHandler(.cancel)
        case .showUnsupportedDownloadMessage:
            decisionHandler(.cancel)
            showUnsupportedDownloadMessage()
        }
    }
}

// WebKit의 policy 취소 실패값은 공개 contract가 아니므로 delegate 경계 밖으로 분류를 넘기지 않습니다.
private func isWebKitPolicyInterruption(_ error: Error) -> Bool {
    let error = error as NSError
    return error.domain == "WebKitErrorDomain" && error.code == 102
}
