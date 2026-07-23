//
//  ClipyActionMenuItem.swift
//  Clipy
//
//  Created by 박민서 on 7/23/26.
//

import UIKit

/// Action Menu 한 줄에 표시할 내용과 사용자가 선택했을 때 실행할 action을 묶습니다.
public struct ClipyActionMenuItem {
    public enum Role {
        case normal
        case destructive
    }

    let title: String
    let image: UIImage
    let role: Role
    let action: () -> Void

    /// action은 메뉴가 살아 있는 동안 유지되며, 실행 뒤 메뉴를 자동으로 닫지 않습니다.
    /// 메뉴를 소유한 객체를 capture할 때는 순환 참조가 생기지 않게 합니다.
    public init(
        title: String,
        image: UIImage,
        role: Role = .normal,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.image = image.withRenderingMode(.alwaysTemplate)
        self.role = role
        self.action = action
    }
}
