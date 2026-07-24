//
//  AppMainHomeComposerTests.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import CoreData
import UIKit
import XCTest

import CorePersistence
import FeatureSession

@testable import AppMain

@MainActor
final class AppMainHomeComposerTests: XCTestCase {
    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    func test_mappingHomeRoute_preservesSessionID_withNilInitialURL() {
        let sessionID = UUID()

        let context = AppMainHomeComposer.makeSessionLaunchContext(sessionID: sessionID)

        XCTAssertEqual(context.sessionId, sessionID)
        XCTAssertNil(context.initialURL)
    }

    func test_startingSession_fromComposedHome_routesSavedSessionContextOnce() async throws {
        let stack = try ClipyCoreDataStack(storeType: NSInMemoryStoreType)
        let routed = expectation(description: "saved session route")
        var routedContexts = [SessionLaunchContext]()
        let sut = AppMainHomeComposer(
            makeCoreDataStack: { stack },
            onSessionRoute: { context in
                routedContexts.append(context)
                routed.fulfill()
            }
        )
        let viewController = sut.makeViewController()
        let beginComparisonButton = try XCTUnwrap(hostAndFindButton(in: viewController))

        beginComparisonButton.sendActions(for: .touchUpInside)

        await fulfillment(of: [routed], timeout: 1)

        let routedContext = try XCTUnwrap(routedContexts.first)
        let repository = CoreDataSessionRepository(stack: stack)
        let savedSnapshot = try await repository.loadSession(id: routedContext.sessionId)

        XCTAssertEqual(routedContexts.count, 1)
        XCTAssertNil(routedContext.initialURL)
        XCTAssertEqual(savedSnapshot?.session.id, routedContext.sessionId)
    }

    func test_startingSession_whenStackInitializationFails_showsAlertAndRetriesWithoutRouting() async throws {
        let stack = try ClipyCoreDataStack(storeType: NSInMemoryStoreType)
        let routed = expectation(description: "route after retry")
        var stackFactoryCallCount = 0
        var routedContexts = [SessionLaunchContext]()
        let sut = AppMainHomeComposer(
            makeCoreDataStack: {
                stackFactoryCallCount += 1

                if stackFactoryCallCount == 1 {
                    throw StackInitializationError.failed
                }

                return stack
            },
            onSessionRoute: { context in
                routedContexts.append(context)
                routed.fulfill()
            }
        )
        let viewController = sut.makeViewController()
        let beginComparisonButton = try XCTUnwrap(hostAndFindButton(in: viewController))

        beginComparisonButton.sendActions(for: .touchUpInside)

        let didPresentAlert = await waitUntil {
            viewController.presentedViewController is UIAlertController
        }
        let alert = try XCTUnwrap(viewController.presentedViewController as? UIAlertController)

        XCTAssertTrue(didPresentAlert)
        XCTAssertTrue(routedContexts.isEmpty)
        XCTAssertTrue(beginComparisonButton.isEnabled)

        alert.dismiss(animated: false)
        let didDismissAlert = await waitUntil {
            viewController.presentedViewController == nil
        }
        XCTAssertTrue(didDismissAlert)

        beginComparisonButton.sendActions(for: .touchUpInside)

        await fulfillment(of: [routed], timeout: 1)

        let routedContext = try XCTUnwrap(routedContexts.first)
        let repository = CoreDataSessionRepository(stack: stack)
        let savedSnapshot = try await repository.loadSession(id: routedContext.sessionId)

        XCTAssertEqual(stackFactoryCallCount, 2)
        XCTAssertEqual(routedContexts.count, 1)
        XCTAssertNil(routedContext.initialURL)
        XCTAssertEqual(savedSnapshot?.session.id, routedContext.sessionId)
    }

    private func hostAndFindButton(in viewController: UIViewController) -> UIButton? {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.view.layoutIfNeeded()
        self.window = window
        return button(containingVisibleText: "Begin Comparison", in: viewController.view)
    }

    private func button(
        containingVisibleText text: String,
        in view: UIView
    ) -> UIButton? {
        if let button = view as? UIButton,
           containsVisibleText(text, in: button) {
            return button
        }

        return view.subviews.lazy.compactMap {
            self.button(containingVisibleText: text, in: $0)
        }.first
    }

    private func containsVisibleText(_ text: String, in view: UIView) -> Bool {
        if let label = view as? UILabel,
           (label.attributedText?.string ?? label.text) == text {
            return true
        }

        return view.subviews.contains {
            self.containsVisibleText(text, in: $0)
        }
    }

    private func waitUntil(
        timeout: TimeInterval = 1,
        condition: () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if condition() {
                return true
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        return condition()
    }
}

private enum StackInitializationError: Error {
    case failed
}
