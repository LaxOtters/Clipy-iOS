//
//  ClipyActionMenuAnimation.swift
//  Clipy
//
//  Created by 박민서 on 7/23/26.
//

import Foundation

/// Action Menu의 표시·숨김 전환 방식과 시간을 담는 설정입니다.
public struct ClipyActionMenuAnimation {
    public enum Style {
        case fade
        case fadeAndScale
        case none
    }

    /// `.fadeAndScale`, 0.16초를 사용하는 기본 설정입니다.
    public static let standard = ClipyActionMenuAnimation(
        validatedStyle: .fadeAndScale,
        validatedDuration: 0.16
    )

    public let style: Style
    public let duration: TimeInterval

    /// duration은 유한한 0 이상 값만 받습니다.
    /// 0이나 `.none`이면 표시·숨김 상태를 즉시 반영합니다.
    public init?(style: Style = .fadeAndScale, duration: TimeInterval = 0.16) {
        guard duration.isFinite, duration >= 0 else {
            return nil
        }

        self.init(validatedStyle: style, validatedDuration: duration)
    }

    private init(validatedStyle style: Style, validatedDuration duration: TimeInterval) {
        self.style = style
        self.duration = duration
    }
}

extension ClipyActionMenuAnimation {
    var canAnimate: Bool {
        switch style {
        case .none:
            false
        case .fade, .fadeAndScale:
            true
        }
    }
}
