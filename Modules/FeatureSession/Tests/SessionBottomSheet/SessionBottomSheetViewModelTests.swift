//
//  SessionBottomSheetViewModelTests.swift
//  Clipy
//
//  Created by 박민서 on 5/31/26.
//

import XCTest

import RxCocoa
import RxRelay
import RxSwift

@testable import FeatureSession

/// Bottom Sheet state가 전용 ViewModel output으로 관리되는지 확인합니다.
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

        output.state
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        XCTAssertEqual(states, [.peek])
    }

    func test_dragEnded_emitsNextState_forGrabberDrivenSheetControl() {
        let dragEndedRelay = PublishRelay<SessionBottomSheetAction>()
        let output = makeOutput(dragEnded: dragEndedRelay.asSignal())
        var states: [SessionBottomSheetState] = []

        output.state
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        dragEndedRelay.accept(.dragEnded(translationY: -72, velocityY: 0))

        XCTAssertEqual(states, [.peek, .expanded])
    }

    func test_stateRequest_overridesCurrentState_forInternalOrExternalSheetAction() {
        let stateRequestRelay = PublishRelay<SessionBottomSheetState>()
        let output = makeOutput(stateRequest: stateRequestRelay.asSignal())
        var states: [SessionBottomSheetState] = []

        output.state
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        stateRequestRelay.accept(.hidden)

        XCTAssertEqual(states, [.peek, .hidden])
    }

    func test_stateRequestAfterDrag_overridesDragResult_forPriorityPolicy() {
        let dragEndedRelay = PublishRelay<SessionBottomSheetAction>()
        let stateRequestRelay = PublishRelay<SessionBottomSheetState>()
        let output = makeOutput(
            dragEnded: dragEndedRelay.asSignal(),
            stateRequest: stateRequestRelay.asSignal()
        )
        var states: [SessionBottomSheetState] = []

        output.state
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        dragEndedRelay.accept(.dragEnded(translationY: 72, velocityY: 0))
        stateRequestRelay.accept(.expanded)

        XCTAssertEqual(states, [.peek, .hidden, .expanded])
    }

    func test_dragAfterStateRequest_usesRequestedState_asCurrentSheetState() {
        let dragEndedRelay = PublishRelay<SessionBottomSheetAction>()
        let stateRequestRelay = PublishRelay<SessionBottomSheetState>()
        let output = makeOutput(
            dragEnded: dragEndedRelay.asSignal(),
            stateRequest: stateRequestRelay.asSignal()
        )
        var states: [SessionBottomSheetState] = []

        output.state
            .drive(onNext: { states.append($0) })
            .disposed(by: disposeBag)

        stateRequestRelay.accept(.minimized)
        dragEndedRelay.accept(.dragEnded(translationY: -72, velocityY: 0))

        XCTAssertEqual(states, [.peek, .minimized, .hidden])
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
}
