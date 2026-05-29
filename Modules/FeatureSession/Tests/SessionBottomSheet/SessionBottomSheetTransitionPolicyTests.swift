//
//  SessionBottomSheetTransitionPolicyTests.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

import XCTest

@testable import FeatureSession

/// Bottom Sheet drag action이 Session의 sheet state 정책으로 해석되는지 확인합니다.
final class SessionBottomSheetTransitionPolicyTests: XCTestCase {
    func test_upwardDragFromMinimized_movesToHidden_forRestoringBrowserControls() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let state = sut.nextState(
            from: .minimized,
            action: .dragEnded(translationY: -72, velocityY: 0)
        )

        XCTAssertEqual(state, .hidden)
    }

    func test_upwardDragFromHidden_movesToPeek_forBrowsingEntryCue() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let state = sut.nextState(
            from: .hidden,
            action: .dragEnded(translationY: -72, velocityY: 0)
        )

        XCTAssertEqual(state, .peek)
    }

    func test_upwardDragFromPeek_movesToExpanded_forComparisonEntry() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let state = sut.nextState(
            from: .peek,
            action: .dragEnded(translationY: -72, velocityY: 0)
        )

        XCTAssertEqual(state, .expanded)
    }

    func test_downwardDragFromExpanded_movesToPeek_forReturningToBrowsing() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let state = sut.nextState(
            from: .expanded,
            action: .dragEnded(translationY: 72, velocityY: 0)
        )

        XCTAssertEqual(state, .peek)
    }

    func test_downwardDragFromPeek_movesToHidden_forWebViewFocusedBrowsing() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let state = sut.nextState(
            from: .peek,
            action: .dragEnded(translationY: 72, velocityY: 0)
        )

        XCTAssertEqual(state, .hidden)
    }

    func test_downwardDragFromHidden_movesToMinimized_forCompactBrowserChrome() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let state = sut.nextState(
            from: .hidden,
            action: .dragEnded(translationY: 72, velocityY: 0)
        )

        XCTAssertEqual(state, .minimized)
    }

    func test_downwardDragFromMinimized_keepsMinimized_forLowestSheetState() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let state = sut.nextState(
            from: .minimized,
            action: .dragEnded(translationY: 72, velocityY: 0)
        )

        XCTAssertEqual(state, .minimized)
    }

    func test_shortDrag_keepsCurrentState_withoutAccidentalSheetChange() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let state = sut.nextState(
            from: .peek,
            action: .dragEnded(translationY: -12, velocityY: 0)
        )

        XCTAssertEqual(state, .peek)
    }

    func test_repeatedUpwardDrags_reachExpandedWithoutSkippingStates_forStepwiseSheetPolicy() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let firstState = sut.nextState(
            from: .minimized,
            action: .dragEnded(translationY: -72, velocityY: 0)
        )
        let secondState = sut.nextState(
            from: firstState,
            action: .dragEnded(translationY: -72, velocityY: 0)
        )
        let thirdState = sut.nextState(
            from: secondState,
            action: .dragEnded(translationY: -72, velocityY: 0)
        )

        XCTAssertEqual(firstState, .hidden)
        XCTAssertEqual(secondState, .peek)
        XCTAssertEqual(thirdState, .expanded)
    }

    func test_fastUpwardFlick_movesOneStepOnly_forPredictableSheetControl() {
        let sut = SessionBottomSheetTransitionPolicy.standard

        let state = sut.nextState(
            from: .hidden,
            action: .dragEnded(translationY: -8, velocityY: -620)
        )

        XCTAssertEqual(state, .peek)
    }
}
