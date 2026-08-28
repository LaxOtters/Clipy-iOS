//
//  SessionWebNavigationResponsePolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 8/27/26.
//

import XCTest

@testable import FeatureSession

final class SessionWebNavigationResponsePolicyTests: XCTestCase {
    func test_responsePolicy_allowsDisplayableInlineContent_andSilencesUnsupportedSubframes() {
        XCTAssertEqual(
            SessionWebNavigationPolicy.response(
                isForMainFrame: true,
                canShowMIMEType: true,
                contentDisposition: "inline; filename=attachment.pdf"
            ),
            .allow
        )
        XCTAssertEqual(
            SessionWebNavigationPolicy.response(
                isForMainFrame: false,
                canShowMIMEType: false,
                contentDisposition: nil
            ),
            .cancel
        )
    }

    func test_responsePolicy_rejectsMainFrameAttachment_orUnsupportedMIME_withoutBrowserFallback() {
        for contentDisposition in [
            "attachment",
            " Attachment ; filename=file.pdf",
            "ATTACHMENT; filename=file.pdf"
        ] {
            XCTAssertEqual(
                SessionWebNavigationPolicy.response(
                    isForMainFrame: true,
                    canShowMIMEType: true,
                    contentDisposition: contentDisposition
                ),
                .showUnsupportedDownloadMessage
            )
        }

        XCTAssertEqual(
            SessionWebNavigationPolicy.response(
                isForMainFrame: true,
                canShowMIMEType: false,
                contentDisposition: nil
            ),
            .showUnsupportedDownloadMessage
        )
    }

    func test_responsePolicy_silencesAttachmentInSubframe() {
        XCTAssertEqual(
            SessionWebNavigationPolicy.response(
                isForMainFrame: false,
                canShowMIMEType: true,
                contentDisposition: "attachment; filename=file.pdf"
            ),
            .cancel
        )
    }

    func test_responsePolicy_doesNotTreatContainsAttachmentValues_asAttachment() {
        for contentDisposition in [nil, "", "inline; filename=attachment.pdf", "x-attachment", "attachment-preview"] {
            XCTAssertEqual(
                SessionWebNavigationPolicy.response(
                    isForMainFrame: true,
                    canShowMIMEType: true,
                    contentDisposition: contentDisposition
                ),
                .allow
            )
        }
    }
}
