//
//  SessionViewControllerSessionEndTests.swift
//  Clipy
//
//  Created by 박민서 on 8/26/26.
//

import UIKit
import XCTest

import FeatureSession

@MainActor
final class SessionViewControllerSessionEndTests: XCTestCase {
    private var windows: [UIWindow] = []
    private var fixtureURLs: [URL] = []

    override func tearDown() {
        windows.forEach {
            $0.rootViewController = nil
            $0.isHidden = true
        }
        fixtureURLs.forEach { try? FileManager.default.removeItem(at: $0) }
        windows = []
        fixtureURLs = []
        super.tearDown()
    }

    func test_temporaryNavigationCover_doesNotCancelAcceptedDialog() throws {
        let overlay = SessionOverlayRequesterSpy()
        let presented = expectation(description: "Session Dialog presented")
        overlay.onDialogPresented = { presented.fulfill() }
        let hosted = try makeHostedSession(overlay: overlay)
        wait(for: [presented], timeout: 10)

        hosted.navigationController.pushViewController(UIViewController(), animated: false)

        XCTAssertTrue(overlay.cancelledRequestIDs.isEmpty)
    }

    func test_navigationRemovalThenDeinit_cancelsAcceptedDialogOnce() async throws {
        let overlay = SessionOverlayRequesterSpy()
        let presented = expectation(description: "Session Dialog presented")
        overlay.onDialogPresented = { presented.fulfill() }
        var hosted: HostedSession? = try makeHostedSession(overlay: overlay)
        await fulfillment(of: [presented], timeout: 10)
        let requestID = try XCTUnwrap(overlay.latestRequestID)
        weak let weakSessionViewController = hosted?.sessionViewController

        hosted?.navigationController.popViewController(animated: false)
        let didCancelAfterRemoval = await waitUntil {
            overlay.cancelledRequestIDs == [requestID]
        }
        XCTAssertTrue(didCancelAfterRemoval)
        XCTAssertEqual(overlay.cancelledRequestIDs, [requestID])

        hosted = nil

        let didRelease = await waitUntil {
            weakSessionViewController == nil
        }
        XCTAssertTrue(didRelease)
        XCTAssertNil(weakSessionViewController)
        XCTAssertEqual(overlay.cancelledRequestIDs, [requestID])
    }

    private func makeHostedSession(
        overlay: SessionOverlayRequesterSpy
    ) throws -> HostedSession {
        let fixtureURL = try makeImmediateAlertFixture()
        fixtureURLs.append(fixtureURL)
        let sessionViewController = SessionFeature.makeViewController(
            context: SessionLaunchContext(sessionId: UUID(), initialURL: fixtureURL),
            overlayRequester: overlay
        )
        let homeViewController = UIViewController()
        let navigationController = UINavigationController(
            rootViewController: homeViewController
        )
        navigationController.pushViewController(sessionViewController, animated: false)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sessionViewController.loadViewIfNeeded()
        windows.append(window)

        return HostedSession(
            sessionViewController: sessionViewController,
            navigationController: navigationController
        )
    }
}

@MainActor
private struct HostedSession {
    let sessionViewController: UIViewController
    let navigationController: UINavigationController
}
