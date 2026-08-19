//
//  CoreDesignSystemImage.swift
//  Clipy
//
//  Created by 박민서 on 8/20/26.
//

import UIKit

enum CoreDesignSystemImage {
    static let errorRounded = original(named: "clipy_image_error_rounded")
    static let dialogRequestSource = original(named: "clipy_image_dialog_request_source")
}

private extension CoreDesignSystemImage {
    static func original(named name: String) -> UIImage {
        guard let image = UIImage(
            named: name,
            in: CoreDesignSystemResourceBundle.module,
            compatibleWith: nil
        ) else {
            preconditionFailure("Missing required CoreDesignSystem image: \(name)")
        }

        // Asset 색을 그대로 써야 하므로 UIKit의 template tint를 타지 않게 둡니다.
        return image.withRenderingMode(.alwaysOriginal)
    }
}
