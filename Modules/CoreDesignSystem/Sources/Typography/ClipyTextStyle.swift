//
//  ClipyTextStyle.swift
//  Clipy
//
//  Created by 박민서 on 7/16/26.
//

import UIKit

public struct ClipyTextStyle {
    public let font: UIFont
    public let lineHeight: CGFloat
    public let letterSpacing: CGFloat

    /// 이 style의 `font`, `lineHeight`, `letterSpacing`을 적용한 attributed string을 만듭니다.
    /// `color`가 nil이면 foreground color는 지정하지 않습니다.
    public func attributedString(
        _ text: String,
        color: UIColor? = nil,
        alignment: NSTextAlignment = .natural,
        lineBreakMode: NSLineBreakMode = .byWordWrapping
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = lineBreakMode

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: letterSpacing,
            .paragraphStyle: paragraphStyle
        ]
        attributes[.foregroundColor] = color

        return NSAttributedString(string: text, attributes: attributes)
    }

    /// label의 현재 문자열·색상·정렬·줄바꿈을 기준으로 style을 적용하며, `text`·`color`를 넘기면 기존 값을 바꿉니다.
    /// `color`는 UIKit 동작에 따라 attributed foreground color와 `label.textColor`에 반영되고, 생략하면 현재 색상을 유지합니다. 정렬·줄바꿈은 바꾸지 않습니다.
    public func apply(
        to label: UILabel,
        text: String? = nil,
        color: UIColor? = nil
    ) {
        let textColor = label.textColor
        let textAlignment = label.textAlignment
        let lineBreakMode = label.lineBreakMode
        let resolvedText = text ?? label.attributedText?.string ?? label.text ?? ""
        let resolvedColor = color ?? textColor

        label.font = font
        label.attributedText = attributedString(
            resolvedText,
            color: resolvedColor,
            alignment: textAlignment,
            lineBreakMode: lineBreakMode
        )
        label.textAlignment = textAlignment
        label.lineBreakMode = lineBreakMode
    }
}
