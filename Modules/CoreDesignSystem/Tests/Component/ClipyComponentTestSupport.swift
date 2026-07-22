//
//  ClipyComponentTestSupport.swift
//  Clipy
//
//  Created by 박민서 on 7/22/26.
//

import UIKit
import XCTest

func render(_ view: UIView, size: CGSize, scale: CGFloat = 2) -> UIImage {
    view.frame = CGRect(origin: .zero, size: size)
    view.setNeedsLayout()
    view.layoutIfNeeded()

    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false
    return UIGraphicsImageRenderer(size: size, format: format).image { context in
        view.layer.render(in: context.cgContext)
    }
}

func renderedColor(in image: UIImage, at point: CGPoint) -> UIColor {
    guard let cgImage = image.cgImage else {
        XCTFail("Expected rendered image to expose CGImage pixels.")
        return .clear
    }

    let pixelX = min(max(Int(point.x * image.scale), 0), cgImage.width - 1)
    let pixelY = min(max(Int(point.y * image.scale), 0), cgImage.height - 1)
    guard let pixel = cgImage.cropping(to: CGRect(x: pixelX, y: pixelY, width: 1, height: 1)) else {
        XCTFail("Expected the requested render point to produce a pixel sample.")
        return .clear
    }

    var components = [UInt8](repeating: 0, count: 4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: &components,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        XCTFail("Expected a bitmap context for rendered color inspection.")
        return .clear
    }
    context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))

    let alpha = CGFloat(components[3]) / 255
    guard alpha > 0 else {
        return .clear
    }

    return UIColor(
        red: CGFloat(components[0]) / 255 / alpha,
        green: CGFloat(components[1]) / 255 / alpha,
        blue: CGFloat(components[2]) / 255 / alpha,
        alpha: alpha
    )
}

func assertRenderedColor(
    _ image: UIImage,
    at point: CGPoint,
    equals expected: UIColor,
    accuracy: CGFloat = 0.01,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let actual = renderedColor(in: image, at: point)
    assertColor(actual, equals: expected, accuracy: accuracy, file: file, line: line)
}

func renderedVerticalSpan(in image: UIImage, atX pointX: CGFloat) -> CGFloat {
    let activePixels = (0..<Int(image.size.height * image.scale)).filter { pixelY in
        let point = CGPoint(x: pointX, y: CGFloat(pixelY) / image.scale)
        return renderedColor(in: image, at: point).cgColor.alpha > 0.5
    }.count
    return CGFloat(activePixels) / image.scale
}

func colorsAreEqual(_ lhs: UIColor, _ rhs: UIColor, accuracy: CGFloat = 0.01) -> Bool {
    rgba(lhs).enumerated().allSatisfy { index, value in
        abs(value - rgba(rhs)[index]) <= accuracy
    }
}

func assertColor(
    _ actual: UIColor?,
    equals expected: UIColor,
    accuracy: CGFloat = 0.000001,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertNotNil(actual, file: file, line: line)
    let actualComponents = rgba(actual ?? .clear)
    let expectedComponents = rgba(expected)

    zip(actualComponents, expectedComponents).forEach { actualValue, expectedValue in
        XCTAssertEqual(actualValue, expectedValue, accuracy: accuracy, file: file, line: line)
    }
}

func assertTitleColor(
    _ button: UIButton,
    equals expected: UIColor,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    assertColor(button.titleColor(for: .normal), equals: expected, file: file, line: line)
}

private func rgba(_ color: UIColor) -> [CGFloat] {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
        XCTFail("Expected an RGB-compatible color.")
        return [.nan, .nan, .nan, .nan]
    }
    return [red, green, blue, alpha]
}
