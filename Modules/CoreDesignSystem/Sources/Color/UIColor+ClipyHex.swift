//
//  UIColor+ClipyHex.swift
//  Clipy
//
//  Created by 박민서 on 7/15/26.
//

import UIKit

extension UIColor {
    convenience init(clipyHex hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
