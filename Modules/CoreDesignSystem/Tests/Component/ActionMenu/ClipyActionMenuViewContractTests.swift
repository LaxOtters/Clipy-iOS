//
//  ClipyActionMenuViewContractTests.swift
//  Clipy
//
//  Created by 박민서 on 7/23/26.
//

import UIKit
import XCTest

@testable import CoreDesignSystem

final class ClipyActionMenuViewContractTests: XCTestCase {
    private var hosts = [UIViewController]()
    private var windows = [UIWindow]()

    override func tearDown() {
        windows.forEach { $0.isHidden = true }
        windows.removeAll()
        hosts.removeAll()
        super.tearDown()
    }

    func test_standardAnimation_andDefaultInitializer_useFadeAndScaleAtPointOneSixSeconds() throws {
        assertFadeAndScale(ClipyActionMenuAnimation.standard)
        assertFadeAndScale(try XCTUnwrap(ClipyActionMenuAnimation()))
    }

    func test_initializingWithInvalidDurations_returnsNil_forEveryRejectedValue() {
        [-0.01, Double.nan, Double.infinity, -Double.infinity].forEach { duration in
            XCTAssertNil(ClipyActionMenuAnimation(style: .fade, duration: duration))
        }
    }

    func test_immediatePresentationAndDismissal_reachExpectedEndpointAcrossNoAnimationPaths() throws {
        let menu = try makeMenu(itemCount: 2)

        XCTAssertTrue(menu.isHidden)
        XCTAssertEqual(menu.alpha, 0)
        XCTAssertFalse(menu.isUserInteractionEnabled)

        menu.present(animated: false)

        assertPresented(menu)

        menu.dismiss(animated: false)

        assertDismissed(menu)

        let noneAnimation = try XCTUnwrap(ClipyActionMenuAnimation(style: .none, duration: 0.16))
        let noneMenu = try makeMenu(itemCount: 2, animation: noneAnimation)
        noneMenu.present()
        assertPresented(noneMenu)
        noneMenu.dismiss()
        assertDismissed(noneMenu)

        let zeroDurationAnimation = try XCTUnwrap(ClipyActionMenuAnimation(style: .fade, duration: 0))
        let zeroDurationMenu = try makeMenu(itemCount: 2, animation: zeroDurationAnimation)
        zeroDurationMenu.present()
        assertPresented(zeroDurationMenu)
        zeroDurationMenu.dismiss()
        assertDismissed(zeroDurationMenu)
    }

    func test_intrinsicContentSize_ownsTwoAndFourItemMenuFootprints() throws {
        let twoItemMenu = try makeMenu(itemCount: 2)
        let fourItemMenu = try makeMenu(itemCount: 4)

        XCTAssertEqual(twoItemMenu.intrinsicContentSize, CGSize(width: 135, height: 88))
        XCTAssertEqual(fourItemMenu.intrinsicContentSize, CGSize(width: 135, height: 168))
    }

    func test_performingAction_runsOnlySelectedAction_onceSynchronouslyOnMainThread() throws {
        var performed = [Int]()
        var ranOnMainThread = false
        let items = [
            ClipyActionMenuItem(title: "Link", image: UIImage()) { performed.append(0) },
            ClipyActionMenuItem(title: "Delete", image: UIImage(), role: .destructive) {
                performed.append(1)
                ranOnMainThread = Thread.isMainThread
            }
        ]
        let menu = try hostMenu(items: items)

        menu.performAction(at: 1)

        XCTAssertEqual(performed, [1])
        XCTAssertTrue(ranOnMainThread)
    }

    func test_releaseFallbacks_returnNilForEmptyItems_andIgnoreOutOfRangeActions() throws {
        #if DEBUG
        throw XCTSkip("Release fallback behavior runs only in the Release configuration.")
        #else
        XCTAssertNil(ClipyActionMenuView(items: []))

        var actionCount = 0
        let menu = try hostMenu(items: [
            ClipyActionMenuItem(title: "Link", image: UIImage()) { actionCount += 1 },
            ClipyActionMenuItem(title: "Delete", image: UIImage()) { actionCount += 1 }
        ])

        menu.performAction(at: -1)
        menu.performAction(at: 2)

        XCTAssertEqual(actionCount, 0)
        #endif
    }

