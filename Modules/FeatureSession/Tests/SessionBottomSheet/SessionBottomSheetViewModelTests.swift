//
//  SessionBottomSheetViewModelTests.swift
//  Clipy
//
//  Created by 박민서 on 5/31/26.
//

import CoreGraphics
import XCTest

import RxCocoa
import RxRelay
import RxSwift

@testable import FeatureSession

final class SessionBottomSheetViewModelTests: XCTestCase {
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }

    func test_output_startsPeek_forSessionBrowsingEntry() {
        let output = makeOutput()
        var states: [SessionBottomSheetState] = []

        output.renderState
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        XCTAssertEqual(states, [.peek])
    }

    func test_sameTargetState_emitsAgain_forSnapBackToDetent() {
        let dragEndedRelay = PublishRelay<SessionBottomSheetAction>()
        let output = makeOutput(dragEnded: dragEndedRelay.asSignal())
        var states: [SessionBottomSheetState] = []

        output.renderState
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        dragEndedRelay.accept(dragEnded(endVisibleHeight: 300, translationY: -14))

        XCTAssertEqual(states, [.peek, .peek])
    }

    func test_stateRequestAfterDrag_emitsRequestedState_forExplicitSheetControl() {
        let dragEndedRelay = PublishRelay<SessionBottomSheetAction>()
        let stateRequestRelay = PublishRelay<SessionBottomSheetState>()
        let output = makeOutput(
            dragEnded: dragEndedRelay.asSignal(),
            stateRequest: stateRequestRelay.asSignal()
        )
        var states: [SessionBottomSheetState] = []

        output.renderState
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        dragEndedRelay.accept(dragEnded(endVisibleHeight: 240, translationY: 46))
        stateRequestRelay.accept(.expanded)

        XCTAssertEqual(states, [.peek, .minimized, .expanded])
    }

    func test_dragAfterStateRequest_usesRequestedState_asCurrentSheetState() {
        let dragEndedRelay = PublishRelay<SessionBottomSheetAction>()
        let stateRequestRelay = PublishRelay<SessionBottomSheetState>()
        let output = makeOutput(
            dragEnded: dragEndedRelay.asSignal(),
            stateRequest: stateRequestRelay.asSignal()
        )
        var states: [SessionBottomSheetState] = []

        output.renderState
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        stateRequestRelay.accept(.minimized)
        dragEndedRelay.accept(dragEnded(endVisibleHeight: 170, translationY: -50))

        XCTAssertEqual(states, [.peek, .minimized, .peek])
    }

    private func makeOutput(
        initialState: SessionBottomSheetState = .peek,
        dragEnded: Signal<SessionBottomSheetAction> = Signal.empty(),
        stateRequest: Signal<SessionBottomSheetState> = Signal.empty()
    ) -> SessionBottomSheetViewModel.Output {
        let viewModel = SessionBottomSheetViewModel(initialState: initialState)
        return viewModel.transform(
            input: SessionBottomSheetViewModel.Input(
                dragEnded: dragEnded,
                stateRequest: stateRequest
            )
        )
    }

    private func dragEnded(
        endVisibleHeight: CGFloat,
        translationY: CGFloat,
        velocityY: CGFloat = 0,
        availableHeight: CGFloat = 760
    ) -> SessionBottomSheetAction {
        .dragEnded(
            SessionBottomSheetDragEndContext(
                translationY: translationY,
                velocityY: velocityY,
                endOffset: availableHeight - endVisibleHeight,
                availableHeight: availableHeight
            )
        )
    }
}
