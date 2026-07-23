//
//  ClipyIcon.swift
//  Clipy
//
//  Created by 박민서 on 7/23/26.
//

import UIKit

/// CoreDesignSystem의 UIKit 컴포넌트에서 재사용할 template 아이콘을 제공합니다.
public enum ClipyIcon {
    public static let link = image(named: "clipy_icon_link")
    public static let share = image(named: "clipy_icon_share")
    public static let edit = image(named: "clipy_icon_edit")
    public static let delete = image(named: "clipy_icon_delete")
}

private extension ClipyIcon {
    static func image(named name: String) -> UIImage {
        guard let image = UIImage(named: name, in: CoreDesignSystemResourceBundle.module, compatibleWith: nil) else {
            // Debug에서는 asset 누락을 드러내고, Release에서는 빈 template image로 대체해 앱 실행을 이어갑니다.
            assertionFailure("Missing required CoreDesignSystem asset: \(name)")

            return UIImage().withRenderingMode(.alwaysTemplate)
        }

        return image.withRenderingMode(.alwaysTemplate)
    }
}