    func test_actionReentry_keepsTheCallbackEndpoint_withoutAutomaticDismissal() throws {
        weak var weakMenu: ClipyActionMenuView?
        let item = ClipyActionMenuItem(title: "Link", image: UIImage()) {
            weakMenu?.present(animated: false)
        }
        let menu = try hostMenu(items: [item])
        weakMenu = menu

        menu.performAction(at: 0)

        assertPresented(menu)
    }

    func test_actionReentry_withDismiss_keepsCallbackEndpoint_withoutPostCallbackMutation() throws {
        weak var weakMenu: ClipyActionMenuView?
        let item = ClipyActionMenuItem(title: "Link", image: UIImage()) {
            weakMenu?.dismiss(animated: false)
        }
        let menu = try hostMenu(items: [item])
        weakMenu = menu
        menu.present(animated: false)

        menu.performAction(at: 0)

        assertDismissed(menu)
    }

    func test_latestRequestWins_whenOppositeAnimatedRequestsInterruptEachOther() throws {
        let animation = try XCTUnwrap(ClipyActionMenuAnimation(style: .fadeAndScale, duration: 0.05))
        let presentingMenu = try makeMenu(itemCount: 2, animation: animation)

        presentingMenu.present()
        presentingMenu.dismiss()
        presentingMenu.present()

        waitForPresented(presentingMenu)

        let dismissingMenu = try makeMenu(itemCount: 2, animation: animation)
        dismissingMenu.present(animated: false)
        dismissingMenu.dismiss()
        dismissingMenu.present()
        dismissingMenu.dismiss()

        waitForDismissed(dismissingMenu)
    }

    func test_immediateOppositeRequest_cannotBeOverwrittenByEarlierAnimationCompletion() throws {
        let animation = try XCTUnwrap(ClipyActionMenuAnimation(style: .fadeAndScale, duration: 0.05))
        let menu = try makeMenu(itemCount: 2, animation: animation)

        menu.present()
        menu.dismiss(animated: false)

        waitForDismissed(menu)

        menu.present(animated: false)
        menu.dismiss()
        menu.present(animated: false)

        waitForPresented(menu)
    }

    func test_repeatingSameEndpoint_doesNotRestartTransition_orChangeLifecycleOutcome() throws {
        let animation = try XCTUnwrap(ClipyActionMenuAnimation(style: .fade, duration: 0.12))
        let menu = try makeMenu(itemCount: 2, animation: animation)

        menu.dismiss()
        assertDismissed(menu)

        menu.present()
        menu.present()
        waitForPresented(menu)

        menu.present()
        assertPresented(menu)

        menu.dismiss()
        menu.dismiss()
        waitForDismissed(menu)
    }

    func test_animatedLifecycle_gatesInteraction_untilPresented_andImmediatelyAfterDismissalStarts() throws {
        let animation = try XCTUnwrap(ClipyActionMenuAnimation(style: .fadeAndScale, duration: 0.05))
        let menu = try makeMenu(itemCount: 2, animation: animation)

        menu.present()

        XCTAssertFalse(menu.isUserInteractionEnabled)

        waitForPresented(menu)

        menu.dismiss()

        XCTAssertFalse(menu.isUserInteractionEnabled)

        waitForDismissed(menu)
    }

    func test_presentationLifecycle_preservesCallerOwnedPlacementTransformAndAnimation() throws {
        let animation = try XCTUnwrap(ClipyActionMenuAnimation(style: .fadeAndScale, duration: 0.05))
        let menu = try makeMenu(itemCount: 2, animation: animation)
        let placementTransform = CGAffineTransform(translationX: 12, y: 8)
        let placementAnimationKey = "host-placement"
        let placementAnimation = CABasicAnimation(keyPath: "position.x")
        placementAnimation.fromValue = menu.layer.position.x
        placementAnimation.toValue = menu.layer.position.x + 8
        placementAnimation.duration = 10
        placementAnimation.repeatCount = .greatestFiniteMagnitude

        menu.transform = placementTransform
        menu.layer.add(placementAnimation, forKey: placementAnimationKey)

        menu.present(animated: false)
        assertPlacement(
            of: menu,
            transform: placementTransform,
            animationKey: placementAnimationKey
        )

        menu.dismiss(animated: false)
        assertPlacement(
            of: menu,
            transform: placementTransform,
            animationKey: placementAnimationKey
        )

        menu.present()
        waitForPresented(menu)
        assertPlacement(
            of: menu,
            transform: placementTransform,
            animationKey: placementAnimationKey
        )

        menu.dismiss()
        waitForDismissed(menu)
        assertPlacement(
            of: menu,
            transform: placementTransform,
            animationKey: placementAnimationKey
        )
    }
}

