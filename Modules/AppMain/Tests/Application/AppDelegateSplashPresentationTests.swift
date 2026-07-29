//
//  AppDelegateSplashPresentationTests.swift
//  Clipy
//
//  Created by 박민서 on 7/25/26.
//

import XCTest

@testable import AppMain

final class AppDelegateSplashPresentationTests: XCTestCase {
    func test_claimingSplashPresentationTwice_allowsFirstClaimOnly_forSameProcess() {
        let appDelegate = AppDelegate()

        XCTAssertTrue(appDelegate.claimSplashPresentation())
        XCTAssertFalse(appDelegate.claimSplashPresentation())
    }
}
