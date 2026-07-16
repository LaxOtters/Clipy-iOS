//
//  ClipyTypography.swift
//  Clipy
//
//  Created by 박민서 on 7/16/26.
//

import UIKit

public enum ClipyTypography {
    public static var heading1: ClipyTextStyle { style(.bold, size: 28, lineHeight: 38, letterSpacing: -0.6) }
    public static var heading2: ClipyTextStyle { style(.bold, size: 24, lineHeight: 34, letterSpacing: -0.4) }
    public static var heading3: ClipyTextStyle { style(.bold, size: 20, lineHeight: 30, letterSpacing: -0.2) }
    public static var heading4: ClipyTextStyle { style(.semiBold, size: 18, lineHeight: 28) }

    public static var body1SemiBold: ClipyTextStyle { style(.semiBold, size: 16, lineHeight: 24) }
    public static var body1Medium: ClipyTextStyle { style(.medium, size: 16, lineHeight: 24) }
    public static var body1Regular: ClipyTextStyle { style(.regular, size: 16, lineHeight: 24) }
    public static var body2SemiBold: ClipyTextStyle { style(.semiBold, size: 14, lineHeight: 20) }
    public static var body2Medium: ClipyTextStyle { style(.medium, size: 14, lineHeight: 20) }
    public static var body2Regular: ClipyTextStyle { style(.regular, size: 14, lineHeight: 20) }
    public static var body3Bold: ClipyTextStyle { style(.bold, size: 12, lineHeight: 16) }
    public static var body3SemiBold: ClipyTextStyle { style(.semiBold, size: 12, lineHeight: 16) }
    public static var body3Medium: ClipyTextStyle { style(.medium, size: 12, lineHeight: 16) }
    public static var body3Regular: ClipyTextStyle { style(.regular, size: 12, lineHeight: 16) }

    public static var tag1Bold: ClipyTextStyle { style(.bold, size: 10, lineHeight: 15, letterSpacing: 0.8) }
    public static var tag2Bold: ClipyTextStyle { style(.bold, size: 8, lineHeight: 10, letterSpacing: 0.6) }

    private static func style(
        _ weight: PretendardWeight,
        size: CGFloat,
        lineHeight: CGFloat,
        letterSpacing: CGFloat = 0
    ) -> ClipyTextStyle {
        let font = ClipyFontRegistry.font(
            postScriptName: weight.postScriptName,
            size: size,
            fallbackWeight: weight.systemWeight
        )

        return ClipyTextStyle(
            font: font,
            lineHeight: lineHeight,
            letterSpacing: letterSpacing
        )
    }
}

private enum PretendardWeight {
    case regular
    case medium
    case semiBold
    case bold

    var postScriptName: String {
        switch self {
        case .regular:
            return "Pretendard-Regular"
        case .medium:
            return "Pretendard-Medium"
        case .semiBold:
            return "Pretendard-SemiBold"
        case .bold:
            return "Pretendard-Bold"
        }
    }

    var systemWeight: UIFont.Weight {
        switch self {
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semiBold:
            return .semibold
        case .bold:
            return .bold
        }
    }
}
