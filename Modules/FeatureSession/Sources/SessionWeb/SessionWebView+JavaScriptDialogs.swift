//
//  SessionWebView+JavaScriptDialogs.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import WebKit

import CoreDesignSystem

extension SessionWebView {
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        presentJavaScriptDialog(
            Self.alertConfiguration(message: message, sourceURL: frame.request.url),
            onResponse: { _ in completionHandler() },
            onUnavailable: completionHandler
        )
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        presentJavaScriptDialog(
            Self.confirmConfiguration(message: message, sourceURL: frame.request.url),
            onResponse: { response in
                completionHandler(Self.confirmResult(for: response))
            },
            onUnavailable: { completionHandler(false) }
        )
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        presentJavaScriptDialog(
            Self.promptConfiguration(
                message: prompt,
                defaultText: defaultText,
                sourceURL: frame.request.url
            ),
            onResponse: { response in
                completionHandler(Self.promptResult(for: response))
            },
            onUnavailable: { completionHandler(nil) }
        )
    }

    static func alertConfiguration(
        message: String,
        sourceURL: URL?
    ) -> ClipyDialog.Configuration {
        .message(
            presentation: websitePresentation(sourceURL: sourceURL),
            title: message,
            body: "",
            buttons: .single(title: "Confirm")
        )
    }

    static func confirmConfiguration(
        message: String,
        sourceURL: URL?
    ) -> ClipyDialog.Configuration {
        .message(
            presentation: websitePresentation(sourceURL: sourceURL),
            title: message,
            body: "",
            buttons: .dual(primaryTitle: "Confirm", secondaryTitle: "Cancel")
        )
    }

    static func promptConfiguration(
        message: String,
        defaultText: String?,
        sourceURL: URL?
    ) -> ClipyDialog.Configuration {
        .prompt(
            presentation: websitePresentation(sourceURL: sourceURL),
            title: message,
            body: "",
            initialText: defaultText ?? "",
            placeholder: nil,
            primaryTitle: "Confirm",
            secondaryTitle: "Cancel"
        )
    }

    static func confirmResult(for response: ClipyDialog.Response) -> Bool {
        guard case let .selected(button, _) = response else {
            return false
        }

        return button == .primary
    }

    static func promptResult(for response: ClipyDialog.Response) -> String? {
        guard case let .selected(.primary, promptText) = response else {
            return nil
        }

        return promptText ?? ""
    }

    private static func websitePresentation(sourceURL: URL?) -> ClipyDialog.Presentation {
        let sourceText: String
        if let host = sourceURL?.host, !host.isEmpty {
            sourceText = "Request from \(host)"
        } else {
            sourceText = "Request from this website"
        }

        return .websiteRequest(sourceText: sourceText)
    }
}
