//
//  SessionAddItemViewController.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

import RxCocoa
import RxSwift

/// 처음 값이 채워진 상품 추가 카드를 Session 화면 위에 보여 주고, 닫기 요청을 Session 화면에 넘깁니다.
final class SessionAddItemViewController: UIViewController {
    private let rootView: SessionAddItemView
    private let disposeBag = DisposeBag()
    var onClose: (() -> Void)?

    init(values: SessionItemFormValues) {
        rootView = SessionAddItemView(values: values)
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
        bindView()
    }

    private func bindView() {
        rootView.rx.closeTap
            .asSignal()
            .emit(with: self) { owner, _ in
                owner.view.endEditing(true)
                owner.onClose?()
            }
            .disposed(by: disposeBag)
    }
}
