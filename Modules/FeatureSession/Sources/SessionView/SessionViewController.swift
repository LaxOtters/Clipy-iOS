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
    private let rootView = SessionView()
    private let viewModel: SessionViewModel
    private let bottomSheetViewModel: SessionBottomSheetViewModel
    private let disposeBag = DisposeBag()
    private var previousPopGestureEnabled: Bool?

    init(
        viewModel: SessionViewModel,
        bottomSheetViewModel: SessionBottomSheetViewModel
    ) {
        self.viewModel = viewModel
        self.bottomSheetViewModel = bottomSheetViewModel
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

    private func bindViewModel() {
        let output = viewModel.transform(
            input: SessionViewModel.Input(
                viewDidLoad: .just(()),
                homeTap: rootView.rx.homeTap.asSignal()
            )
        )

        let bottomSheetOutput = bottomSheetViewModel.transform(
            input: SessionBottomSheetViewModel.Input(
                dragEnded: rootView.rx.bottomSheetDragEnded,
                stateRequest: .empty()
            )
        )

        output.initialLoadURL
            .emit(with: self) { owner, url in
                owner.rootView.load(url: url)
            }
            .disposed(by: disposeBag)

        output.initialChromeState
            .emit(with: self) { owner, chromeState in
                owner.rootView.render(chromeState: chromeState)
            }
            .disposed(by: disposeBag)

        output.route
            .emit(with: self) { owner, route in
                owner.handle(route: route)
            }
            .disposed(by: disposeBag)

        bottomSheetOutput.renderState
            .drive(with: self) { owner, state in
                owner.rootView.render(bottomSheetState: state, animated: true)
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
