//
//  ClipyGradientGeometry.swift
//  Clipy
//
//  Created by 박민서 on 7/16/26.
//

import UIKit

// Figma gradientTransform을 UIKit 좌표로 변환한 값입니다.
// Foundation에서는 geometry 이름만 선택하고 좌표를 직접 관리하지 않습니다.
enum ClipyGradientGeometry {
    case linear
    case linearWhite
    case linearMint
    case linearBlack

    var startPoint: CGPoint {
        switch self {
        case .linear:
            return CGPoint(x: 0.2091, y: -1.2768)
        case .linearWhite:
            return CGPoint(x: 0.5, y: 1)
        case .linearMint:
            return CGPoint(x: -0.0307, y: -0.5619)
        case .linearBlack:
            return CGPoint(x: 0, y: 1)
        }
    }

    var endPoint: CGPoint {
        switch self {
        case .linear:
            return CGPoint(x: 0.7909, y: 2.2768)
        case .linearWhite:
            return CGPoint(x: 0.5, y: 0)
        case .linearMint:
            return CGPoint(x: 1.0614, y: 1.2525)
        case .linearBlack:
            return CGPoint(x: 1, y: 0)
        }
    }
}
