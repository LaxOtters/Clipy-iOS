//
//  SessionViewModelTests.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import XCTest

import RxCocoa
import RxRelay
import RxSwift

@testable import FeatureSession

final class SessionViewModelTests: XCTestCase {
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }

    func test_viewDidLoadWithInitialURL_emitsInitialURL_readyForBrowsing() {
        let initialURL = URL(string: "https://www.google.com")!
        let viewDidLoadRelay = PublishRelay<Void>()
        let output = makeOutput(
            context: SessionLaunchContext(sessionId: UUID(), initialURL: initialURL),
            viewDidLoad: viewDidLoadRelay.asSignal()
        )
        var loadedURLs: [URL] = []

        output.initialLoadURL
            .emit(onNext: { loadedURLs.append($0) })
            .disposed(by: disposeBag)

        viewDidLoadRelay.accept(())

        XCTAssertEqual(loadedURLs, [initialURL])
    }

    func test_viewDidLoadWithoutInitialURL_doesNotEmitInitialURL_readyForEmptySession() {
        let viewDidLoadRelay = PublishRelay<Void>()
        let output = makeOutput(
            context: SessionLaunchContext(sessionId: UUID(), initialURL: nil),
            viewDidLoad: viewDidLoadRelay.asSignal()
        )
        var loadedURLs: [URL] = []

        output.initialLoadURL
            .emit(onNext: { loadedURLs.append($0) })
            .disposed(by: disposeBag)

        viewDidLoadRelay.accept(())

        XCTAssertTrue(loadedURLs.isEmpty)
    }

    func test_output_startsWithNewSessionChromeState_forInitialPeekContract() {
        let output = makeOutput()
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        XCTAssertEqual(chromeStates, [.newSession])
    }

    func test_topBarToggleFromInitialPeek_foldsTopBarOnly_keepsBottomSheetPeek() {
        let topBarToggleRelay = PublishRelay<Void>()
        let output = makeOutput(topBarToggleTap: topBarToggleRelay.asSignal())
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

    func test_rootScrollDownAfterBrowsingMinimized_hidesChrome_forFocusedBrowsing() {
        let navigationFinishedRelay = PublishRelay<Void>()
        let rootScrollRelay = PublishRelay<SessionWebRootScrollEvent>()
        let output = makeOutput(
            webRootScroll: rootScrollRelay.asSignal(),
            browserNavigationFinished: navigationFinishedRelay.asSignal()
        )
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        navigationFinishedRelay.accept(())
        navigationFinishedRelay.accept(())
        rootScrollRelay.accept(.init(direction: .down, isEligibleForChromeTransition: true))

        XCTAssertEqual(
            chromeStates,
            [.newSession, .browsingMinimized, .browsingHidden]
        )
    }

    func test_navigationFinished_keepsFirstPeek_thenRestoresLaterNavigationToMinimized() {
        let navigationFinishedRelay = PublishRelay<Void>()
        let output = makeOutput(browserNavigationFinished: navigationFinishedRelay.asSignal())
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
        let output = makeOutput(bottomSheetDragEnded: bottomSheetDragRelay.asSignal())
        var chromeStates: [SessionChromeState] = []

        output.chromeState
            .drive(onNext: { chromeStates.append($0) })
            .disposed(by: disposeBag)

        bottomSheetDragRelay.accept(dragEnded(endVisibleHeight: 240, translationY: 46))

        XCTAssertEqual(chromeStates, [.newSession, .browsingMinimized])
    }

    func test_homeTap_emitsHomeRoute_forExplicitSessionExit() {
        let homeTapRelay = PublishRelay<Void>()
        let output = makeOutput(homeTap: homeTapRelay.asSignal())
        var routes: [SessionRoute] = []

        output.route
            .emit(onNext: { routes.append($0) })
            .disposed(by: disposeBag)

        homeTapRelay.accept(())

        XCTAssertEqual(routes, [.home])
    }

    private func makeOutput(
        context: SessionLaunchContext = SessionLaunchContext(sessionId: UUID()),
        viewDidLoad: Signal<Void> = Signal.empty(),
        homeTap: Signal<Void> = Signal.empty(),
        topBarToggleTap: Signal<Void> = Signal.empty(),
        webRootScroll: Signal<SessionWebRootScrollEvent> = Signal.empty(),
        browserNavigationFinished: Signal<Void> = Signal.empty(),
        bottomSheetDragEnded: Signal<SessionBottomSheetAction> = Signal.empty()
    ) -> SessionViewModel.Output {
        let viewModel = SessionViewModel(context: context)
        return viewModel.transform(
            input: SessionViewModel.Input(
                viewDidLoad: viewDidLoad,
                homeTap: homeTap,
                topBarToggleTap: topBarToggleTap,
                webRootScroll: webRootScroll,
                browserNavigationFinished: browserNavigationFinished,
                bottomSheetDragEnded: bottomSheetDragEnded
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
