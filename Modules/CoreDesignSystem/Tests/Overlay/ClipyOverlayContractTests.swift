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
    func test_websiteRequestButton_usesPrimary500_withoutChangingPublicPrimaryVariant() {
        let publicButton = ClipyButton(variant: .primaryMedium, title: "Continue")
        let websiteButton = ClipyButton(
            variant: .primaryMedium,
            title: "Continue",
            colorRole: .primary500
        )

        assertColor(
            publicButton.configuration?.background.backgroundColor,
            equals: ClipyColor.Foundation.primary400
        )
        assertColor(
            websiteButton.configuration?.background.backgroundColor,
            equals: ClipyColor.Foundation.primary500
        )
    }

    func test_promptDialogButtons_returnCurrentTextSnapshotAndSelectedPosition() throws {
        var selections: [(ClipyDialog.Selection, String?)] = []
        let dialog = ClipyDialogView(
            configuration: .prompt(
                presentation: .plain,
                title: "Enter a value",
                body: "This site is requesting input.",
                initialText: "Initial",
                placeholder: "Value",
                primaryTitle: "Confirm",
                secondaryTitle: "Cancel"
            )
        ) { selections.append(($0, $1)) }

        let textField = try XCTUnwrap(dialog.firstDescendant(of: UITextField.self))
        textField.text = "Edited"
        try dialog.button(titled: "Cancel").sendActions(for: .touchUpInside)
        try dialog.button(titled: "Confirm").sendActions(for: .touchUpInside)

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
