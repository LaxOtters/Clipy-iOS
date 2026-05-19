//
//  SessionViewController.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import UIKit

import RxCocoa
import RxSwift

/// Session 화면의 lifecycle, binding, Home route 처리를 맡는 UIKit shell입니다.
final class SessionViewController: UIViewController {
    private let rootView = SessionView()
    private let viewModel: SessionViewModel
    private let disposeBag = DisposeBag()
    private var previousPopGestureEnabled: Bool?

    init(viewModel: SessionViewModel) {
        self.viewModel = viewModel
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

        output.initialLoadURL
            .emit(with: self) { owner, url in
                owner.rootView.load(url: url)
            }
            .disposed(by: disposeBag)

        output.route
            .emit(with: self) { owner, route in
                owner.handle(route: route)
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
