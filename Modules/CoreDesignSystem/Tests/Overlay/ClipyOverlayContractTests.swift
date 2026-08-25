//
//  ClipyOverlayContractTests.swift
//  Clipy
//
//  Created by 박민서 on 8/21/26.
//

import UIKit
import XCTest

@testable import CoreDesignSystem

@MainActor
final class ClipyOverlayContractTests: XCTestCase {
    func test_websiteRequestDialog_usesPrimary500_withoutChangingPlainDialogPrimaryColor() throws {
        let plainDialog = ClipyDialogView(
            configuration: .message(
                presentation: .plain,
                title: "Continue?",
                body: "The current page is requesting confirmation.",
                buttons: .single(title: "Continue")
            ),
            onSelection: { _, _ in }
        )
        let websiteDialog = ClipyDialogView(
            configuration: .message(
                presentation: .websiteRequest(sourceText: "example.com"),
                title: "Continue?",
                body: "The current page is requesting confirmation.",
                buttons: .single(title: "Continue")
            ),
            onSelection: { _, _ in }
        )
        let plainButton = try plainDialog.button(titled: "Continue")
        let websiteButton = try websiteDialog.button(titled: "Continue")

        assertColor(
            plainButton.configuration?.background.backgroundColor,
            equals: ClipyColor.Foundation.primary400
        )
        assertColor(
            websiteButton.configuration?.background.backgroundColor,
            equals: ClipyColor.Foundation.primary500
        )
    }

    func test_promptDialogButtons_returnCurrentTextSnapshotAndSelectedPosition() throws {
        var selections: [(ClipyDialog.Selection, String?)] = []
        let configuration = ClipyDialog.Configuration.prompt(
            presentation: .plain,
            title: "Enter a value",
            body: "This site is requesting input.",
            initialText: "Initial",
            placeholder: "Value",
            primaryTitle: "Confirm",
            secondaryTitle: "Cancel"
        )
        let secondaryDialog = ClipyDialogView(configuration: configuration) {
            selections.append(($0, $1))
        }
        let primaryDialog = ClipyDialogView(configuration: configuration) {
            selections.append(($0, $1))
        }

        try XCTUnwrap(secondaryDialog.firstDescendant(of: UITextField.self)).text = "Edited"
        try secondaryDialog.button(titled: "Cancel").sendActions(for: .touchUpInside)
        try XCTUnwrap(primaryDialog.firstDescendant(of: UITextField.self)).text = "Edited"
        try primaryDialog.button(titled: "Confirm").sendActions(for: .touchUpInside)

        XCTAssertEqual(selections.map(\.0), [.secondary, .primary])
        XCTAssertEqual(selections.map(\.1), ["Edited", "Edited"])
    }

    func test_errorContentAction_invokesProvidedCallback() throws {
        var actionCount = 0
        let errorContent = ClipyErrorContentView(
            title: "Couldn’t load this page",
            body: "Try again.",
            action: .init(title: "Try again") { actionCount += 1 }
        )

        try errorContent.button(titled: "Try again").sendActions(for: .touchUpInside)

        XCTAssertEqual(actionCount, 1)
    }

    func test_shortSnackbarAction_reservesNonOverlappingMinimumTouchWidth() throws {
        let snackbar = ClipySnackbarView(
            message: "Couldn’t load this page.",
            action: .init(title: "X") {},
            onDismiss: {}
        )
        let fittingSize = snackbar.systemLayoutSizeFitting(
            CGSize(width: 349, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        snackbar.frame = CGRect(origin: .zero, size: fittingSize)
        snackbar.layoutIfNeeded()

        let actionButton = try snackbar.button(titled: "X")
        let actionFrame = actionButton.convert(actionButton.bounds, to: snackbar)
        let messageLabel = try XCTUnwrap(
            snackbar.descendants(of: UILabel.self).first {
                $0.attributedText?.string == "Couldn’t load this page."
            }
        )
        let messageFrame = messageLabel.convert(messageLabel.bounds, to: snackbar)

        XCTAssertGreaterThanOrEqual(actionFrame.width, 44)
        XCTAssertLessThanOrEqual(messageFrame.maxX, actionFrame.minX)
    }

    func test_explicitLineBreakSnackbar_fittingSizeContainsMessageAndAction() throws {
        let message = "First line\nSecond line"
        let snackbar = ClipySnackbarView(
            message: message,
            action: .init(title: "Try again") {},
            onDismiss: {}
        )
        let fittingSize = snackbar.systemLayoutSizeFitting(
            CGSize(width: 349, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        snackbar.frame = CGRect(origin: .zero, size: fittingSize)
        snackbar.layoutIfNeeded()

        let actionButton = try snackbar.button(titled: "Try again")
        let messageLabel = try XCTUnwrap(
            snackbar.descendants(of: UILabel.self).first {
                $0.attributedText?.string == message
            }
        )
        let actionFrame = actionButton.convert(actionButton.bounds, to: snackbar)
        let messageFrame = messageLabel.convert(messageLabel.bounds, to: snackbar)

        XCTAssertLessThanOrEqual(messageFrame.maxY, actionFrame.minY)
        XCTAssertLessThanOrEqual(actionFrame.maxY, snackbar.bounds.maxY)
    }

    func test_widthOverflowSnackbar_firstHostLayoutContainsMessageAndAction() throws {
        let hostView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let snackbar = ClipySnackbarView(
            message: "Couldn’t load this page.",
            action: .init(title: "Try again") {},
            onDismiss: {}
        )
        snackbar.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(snackbar)
        NSLayoutConstraint.activate([
            snackbar.topAnchor.constraint(equalTo: hostView.topAnchor),
            snackbar.centerXAnchor.constraint(equalTo: hostView.centerXAnchor),
            snackbar.widthAnchor.constraint(equalToConstant: 280)
        ])

        hostView.layoutIfNeeded()

        let firstLayoutHeight = snackbar.bounds.height
        let actionButton = try snackbar.button(titled: "Try again")
        let messageLabel = try XCTUnwrap(
            snackbar.descendants(of: UILabel.self).first {
                $0.attributedText?.string == "Couldn’t load this page."
            }
        )
        let actionFrame = actionButton.convert(actionButton.bounds, to: snackbar)
        let messageFrame = messageLabel.convert(messageLabel.bounds, to: snackbar)

        XCTAssertLessThanOrEqual(messageFrame.maxY, actionFrame.minY)
        XCTAssertLessThanOrEqual(actionFrame.maxY, snackbar.bounds.maxY)

        hostView.layoutIfNeeded()
        XCTAssertEqual(snackbar.bounds.height, firstLayoutHeight)
    }

}

private extension UIView {
    func button(titled title: String) throws -> UIButton {
        try XCTUnwrap(
            descendants(of: UIButton.self).first { button in
                button.configuration?.attributedTitle.map { String($0.characters) } == title
                    || button.attributedTitle(for: .normal)?.string == title
                    || button.title(for: .normal) == title
            }
        )
    }

    func firstDescendant<View: UIView>(of type: View.Type) -> View? {
        descendants(of: type).first
    }

    func descendants<View: UIView>(of type: View.Type) -> [View] {
        subviews.flatMap { subview in
            [subview as? View].compactMap { $0 } + subview.descendants(of: type)
        }
    }
}
