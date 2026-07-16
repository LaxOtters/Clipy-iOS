//
//  ClipyGradient.swift
//  Clipy
//
//  Created by 박민서 on 7/16/26.
//

import UIKit

public struct ClipyGradient {
    private struct Stop {
        let color: UIColor
        let location: CGFloat
    }

    private let stops: [Stop]
    private let startPoint: CGPoint
    private let endPoint: CGPoint
    private let opacity: CGFloat

    private init(
        stops: [Stop],
        startPoint: CGPoint,
        endPoint: CGPoint,
        opacity: CGFloat = 1
    ) {
        self.stops = stops
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.opacity = opacity
    }

    /// 이 gradient의 `type`, `colors`, `locations`, `startPoint`, `endPoint`만 덮어씁니다.
    /// `layer.opacity`와 나머지 layer 상태는 유지합니다.
    public func apply(to layer: CAGradientLayer) {
        layer.type = .axial
        layer.colors = stops.map { stop in
            stop.color.withAlphaComponent(stop.color.cgColor.alpha * opacity).cgColor
        }
        layer.locations = stops.map { NSNumber(value: Double($0.location)) }
        layer.startPoint = startPoint
        layer.endPoint = endPoint
    }
}

public extension ClipyGradient {
    /// Figma에서 가져온 원본 gradient 값이며, 컴포넌트 역할별 의미는 포함하지 않습니다.
    enum Foundation {
        public static let linear = make(
            stops: [
                stop(hex: 0x4A40E0, at: 0),
                stop(hex: 0xC3C0FF, at: 100)
            ],
            geometry: .linear
        )

        public static let linearWhite = make(
            stops: [
                stop(hex: 0xFBF8FF, opacity: 70, at: 0),
                stop(hex: 0xFBF8FF, opacity: 0, at: 100)
            ],
            geometry: .linearWhite
        )

        public static let linearMint = make(
            stops: [
                stop(hex: 0x4051E0, at: 0),
                stop(hex: 0x8680EF, at: 44.150421),
                stop(hex: 0xD6F7F3, at: 100)
            ],
            geometry: .linearMint
        )

        public static let linearBlack = make(
            stops: [
                stop(hex: 0x1A1A2E, opacity: 50, at: 0),
                stop(hex: 0xC4C4C4, at: 100)
            ],
            geometry: .linearBlack,
            opacity: 40
        )

        private static func make(
            stops: [ClipyGradient.Stop],
            geometry: ClipyGradientGeometry,
            opacity: CGFloat = 100
        ) -> ClipyGradient {
            ClipyGradient(
                stops: stops,
                startPoint: geometry.startPoint,
                endPoint: geometry.endPoint,
                opacity: opacity / 100
            )
        }

        private static func stop(
            hex: UInt32,
            opacity: CGFloat = 100,
            at location: CGFloat
        ) -> ClipyGradient.Stop {
            ClipyGradient.Stop(
                color: UIColor(clipyHex: hex, alpha: opacity / 100),
                location: location / 100
            )
        }
    }
}
