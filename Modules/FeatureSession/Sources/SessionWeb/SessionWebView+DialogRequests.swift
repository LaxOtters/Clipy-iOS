//
//  SessionWebView+DialogRequests.swift
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
        presentDialog(
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
        presentDialog(
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
        presentDialog(
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

    static var externalOpenConfiguration: ClipyDialog.Configuration {
        .message(
            presentation: .plain,
            title: "Open external app?",
            body: "Clipy will open another app to continue.",
            buttons: .dual(primaryTitle: "Continue", secondaryTitle: "Cancel")
        )
    }

    static var browserFallbackConfiguration: ClipyDialog.Configuration {
        .message(
            presentation: .plain,
            title: "Open in browser?",
            body: "Downloads aren't supported in Clipy.",
            buttons: .dual(primaryTitle: "Open in browser", secondaryTitle: "Cancel")
        )
    }

    func presentExternalOpenConfirmation(url: URL) {
        presentURLConfirmation(configuration: Self.externalOpenConfiguration, url: url)
    }

    func presentBrowserFallbackConfirmation(url: URL) {
        presentURLConfirmation(configuration: Self.browserFallbackConfiguration, url: url)
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

    private func presentURLConfirmation(
        configuration: ClipyDialog.Configuration,
        url: URL
    ) {
        let openExternalURL = externalOpenAction(for: url)
        presentDialog(
            configuration,
            onResponse: { response in
                guard case .selected(.primary, _) = response else {
                    return
                }
                openExternalURL()
            },
            onUnavailable: {}
        )
    }
}
