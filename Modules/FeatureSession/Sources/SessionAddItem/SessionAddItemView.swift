//
//  SessionAddItemView.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

import CoreDesignSystem
import RxCocoa
import RxSwift

/// Session 화면 위에 깔리는 backdrop과 상품 추가 카드입니다. 키보드가 올라오면 카드를 줄이고 입력 중인 칸을 보이게 합니다.
final class SessionAddItemView: UIView {
    private enum Layout {
        static let cardHorizontalInset: CGFloat = 20
        static let cardVerticalInset: CGFloat = 16
        static let cardCornerRadius: CGFloat = 20
    }

    private let cardView = UIView()
    fileprivate let headerView = ClipyPopupHeader(title: "Add item", actionTitle: "Save")
    private let scrollView = UIScrollView()
    private let formView: SessionItemFormView

    init(values: SessionItemFormValues) {
        formView = SessionItemFormView(values: values)
        super.init(frame: .zero)
        configureHierarchy()
        configureStyle()
        configureLayout()
        configureKeyboardScroll()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func configureHierarchy() {
        addSubview(cardView)
        cardView.addSubview(headerView)
        cardView.addSubview(scrollView)
        scrollView.addSubview(formView)
    }

    private func configureStyle() {
        backgroundColor = ClipyColor.Foundation.overlayBackground

        cardView.backgroundColor = ClipyColor.Foundation.neutral50
        cardView.layer.cornerRadius = Layout.cardCornerRadius
        cardView.clipsToBounds = true

        // 처음 상태는 상품명이 비어 있어 저장할 수 없으므로 비활성으로 둡니다.
        // 입력값 검증이 붙으면 이 고정값은 지우고, 현재 입력의 유효성으로 활성화를 정합니다.
        headerView.actionButton?.isEnabled = false

        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
    }

    private func configureLayout() {
        [cardView, headerView, scrollView, formView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // 내용이 다 들어가면 카드가 내용 높이에 맞고, 키보드나 작은 화면에서는 카드 안을 스크롤합니다.
        let fittingHeight = scrollView.heightAnchor.constraint(equalTo: formView.heightAnchor)
        fittingHeight.priority = .defaultLow
        let centered = cardView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
        centered.priority = .defaultLow

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.cardHorizontalInset),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.cardHorizontalInset),
            cardView.topAnchor.constraint(
                greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor,
                constant: Layout.cardVerticalInset
            ),
            cardView.bottomAnchor.constraint(
                lessThanOrEqualTo: keyboardLayoutGuide.topAnchor,
                constant: -Layout.cardVerticalInset
            ),
            centered,

            headerView.topAnchor.constraint(equalTo: cardView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            fittingHeight,

            formView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            formView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            formView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            formView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            formView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // 카드가 키보드만큼 줄어든 뒤에 입력 중인 칸이 보이도록 스크롤합니다.
    private func configureKeyboardScroll() {
        formView.onBeginEditing = { [weak self] editingView in
            DispatchQueue.main.async {
                self?.scroll(toVisible: editingView)
            }
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidChangeFrame),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
    }

    @objc
    private func keyboardDidChangeFrame() {
        guard let editingView = formView.editingView else {
            return
        }
        scroll(toVisible: editingView)
    }

    private func scroll(toVisible editingView: UIView) {
        layoutIfNeeded()
        let rect = editingView.convert(editingView.bounds, to: scrollView).insetBy(dx: 0, dy: -12)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionAddItemView {
    var closeTap: ControlEvent<Void> {
        base.headerView.closeButton.rx.tap
    }
}
