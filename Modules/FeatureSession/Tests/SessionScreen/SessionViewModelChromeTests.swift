//
//  SessionViewModelChromeTests.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import XCTest

import RxCocoa
import RxRelay
import RxSwift

@testable import FeatureSession

final class SessionViewModelChromeTests: XCTestCase {
    typealias Fixture = SessionViewModelTestFixture

    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }

    func test_output_startsWithNewSessionChromeState_forInitialPeekContract() {
        let output = Fixture.makeOutput()
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        XCTAssertEqual(chromeStates, [.newSession])
    }

    func test_topBarToggleFromInitialPeek_foldsTopBarOnly_keepsBottomSheetPeek() {
        let topBarToggleRelay = PublishRelay<Void>()
        let output = Fixture.makeOutput(topBarToggleTap: topBarToggleRelay.asSignal())
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        topBarToggleRelay.accept(())

        XCTAssertEqual(
            chromeStates,
            [.newSession, .comparingPeek(topBarState: .folded)]
        )
    }

    func test_topBarToggleDuringWebRootDragging_doesNotEmitRender_forIgnoredInteraction() {
        let topBarToggleRelay = PublishRelay<Void>()
        let rootScrollRelay = PublishRelay<SessionWebRootScrollInput>()
        let output = Fixture.makeOutput(
            topBarToggleTap: topBarToggleRelay.asSignal(),
            webRootScroll: rootScrollRelay.asSignal()
        )
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        rootScrollRelay.accept(.dragBegan(Fixture.snapshot(offsetY: 0)))
        topBarToggleRelay.accept(())

        XCTAssertEqual(chromeStates, [.newSession])
    }

    func test_rootScrollDownAfterBrowsingMinimized_hidesChrome_forFocusedBrowsing() {
        let navigationFinishedRelay = PublishRelay<Void>()
        let rootScrollRelay = PublishRelay<SessionWebRootScrollInput>()
        let output = Fixture.makeOutput(
            webRootScroll: rootScrollRelay.asSignal(),
            browserNavigationFinished: navigationFinishedRelay.asSignal()
        )
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        navigationFinishedRelay.accept(())
        navigationFinishedRelay.accept(())
        rootScrollRelay.accept(.dragBegan(Fixture.snapshot(offsetY: 0)))
        rootScrollRelay.accept(.dragged(Fixture.snapshot(offsetY: 14)))

        XCTAssertEqual(
            chromeStates,
            [.newSession, .browsingMinimized, .browsingHidden]
        )
    }

    func test_navigationFinished_keepsFirstPeek_thenRestoresLaterNavigationToMinimized() {
        let navigationFinishedRelay = PublishRelay<Void>()
        let output = Fixture.makeOutput(browserNavigationFinished: navigationFinishedRelay.asSignal())
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        navigationFinishedRelay.accept(())
        navigationFinishedRelay.accept(())

        XCTAssertEqual(chromeStates, [.newSession, .browsingMinimized])
    }

    func test_bottomSheetDrag_routesThroughChromeReducer_forSharedChromeState() {
        let bottomSheetDragRelay = PublishRelay<SessionBottomSheetAction>()
        let output = Fixture.makeOutput(bottomSheetDragEnded: bottomSheetDragRelay.asSignal())
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        bottomSheetDragRelay.accept(Fixture.dragEnded(endVisibleHeight: 240, translationY: 46))

        XCTAssertEqual(chromeStates, [.newSession, .browsingMinimized])
    }

    func test_bottomSheetDragEndingAtCurrentDetent_emitsAgain_forSnapBackRender() {
        let bottomSheetDragRelay = PublishRelay<SessionBottomSheetAction>()
        let output = Fixture.makeOutput(bottomSheetDragEnded: bottomSheetDragRelay.asSignal())
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        bottomSheetDragRelay.accept(Fixture.dragEnded(endVisibleHeight: 286, translationY: 0))

        XCTAssertEqual(chromeStates, [.newSession, .newSession])
    }
}
