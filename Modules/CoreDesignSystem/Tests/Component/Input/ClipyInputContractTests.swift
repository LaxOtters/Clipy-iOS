//
//  ClipyInputContractTests.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import UIKit
import XCTest

import CoreDesignSystem

final class ClipyInputContractTests: XCTestCase {
    func test_textField_drawsFigmaInputBox_withNeutralBorderAndBody1Text() {
        let field = ClipyTextField()

        XCTAssertEqual(field.intrinsicContentSize.height, 48)
        XCTAssertEqual(field.layer.cornerRadius, 12)
        XCTAssertEqual(field.layer.borderWidth, 1)
        assertColor(field.layer.borderColor.map(UIColor.init(cgColor:)), equals: Palette.neutral200)
        assertColor(field.backgroundColor, equals: Palette.primary50)
        assertColor(field.textColor, equals: Palette.neutral900)
        XCTAssertEqual(field.font?.pointSize, 16)
    }

    func test_textFieldWithIconAndTrailingView_placesTextBetweenThem_withoutOverlap() {
        let field = ClipyTextField(leadingIcon: ClipyIcon.link)
        let trailingButton = UIButton(type: .system)
        trailingButton.setTitle("KRW", for: .normal)
        field.rightView = trailingButton
        field.rightViewMode = .always
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 48)

        let textRect = field.textRect(forBounds: bounds)
        let trailingRect = field.rightViewRect(forBounds: bounds)
        XCTAssertGreaterThan(trailingRect.width, 0)
        XCTAssertGreaterThan(textRect.minX, field.leftViewRect(forBounds: bounds).maxX)
        XCTAssertLessThan(textRect.maxX, trailingRect.minX)
    }

    func test_textFieldPlaceholder_usesNeutralFourHundred() {
        let field = ClipyTextField()
        field.placeholder = "Product name"

        let color = field.attributedPlaceholder?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertEqual(field.placeholder, "Product name")
        assertColor(color, equals: Palette.neutral400)
    }

    func test_textView_sharesInputBox_andShowsPlaceholderOnlyWhileEmpty() {
        let textView = ClipyTextView(placeholder: "Add comparison notes")
        textView.frame = CGRect(x: 0, y: 0, width: 300, height: 120)

        XCTAssertEqual(textView.layer.cornerRadius, 12)
        XCTAssertEqual(textView.layer.borderWidth, 1)
        assertColor(textView.layer.borderColor.map(UIColor.init(cgColor:)), equals: Palette.neutral200)
        XCTAssertTrue(visibleTexts(in: textView).contains("Add comparison notes"))

        textView.text = "Battery lasts 30h"
        XCTAssertFalse(visibleTexts(in: textView).contains("Add comparison notes"))

        textView.text = ""
        XCTAssertTrue(visibleTexts(in: textView).contains("Add comparison notes"))
    }

    func test_fieldHeaderWithLimit_showsCountOverLimit_inFigmaFormat() {
        let header = ClipyFieldHeader(title: "Product Name", characterLimit: 50)

        XCTAssertTrue(visibleTexts(in: header).contains("0 / 50"))

        header.updateCharacterCount(51)
        XCTAssertTrue(visibleTexts(in: header).contains("51 / 50"))
    }

    func test_fieldHeaderWithoutLimit_drawsTitleOnly() {
        let header = ClipyFieldHeader(title: "Status")

        XCTAssertEqual(visibleTexts(in: header), ["Status"])
    }

    func test_requiredFieldHeader_appendsRedAsterisk_toTitle() {
        let header = ClipyFieldHeader(title: "URL", isRequired: true)
        let title = visibleAttributedTexts(in: header).first { $0.string == "URL*" }
        let asteriskColor = title?.attribute(.foregroundColor, at: 3, effectiveRange: nil) as? UIColor

        XCTAssertNotNil(title)
        assertColor(asteriskColor, equals: Palette.red500)
    }

    func test_popupHeader_ownsSixtyPointBar_andOptionalPrimaryAction() {
        let headerWithAction = ClipyPopupHeader(title: "Add item", actionTitle: "Save")
        let headerWithoutAction = ClipyPopupHeader(title: "Item")

        XCTAssertEqual(headerWithAction.intrinsicContentSize.height, 60)
        XCTAssertNotNil(headerWithAction.closeButton.image(for: .normal))
        XCTAssertEqual(headerWithAction.actionButton?.title(for: .normal), "Save")
        XCTAssertNil(headerWithoutAction.actionButton)
        XCTAssertTrue(visibleTexts(in: headerWithoutAction).contains("Item"))
    }
}

private extension ClipyInputContractTests {
    // 화면에 보이는 문자열만 모아, 컴포넌트 안의 view 구성과 상관없이 표시 결과를 확인합니다.
    func visibleTexts(in view: UIView) -> [String] {
        visibleAttributedTexts(in: view).map(\.string)
    }

    func visibleAttributedTexts(in view: UIView) -> [NSAttributedString] {
        guard !view.isHidden else { return [] }
        var texts: [NSAttributedString] = []
        if let label = view as? UILabel, let text = label.attributedText, !text.string.isEmpty {
            texts.append(text)
        }
        return texts + view.subviews.flatMap { visibleAttributedTexts(in: $0) }
    }
}

private typealias Palette = ClipyColor.Foundation
