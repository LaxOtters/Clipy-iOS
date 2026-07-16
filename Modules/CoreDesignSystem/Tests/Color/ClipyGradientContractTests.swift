//
//  ClipyGradientContractTests.swift
//  Clipy
//
//  Created by 박민서 on 7/16/26.
//

import UIKit
import XCTest

import CoreDesignSystem

final class ClipyGradientContractTests: XCTestCase {
    func test_foundationGradients_renderFigmaStopsLocationsOpacityAndDirection() {
        assertGradient(
            Gradient.linear,
            stops: [
                .init(hex: 0x4A40E0, location: 0),
                .init(hex: 0xC3C0FF, location: 1)
            ],
            start: .init(x: 0.2091, y: -1.2768),
            end: .init(x: 0.7909, y: 2.2768)
        )
        assertGradient(
            Gradient.linearWhite,
            stops: [
                .init(hex: 0xFBF8FF, alpha: 0.7, location: 0),
                .init(hex: 0xFBF8FF, alpha: 0, location: 1)
            ],
            start: .init(x: 0.5, y: 1),
            end: .init(x: 0.5, y: 0)
        )
        assertGradient(
            Gradient.linearMint,
            stops: [
                .init(hex: 0x4051E0, location: 0),
                .init(hex: 0x8680EF, location: 0.44150421),
                .init(hex: 0xD6F7F3, location: 1)
            ],
            start: .init(x: -0.0307, y: -0.5619),
            end: .init(x: 1.0614, y: 1.2525)
        )
        assertGradient(
            Gradient.linearBlack,
            stops: [
                .init(hex: 0x1A1A2E, alpha: 0.2, location: 0),
                .init(hex: 0xC4C4C4, alpha: 0.4, location: 1)
            ],
            start: .init(x: 0, y: 1),
            end: .init(x: 1, y: 0)
        )
    }

    private func assertGradient(
        _ gradient: ClipyGradient,
        stops expectedStops: [ExpectedStop],
        start: CGPoint,
        end: CGPoint,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let layer = CAGradientLayer()
        layer.opacity = 0.37
        layer.cornerRadius = 12
        gradient.apply(to: layer)

        XCTAssertEqual(layer.type, .axial, file: file, line: line)
        XCTAssertEqual(layer.opacity, 0.37, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(layer.cornerRadius, 12, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(layer.startPoint.x, start.x, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(layer.startPoint.y, start.y, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(layer.endPoint.x, end.x, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(layer.endPoint.y, end.y, accuracy: 0.000001, file: file, line: line)

        let colors = (layer.colors as? [CGColor]) ?? []
        let locations = layer.locations ?? []
        XCTAssertEqual(colors.count, expectedStops.count, file: file, line: line)
        XCTAssertEqual(locations.count, expectedStops.count, file: file, line: line)

        zip(zip(colors, locations), expectedStops).forEach { pair, expected in
            let (color, location) = pair
            XCTAssertEqual(location.doubleValue, Double(expected.location), accuracy: 0.000001, file: file, line: line)
            assertColor(UIColor(cgColor: color), equals: expected, file: file, line: line)
        }
    }

    private func assertColor(
        _ color: UIColor,
        equals expected: ExpectedStop,
        file: StaticString,
        line: UInt
    ) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha), file: file, line: line)
        XCTAssertEqual(red, CGFloat((expected.hex >> 16) & 0xFF) / 255, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(green, CGFloat((expected.hex >> 8) & 0xFF) / 255, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(blue, CGFloat(expected.hex & 0xFF) / 255, accuracy: 0.000001, file: file, line: line)
        XCTAssertEqual(alpha, expected.alpha, accuracy: 0.000001, file: file, line: line)
    }
}

private typealias Gradient = ClipyGradient.Foundation

private struct ExpectedStop {
    let hex: UInt32
    let alpha: CGFloat
    let location: CGFloat

    init(hex: UInt32, alpha: CGFloat = 1, location: CGFloat) {
        self.hex = hex
        self.alpha = alpha
        self.location = location
    }
}
