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
        homeTap: Signal<Void> = Signal.empty()
    ) -> SessionViewModel.Output {
        let viewModel = SessionViewModel(context: context)
        return viewModel.transform(
            input: SessionViewModel.Input(
                viewDidLoad: viewDidLoad,
                homeTap: homeTap
            )
        )
    }
}
