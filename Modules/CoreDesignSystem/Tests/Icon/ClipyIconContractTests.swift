//
//  ClipyIconContractTests.swift
//  Clipy
//
//  Created by 박민서 on 7/23/26.
//

import UIKit
import XCTest

import CoreDesignSystem

final class ClipyIconContractTests: XCTestCase {
    func test_publicIcons_returnFourTemplateImages_readyForComponentTinting() {
        let images = [
            ClipyIcon.link,
            ClipyIcon.share,
            ClipyIcon.edit,
            ClipyIcon.delete
        ]

        images.forEach { image in
            XCTAssertEqual(image.size.width, 16)
            XCTAssertEqual(image.size.height, 16)
            XCTAssertEqual(image.renderingMode, .alwaysTemplate)
        }
    }

    func test_publicIcons_renderDistinctGlyphPayloads_withSharedSizeAndTint() {
        let renderedPayloads = [
            ClipyIcon.link,
            ClipyIcon.share,
            ClipyIcon.edit,
            ClipyIcon.delete
        ].map(renderedPayload)

        for (index, payload) in renderedPayloads.enumerated() {
            for otherPayload in renderedPayloads.dropFirst(index + 1) {
                XCTAssertNotEqual(payload, otherPayload)
            }
        }
    }

    private func renderedPayload(_ image: UIImage) -> Data {
        let imageView = UIImageView(image: image)
        imageView.tintColor = .black
        let renderedImage = render(imageView, size: CGSize(width: 16, height: 16))

        guard let payload = renderedImage.pngData() else {
            XCTFail("Expected rendered icon PNG data.")
            return Data()
        }
        return payload
    }
}
