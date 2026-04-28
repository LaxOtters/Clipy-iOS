//
//  AppMainBaselineTests.swift
//  Clipy
//
//  Created by 박민서 on 4/28/26.
//

import XCTest
@testable import AppMain

final class AppMainBaselineTests: XCTestCase {
    func test_baselineTitle_matchesProductName() {
        XCTAssertEqual(AppMainBaseline.title, "Clipy")
    }
}
