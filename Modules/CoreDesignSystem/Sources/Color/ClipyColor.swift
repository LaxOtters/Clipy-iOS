//
//  ClipyColor.swift
//  Clipy
//
//  Created by 박민서 on 7/15/26.
//

import UIKit

public enum ClipyColor {
    /// Figma에서 가져온 원본 색상 값이며, 컴포넌트 역할별 의미는 포함하지 않습니다.
    public enum Foundation {
        public static let primary50 = UIColor(clipyHex: 0xFFFFFF)
        public static let primary100 = UIColor(clipyHex: 0xF9F9FE)
        public static let primary150 = UIColor(clipyHex: 0xF4F2FD)
        public static let primary200 = UIColor(clipyHex: 0xCFCCF8)
        public static let primary300 = UIColor(clipyHex: 0xA49FF2)
        public static let primary400 = UIColor(clipyHex: 0x7A73EB)
        public static let primary500 = UIColor(clipyHex: 0x4F46E5)
        public static let primary600 = UIColor(clipyHex: 0x291FD9)
        public static let primary700 = UIColor(clipyHex: 0x2118AD)
        public static let primary800 = UIColor(clipyHex: 0x181280)
        public static let primary900 = UIColor(clipyHex: 0x100C53)

        public static let accent50 = UIColor(clipyHex: 0xFFFFFF)
        public static let accent100 = UIColor(clipyHex: 0xD6F7F3)
        public static let accent200 = UIColor(clipyHex: 0xACEEE6)
        public static let accent300 = UIColor(clipyHex: 0x82E5D9)
        public static let accent400 = UIColor(clipyHex: 0x57DDCC)
        public static let accent500 = UIColor(clipyHex: 0x2DD4BF)
        public static let accent600 = UIColor(clipyHex: 0x23AB9A)
        public static let accent700 = UIColor(clipyHex: 0x1A8174)
        public static let accent800 = UIColor(clipyHex: 0x12564E)
        public static let accent900 = UIColor(clipyHex: 0x092C28)

        public static let neutral50 = UIColor(clipyHex: 0xFAFAFA)
        public static let neutral100 = UIColor(clipyHex: 0xF4F4F5)
        public static let neutral200 = UIColor(clipyHex: 0xE4E4E7)
        public static let neutral300 = UIColor(clipyHex: 0xD4D4D8)
        public static let neutral400 = UIColor(clipyHex: 0xA1A1AA)
        public static let neutral500 = UIColor(clipyHex: 0x71717A)
        public static let neutral600 = UIColor(clipyHex: 0x52525B)
        public static let neutral700 = UIColor(clipyHex: 0x3F3F46)
        public static let neutral800 = UIColor(clipyHex: 0x27272A)
        public static let neutral900 = UIColor(clipyHex: 0x18181B)
        public static let neutral950 = UIColor(clipyHex: 0x09090B)

        public static let error100 = UIColor(clipyHex: 0xFFDAD6)
        public static let error700 = UIColor(clipyHex: 0xBA1A1A)

        public static let alphaWhite20 = UIColor(clipyHex: 0xFFFFFF, alpha: 0.2)
        public static let alphaWhite70 = UIColor(clipyHex: 0xFFFFFF, alpha: 0.7)
        public static let alphaWhite0Point2 = UIColor(clipyHex: 0xFFFFFF, alpha: 0.002)
        public static let alphaWhite10 = UIColor(clipyHex: 0xFFFFFF, alpha: 0.1)
        public static let alphaBlack20 = UIColor(clipyHex: 0x000000, alpha: 0.2)
        public static let alphaBlack60 = UIColor(clipyHex: 0x000000, alpha: 0.6)
        public static let alphaBlack15 = UIColor(clipyHex: 0x000000, alpha: 0.15)
        public static let overlayBackground = UIColor(clipyHex: 0x000000, alpha: 0.2)
    }
}