private extension ClipyActionMenuViewContractTests {
    func makeMenu(
        itemCount: Int,
        animation: ClipyActionMenuAnimation = .standard
    ) throws -> ClipyActionMenuView {
        let items = (0..<itemCount).map { index in
            ClipyActionMenuItem(title: "Item \(index)", image: UIImage()) {}
        }
        return try hostMenu(items: items, animation: animation)
    }

    func hostMenu(
        items: [ClipyActionMenuItem],
        animation: ClipyActionMenuAnimation = .standard
    ) throws -> ClipyActionMenuView {
        let host = UIViewController()
        host.loadViewIfNeeded()
        host.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        let window = UIWindow(frame: host.view.bounds)
        window.rootViewController = host
        window.isHidden = false

        let menu = try XCTUnwrap(ClipyActionMenuView(items: items, animation: animation))
        menu.frame = CGRect(origin: CGPoint(x: 16, y: 16), size: menu.intrinsicContentSize)
        host.view.addSubview(menu)
        host.view.layoutIfNeeded()
        hosts.append(host)
        windows.append(window)
        return menu
    }

    func assertFadeAndScale(
        _ animation: ClipyActionMenuAnimation,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .fadeAndScale = animation.style else {
            return XCTFail("Expected fadeAndScale animation.", file: file, line: line)
        }
        XCTAssertEqual(animation.duration, 0.16, accuracy: 0.000001, file: file, line: line)
    }

    func assertPresented(
        _ menu: ClipyActionMenuView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(menu.isHidden, file: file, line: line)
        XCTAssertEqual(menu.alpha, 1, accuracy: 0.000001, file: file, line: line)
        XCTAssertTrue(menu.isUserInteractionEnabled, file: file, line: line)
    }

    func assertDismissed(
        _ menu: ClipyActionMenuView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(menu.isHidden, file: file, line: line)
        XCTAssertEqual(menu.alpha, 0, accuracy: 0.000001, file: file, line: line)
        XCTAssertFalse(menu.isUserInteractionEnabled, file: file, line: line)
    }

    func waitForPresented(
        _ menu: ClipyActionMenuView,
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitForEndpoint(menu, timeout: timeout, matches: { menu in
            !menu.isHidden
                && menu.alpha == 1
                && menu.isUserInteractionEnabled
        }, file: file, line: line)
    }

    func waitForDismissed(
        _ menu: ClipyActionMenuView,
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitForEndpoint(menu, timeout: timeout, matches: { menu in
            menu.isHidden
                && menu.alpha == 0
                && !menu.isUserInteractionEnabled
        }, file: file, line: line)
    }

    func assertPlacement(
        of menu: ClipyActionMenuView,
        transform expectedTransform: CGAffineTransform,
        animationKey: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(menu.transform, expectedTransform, file: file, line: line)
        XCTAssertNotNil(menu.layer.animation(forKey: animationKey), file: file, line: line)
    }

    func waitForEndpoint(
        _ menu: ClipyActionMenuView,
        timeout: TimeInterval,
        matches predicate: (ClipyActionMenuView) -> Bool,
        file: StaticString,
        line: UInt
    ) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if predicate(menu) {
                return
            }

            RunLoop.main.run(until: min(deadline, Date().addingTimeInterval(0.01)))
        }

        XCTAssertTrue(
            predicate(menu),
            "Menu did not reach its expected endpoint before the deadline.",
            file: file,
            line: line
        )
    }
}
