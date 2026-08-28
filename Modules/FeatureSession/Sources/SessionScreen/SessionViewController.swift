//
//  SessionViewController.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import UIKit

import RxCocoa
import RxSwift

final class SessionViewController: UIViewController {
    private let rootView: SessionView
    private let viewModel: SessionViewModel
    private let disposeBag = DisposeBag()
    private var previousPopGestureEnabled: Bool?

    init(
        viewModel: SessionViewModel,
        dependencies: SessionFeature.Dependencies
    ) {
        self.viewModel = viewModel
        rootView = SessionView(dependencies: dependencies)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView.onWebRecoveryGoHome = { [weak self] in
            self?.handle(route: .home)
        }
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesBackButton = true
        previousPopGestureEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled
        // Session은 자체 Home route로 나가므로 기본 pop gesture를 막고 나갈 때 원래 값으로 돌립니다.
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let previousPopGestureEnabled {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = previousPopGestureEnabled
        }
        super.viewWillDisappear(animated)
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)

        if parent == nil {
            rootView.endSession()
        }
    }

    deinit {
        rootView.endSession()
    }

    private func bindViewModel() {
        let output = viewModel.transform(
            input: SessionViewModel.Input(
                viewDidLoad: .just(()),
                homeTap: rootView.rx.homeTap.asSignal(),
                topBarToggleTap: rootView.rx.topBarToggleTap.asSignal(),
                webRootScroll: rootView.rx.webRootScroll,
                browserNavigationFinished: rootView.rx.navigationFinished,
                bottomSheetDragEnded: rootView.rx.bottomSheetDragEnded
            )
        )

        rootView.rx.browserState
            .drive(with: self) { owner, browserState in
                owner.rootView.render(browserState: browserState)
            }
            .disposed(by: disposeBag)

        rootView.rx.backTap
            .asSignal()
            .emit(with: self, onNext: { owner, _ in
                owner.rootView.goBack()
            })
            .disposed(by: disposeBag)

        rootView.rx.forwardTap
            .asSignal()
            .emit(with: self, onNext: { owner, _ in
                owner.rootView.goForward()
            })
            .disposed(by: disposeBag)

        rootView.rx.reloadTap
            .asSignal()
            .emit(with: self, onNext: { owner, _ in
                owner.rootView.reload()
            })
            .disposed(by: disposeBag)

        output.chromeState
            .drive(with: self) { owner, chromeState in
                owner.rootView.render(chromeState: chromeState, animated: true)
            }
            .disposed(by: disposeBag)

        output.route
            .emit(with: self) { owner, route in
                owner.handle(route: route)
            }
            .disposed(by: disposeBag)

        // WebView 이벤트 구독을 먼저 연결한 뒤 initial load를 시작해야 첫 navigation 상태 변화를 놓치지 않습니다.
        output.initialLoadURL
            .emit(with: self) { owner, url in
                owner.rootView.load(url: url)
            }
            .disposed(by: disposeBag)
    }

    private func handle(route: SessionRoute) {
        switch route {
        case .home:
            navigationController?.popViewController(animated: true)
        }
    }
}
