//
//  AppOverlayContainerViewControllerTests.swift
//  Clipy
//
//  Created by 박민서 on 8/22/26.
//

import UIKit
import XCTest

import CoreDesignSystem
@testable import AppMain

@MainActor
final class AppOverlayContainerViewControllerTests: XCTestCase {
    func test_container_forwardsChildOwnedSystemUIOutputs() {
        let child = SystemUIChildViewController()
        let container = AppOverlayContainerViewController(contentViewController: child)

        container.loadViewIfNeeded()

        XCTAssertTrue(container.childForStatusBarStyle === child)
        XCTAssertTrue(container.childForStatusBarHidden === child)
        XCTAssertEqual(container.supportedInterfaceOrientations, .landscapeLeft)
        XCTAssertTrue(container.childForHomeIndicatorAutoHidden === child)
        XCTAssertTrue(container.childForScreenEdgesDeferringSystemGestures === child)
    }

    func test_rootHostWindowDetach_forwardsToCoordinator_andCancelsAcceptedDialog() {
        let container = AppOverlayContainerViewController(contentViewController: UIViewController())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.loadViewIfNeeded()
        let coordinator = AppOverlayCoordinator(host: container, isSceneActive: true)
        container.setHostDetachHandler { [weak coordinator] in
            coordinator?.hostDidDetach()
        }
        var responses: [ClipyDialog.Response] = []

        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        assertDialogRequestAccepted(
            coordinator.presentDialog(overlayDialogConfiguration) { responses.append($0) }
        )

        window.rootViewController = nil

        XCTAssertEqual(responses, [.cancelled(.hostUnavailable)])
    }

    func test_mountingSecondDialog_keepsIncumbent_untilCoordinatorUnmounts() async {
        let (container, window) = makeVisibleContainer()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        var firstResult: AppOverlayMountResult?
        var secondResult: AppOverlayMountResult?
        let mounted = expectation(description: "Dialog entry completed")

        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        XCTAssertEqual(
            container.mountDialog(
                configuration: overlayDialogConfiguration,
                onSelection: { _, _ in },
                completion: {
                    firstResult = $0
                    mounted.fulfill()
                }
            ),
            .accepted
        )
        await fulfillment(of: [mounted], timeout: 1)
        let incumbent = container.view.firstDescendant(of: ClipyDialogView.self)

        XCTAssertEqual(
            container.mountDialog(
                configuration: overlayDialogConfiguration,
                onSelection: { _, _ in },
                completion: { secondResult = $0 }
            ),
            .occupied
        )

        XCTAssertEqual(firstResult, .displayed)
        XCTAssertNil(secondResult)
        XCTAssertTrue(container.view.firstDescendant(of: ClipyDialogView.self) === incumbent)

        container.unmountDialog(animated: false) {}

        XCTAssertNil(container.view.firstDescendant(of: ClipyDialogView.self))
    }

    func test_mountingSecondSnackbar_keepsIncumbent_untilCoordinatorUnmounts() async {
        let (container, window) = makeVisibleContainer()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        var firstResult: AppOverlayMountResult?
        var secondResult: AppOverlayMountResult?
        let mounted = expectation(description: "Snackbar entry completed")

        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        XCTAssertEqual(
            container.mountSnackbar(
                message: "First",
                actionTitle: nil,
                onAction: nil,
                onDismiss: {},
                completion: {
                    firstResult = $0
                    mounted.fulfill()
                }
            ),
            .accepted
        )
        await fulfillment(of: [mounted], timeout: 1)
        let incumbent = container.view.firstDescendant(of: ClipySnackbarView.self)

        XCTAssertEqual(
            container.mountSnackbar(
                message: "Second",
                actionTitle: nil,
                onAction: nil,
                onDismiss: {},
                completion: { secondResult = $0 }
            ),
            .occupied
        )

        XCTAssertEqual(firstResult, .displayed)
        XCTAssertNil(secondResult)
        XCTAssertTrue(container.view.firstDescendant(of: ClipySnackbarView.self) === incumbent)

        container.unmountSnackbar(animated: false) {}

        XCTAssertNil(container.view.firstDescendant(of: ClipySnackbarView.self))
    }

    func test_mountingLongSnackbar_keepsActionWithinVisibleArea() async throws {
        let (container, window) = makeVisibleContainer(
            frame: CGRect(x: 0, y: 0, width: 320, height: 200)
        )
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let mounted = expectation(description: "Snackbar entry completed")

        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        XCTAssertEqual(
            container.mountSnackbar(
                message: String(repeating: "Long snackbar message ", count: 20),
                actionTitle: "Retry",
                onAction: {},
                onDismiss: {},
                completion: { _ in mounted.fulfill() }
            ),
            .accepted
        )
        await fulfillment(of: [mounted], timeout: 1)
        container.view.layoutIfNeeded()

        let snackbar = try XCTUnwrap(container.view.firstDescendant(of: ClipySnackbarView.self))
        let actionButton = try XCTUnwrap(snackbar.firstDescendant(of: UIButton.self))
        let actionFrame = actionButton.convert(actionButton.bounds, to: container.view)

        XCTAssertLessThanOrEqual(
            actionFrame.maxY,
            container.view.safeAreaLayoutGuide.layoutFrame.maxY - 10
        )
    }

    private func makeVisibleContainer(
        frame: CGRect = CGRect(x: 0, y: 0, width: 390, height: 844)
    ) -> (AppOverlayContainerViewController, UIWindow) {
        let container = AppOverlayContainerViewController(contentViewController: UIViewController())
        let window = UIWindow(frame: frame)
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.loadViewIfNeeded()
        return (container, window)
    }
}

private extension UIView {
    func firstDescendant<View: UIView>(of type: View.Type) -> View? {
        if let match = self as? View {
            return match
        }
        return subviews.lazy.compactMap { $0.firstDescendant(of: type) }.first
    }
}

private final class SystemUIChildViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscapeLeft }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .bottom }
}
