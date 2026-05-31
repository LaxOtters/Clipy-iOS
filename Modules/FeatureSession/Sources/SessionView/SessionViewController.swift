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
    /// Session 화면의 UIKit hierarchy를 소유하는 root view입니다.
    private let rootView = SessionView()
    /// Session 진입 URL load와 화면 route를 만드는 화면 ViewModel입니다.
    private let viewModel: SessionViewModel
    /// Bottom Sheet 상태를 소유하는 surface ViewModel입니다.
    private let bottomSheetViewModel: SessionBottomSheetViewModel
    /// ViewController lifecycle 동안 유지되는 Rx binding 소유자입니다.
    private let disposeBag = DisposeBag()
    /// Session 진입 전 navigation pop gesture 설정을 복원하기 위한 값입니다.
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
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let previousPopGestureEnabled {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = previousPopGestureEnabled
        }
        super.viewWillDisappear(animated)
    }

    /// RootView event를 ViewModel input으로 넘기고 output을 화면에 반영합니다.
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

        output.route
            .emit(with: self) { owner, route in
                owner.handle(route: route)
            }
            .disposed(by: disposeBag)

        bottomSheetOutput.state
            .drive(with: self) { owner, state in
                owner.rootView.render(bottomSheetState: state, animated: true)
            }
            .disposed(by: disposeBag)
    }

    /// Session ViewModel이 내보낸 화면 이동 의도를 UIKit navigation으로 처리합니다.
    private func handle(route: SessionRoute) {
        switch route {
        case .home:
            navigationController?.popViewController(animated: true)
        }
    }
}
