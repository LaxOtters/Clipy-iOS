//
//  SessionAddItemFormTests.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import XCTest

import CoreDomain

@testable import FeatureSession

final class SessionAddItemFormTests: XCTestCase {
    func test_openingOnCurrentPage_prefillsURL_withWebViewAddress() {
        let pageURL = URL(string: "https://shop.example.com/products/42?color=black")!

        let form = SessionAddItemForm.initialValues(currentPageURL: pageURL)

        XCTAssertEqual(form.urlText, "https://shop.example.com/products/42?color=black")
    }

    func test_openingWithoutCurrentPage_startsURLEmpty_forManualEntry() {
        let form = SessionAddItemForm.initialValues(currentPageURL: nil)

        XCTAssertEqual(form.urlText, "")
    }

    func test_openingCard_startsWithKRWAndInterested_asPolicyDefaults() {
        let form = SessionAddItemForm.initialValues(currentPageURL: nil)

        XCTAssertEqual(form.currency, .krw)
        XCTAssertEqual(form.status, .interested)
        XCTAssertEqual(form.productName, "")
        XCTAssertEqual(form.priceText, "")
        XCTAssertEqual(form.note, "")
    }

    func test_choosingOptions_listsCurrenciesAndStatuses_inPolicyOrder() {
        XCTAssertEqual(
            SessionItemFormValues.currencyOptions.map(\.rawValue),
            ["KRW", "USD", "JPY", "CNY", "EUR"]
        )
        XCTAssertEqual(
            SessionItemFormValues.statusOptions.map(\.rawValue),
            ["Interested", "Hold", "Dropped"]
        )
    }
}
