//
//  SessionItemFormView.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit

import CoreDesignSystem

/// 상품 입력 카드 본문입니다. 이미지 영역과 입력 칸을 Figma 순서로 쌓고 처음 값을 채웁니다.
/// 입력값은 각 컨트롤이 들고 있고, 이 view는 글자 수 표시만 입력에 맞춰 바꿉니다.
final class SessionItemFormView: UIView {
    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let headerSpacing: CGFloat = 10
        static let noteHeight: CGFloat = 180
    }

    /// 입력을 시작한 칸을 알려, 카드가 그 칸을 키보드 위로 스크롤할 수 있게 합니다.
    var onBeginEditing: ((UIView) -> Void)?
    private weak var lastEditingView: UIView?

    private let contentStackView = UIStackView()
    private let imageSection = SessionItemImageSection()
    private let urlField = ClipyTextField(leadingIcon: ClipyIcon.link)
    private let productNameHeader = ClipyFieldHeader(
        title: "Product Name",
        characterLimit: SessionItemFormValues.productNameLimit
    )
    private let productNameField = ClipyTextField()
    private let priceField = ClipyTextField()
    private let currencySelector: SessionItemCurrencySelector
    private let statusSelector: SessionItemStatusSelector
    private let noteHeader = ClipyFieldHeader(title: "Note Content", characterLimit: SessionItemFormValues.noteLimit)
    private let noteView = ClipyTextView(placeholder: "Add comparison notes or decision reasons")

    init(values: SessionItemFormValues) {
        currencySelector = SessionItemCurrencySelector(selectedCurrency: values.currency)
        statusSelector = SessionItemStatusSelector(selectedStatus: values.status)
        super.init(frame: .zero)
        configureHierarchy()
        configureContent(values: values)
        configureLayout()
        configureEditingEvents()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func configureHierarchy() {
        addSubview(contentStackView)
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = Layout.sectionSpacing

        let imageRow = UIView()
        imageRow.addSubview(imageSection)
        imageSection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageSection.topAnchor.constraint(equalTo: imageRow.topAnchor),
            imageSection.bottomAnchor.constraint(equalTo: imageRow.bottomAnchor),
            imageSection.centerXAnchor.constraint(equalTo: imageRow.centerXAnchor)
        ])

        [
            imageRow,
            section(header: ClipyFieldHeader(title: "URL", isRequired: true), content: urlField),
            section(header: productNameHeader, content: productNameField),
            section(header: ClipyFieldHeader(title: "Price"), content: priceField),
            section(header: ClipyFieldHeader(title: "Status"), content: statusSelector),
            section(header: noteHeader, content: noteView)
        ].forEach(contentStackView.addArrangedSubview)
    }

    private func configureContent(values: SessionItemFormValues) {
        urlField.text = values.urlText
        urlField.keyboardType = .URL
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no

        productNameField.text = values.productName
        productNameField.placeholder = "Product name"

        priceField.text = values.priceText
        priceField.placeholder = "0"
        priceField.keyboardType = .decimalPad
        priceField.rightView = currencySelector
        priceField.rightViewMode = .always

        noteView.text = values.note
        updateCounts()
    }

    private func configureLayout() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.sectionSpacing),
            noteView.heightAnchor.constraint(equalToConstant: Layout.noteHeight)
        ])
    }

    private func configureEditingEvents() {
        [urlField, productNameField, priceField].forEach { field in
            field.addAction(UIAction { [weak self, weak field] _ in
                guard let field else { return }
                self?.beginEditing(field)
            }, for: .editingDidBegin)
            field.addAction(UIAction { [weak self] _ in self?.updateCounts() }, for: .editingChanged)
        }

        // 공용 여러 줄 입력 칸은 delegate를 비워 두므로, 편집 시작과 변경은 알림으로 받습니다.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(noteDidBeginEditing),
            name: UITextView.textDidBeginEditingNotification,
            object: noteView
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(noteDidChange),
            name: UITextView.textDidChangeNotification,
            object: noteView
        )
    }

    @objc
    private func noteDidBeginEditing() {
        beginEditing(noteView)
    }

    @objc
    private func noteDidChange() {
        updateCounts()
    }

    private func beginEditing(_ view: UIView) {
        lastEditingView = view
        onBeginEditing?(view)
    }

    // 입력을 자르지 않으므로 제한을 넘으면 `51 / 50`처럼 넘친 숫자가 보입니다. 오류 표시는 입력값 검증이 붙을 때 더합니다.
    private func updateCounts() {
        productNameHeader.updateCharacterCount(productNameField.text?.count ?? 0)
        noteHeader.updateCharacterCount(noteView.text.count)
    }

    private func section(header: UIView, content: UIView) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [header, content])
        stackView.axis = .vertical
        stackView.spacing = Layout.headerSpacing
        return stackView
    }
}

// MARK: - Interface

extension SessionItemFormView {
    /// 마지막으로 입력을 시작한 칸입니다. 입력이 끝나도 비우지 않습니다.
    var editingView: UIView? {
        lastEditingView
    }
}
