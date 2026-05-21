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
    func test_upwardDragFromHidden_movesToPeek_forBrowsingEntryCue() {
        var sut = SessionBottomSheetStateMachine(initialState: .hidden)

        let state = sut.handle(.dragEnded(translationY: -72, velocityY: 0))

        XCTAssertEqual(state, .peek)
        XCTAssertEqual(sut.currentState, .peek)
    }

    func test_upwardDragFromPeek_movesToExpanded_forComparisonEntry() {
        var sut = SessionBottomSheetStateMachine(initialState: .peek)

        let state = sut.handle(.dragEnded(translationY: -72, velocityY: 0))

        XCTAssertEqual(state, .expanded)
        XCTAssertEqual(sut.currentState, .expanded)
    }

    func test_downwardDragFromExpanded_movesToPeek_forReturningToBrowsing() {
        var sut = SessionBottomSheetStateMachine(initialState: .expanded)

        let state = sut.handle(.dragEnded(translationY: 72, velocityY: 0))

        XCTAssertEqual(state, .peek)
        XCTAssertEqual(sut.currentState, .peek)
    }

    func test_downwardDragFromPeek_movesToHidden_forWebViewFocusedBrowsing() {
        var sut = SessionBottomSheetStateMachine(initialState: .peek)

        let state = sut.handle(.dragEnded(translationY: 72, velocityY: 0))

        XCTAssertEqual(state, .hidden)
        XCTAssertEqual(sut.currentState, .hidden)
    }

    func test_shortDrag_keepsCurrentState_withoutAccidentalSheetChange() {
        var sut = SessionBottomSheetStateMachine(initialState: .peek)

        let state = sut.handle(.dragEnded(translationY: -12, velocityY: 0))

        XCTAssertEqual(state, .peek)
        XCTAssertEqual(sut.currentState, .peek)
    }

    func test_repeatedUpwardDrags_reachExpandedWithoutSkippingPeek_forStepwiseSheetPolicy() {
        var sut = SessionBottomSheetStateMachine(initialState: .hidden)

        let firstState = sut.handle(.dragEnded(translationY: -72, velocityY: 0))
        let secondState = sut.handle(.dragEnded(translationY: -72, velocityY: 0))

        XCTAssertEqual(firstState, .peek)
        XCTAssertEqual(secondState, .expanded)
        XCTAssertEqual(sut.currentState, .expanded)
    }

    func test_fastUpwardFlick_movesOneStepOnly_forPredictableSheetControl() {
        var sut = SessionBottomSheetStateMachine(initialState: .hidden)

        let state = sut.handle(.dragEnded(translationY: -8, velocityY: -620))

        XCTAssertEqual(state, .peek)
        XCTAssertEqual(sut.currentState, .peek)
    }
}
