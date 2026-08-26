//
//  SessionWebDialogConfigurationTests.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import XCTest

import CoreDesignSystem
@testable import FeatureSession

final class SessionWebDialogConfigurationTests: XCTestCase {
    func test_alert_preservesWebsiteMessage_andUsesInitiatingHost() {
        XCTAssertEqual(
            SessionWebView.alertConfiguration(
                message: "Allow access?",
                sourceURL: URL(string: "https://shop.example/path")
            ),
            .message(
                presentation: .websiteRequest(sourceText: "Request from shop.example"),
                title: "Allow access?",
                body: "",
                buttons: .single(title: "Confirm")
            )
        )
    }

    func test_confirm_withoutSourceURL_usesGenericWebsiteSource() {
        XCTAssertEqual(
            SessionWebView.confirmConfiguration(message: "Continue?", sourceURL: nil),
            .message(
                presentation: .websiteRequest(sourceText: "Request from this website"),
                title: "Continue?",
                body: "",
                buttons: .dual(primaryTitle: "Confirm", secondaryTitle: "Cancel")
            )
        )
    }

    func test_confirm_withEmptyHost_usesGenericWebsiteSource() {
        var components = URLComponents()
        components.scheme = "file"
        components.host = ""
        components.path = "/fixture.html"

        XCTAssertEqual(
            SessionWebView.confirmConfiguration(message: "Continue?", sourceURL: components.url),
            .message(
                presentation: .websiteRequest(sourceText: "Request from this website"),
                title: "Continue?",
                body: "",
                buttons: .dual(primaryTitle: "Confirm", secondaryTitle: "Cancel")
            )
        )
    }

    func test_prompt_withNilDefault_usesEmptyInitialText_withoutPlaceholder() {
        XCTAssertEqual(
            SessionWebView.promptConfiguration(message: "Name", defaultText: nil, sourceURL: nil),
            .prompt(
                presentation: .websiteRequest(sourceText: "Request from this website"),
                title: "Name",
                body: "",
                initialText: "",
                placeholder: nil,
                primaryTitle: "Confirm",
                secondaryTitle: "Cancel"
            )
        )
    }

    func test_prompt_withNonEmptyDefault_preservesInitialText() {
        let configuration = SessionWebView.promptConfiguration(
            message: "Name",
            defaultText: "Minseo",
            sourceURL: nil
        )

        XCTAssertEqual(
            configuration,
            .prompt(
                presentation: .websiteRequest(sourceText: "Request from this website"),
                title: "Name",
                body: "",
                initialText: "Minseo",
                placeholder: nil,
                primaryTitle: "Confirm",
                secondaryTitle: "Cancel"
            )
        )
    }

    func test_confirmPrimarySelection_returnsTrue() {
        XCTAssertTrue(
            SessionWebView.confirmResult(
                for: .selected(button: .primary, promptText: nil)
            )
        )
    }

    func test_confirmSecondarySelection_returnsFalse() {
        XCTAssertFalse(
            SessionWebView.confirmResult(
                for: .selected(button: .secondary, promptText: nil)
            )
        )
    }

    func test_confirmCancellation_returnsFalse() {
        XCTAssertFalse(
            SessionWebView.confirmResult(for: .cancelled(.requestCancelled))
        )
    }

    func test_promptPrimarySelection_preservesEditedText() {
        XCTAssertEqual(
            SessionWebView.promptResult(
                for: .selected(button: .primary, promptText: "Edited")
            ),
            "Edited"
        )
    }

    func test_promptPrimarySelection_preservesUntouchedDefaultText() {
        XCTAssertEqual(
            SessionWebView.promptResult(
                for: .selected(button: .primary, promptText: "Minseo")
            ),
            "Minseo"
        )
    }

    func test_promptPrimarySelectionWithNilText_returnsEmptyText() {
        XCTAssertEqual(
            SessionWebView.promptResult(
                for: .selected(button: .primary, promptText: nil)
            ),
            ""
        )
    }

    func test_promptSecondarySelection_returnsNil() {
        XCTAssertNil(
            SessionWebView.promptResult(
                for: .selected(button: .secondary, promptText: "Ignored")
            )
        )
    }

    func test_promptCancellation_returnsNil() {
        XCTAssertNil(
            SessionWebView.promptResult(for: .cancelled(.requestCancelled))
        )
    }
}
