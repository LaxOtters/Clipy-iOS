//
//  HomeViewController.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import UIKit

import RxCocoa
import RxSwift

/// First Use Home을 그리고, ViewModel output을 UIKit 화면과 AppMain route에 연결합니다.
final class HomeViewController: UIViewController {
    private let homeView = HomeView()
    private let viewModel: HomeViewModel
    private let onRoute: (HomeFeatureRoute) -> Void
    private let disposeBag = DisposeBag()

    init(
        viewModel: HomeViewModel,
        onRoute: @escaping (HomeFeatureRoute) -> Void
    ) {
        self.viewModel = viewModel
        self.onRoute = onRoute
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = homeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let output = viewModel.transform(
            input: HomeViewModel.Input(
                beginComparisonTap: homeView.beginComparisonButton.rx.tap.asSignal()
            )
        )

        output.isStartEnabled
            .drive(homeView.beginComparisonButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.route
            .emit(with: self) { viewController, route in
                viewController.onRoute(route)
            }
            .disposed(by: disposeBag)

        output.failureAlert
            .emit(with: self) { viewController, _ in
                viewController.presentStartFailureAlert()
            }
            .disposed(by: disposeBag)
    }

    private func presentStartFailureAlert() {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(
            title: "Unable to Start Session",
            message: "Failed to make session. Try again",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
