//
//  AppMainNavigationControllerTests.swift
//  Clipy
//
//  Created by 박민서 on 7/25/26.
//

import XCTest

@testable import AppMain

final class AppMainNavigationControllerTests: XCTestCase {
    func test_rootNavigation_hidesHomeIndicator_withoutDeferringToVisibleChild() {
        let navigationController = AppMainNavigationController(
            rootViewController: UIViewController()
        )

        XCTAssertTrue(navigationController.prefersHomeIndicatorAutoHidden)
        XCTAssertNil(navigationController.childForHomeIndicatorAutoHidden)
    }
}
