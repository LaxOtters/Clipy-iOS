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
    static func original(named name: String) -> UIImage? {
        guard let image = UIImage(
            named: name,
            in: CoreDesignSystemResourceBundle.module,
            compatibleWith: nil
        ) else {
            // Debug에서는 asset 누락을 바로 드러내고, Release에서는 해당 이미지 영역만 생략합니다.
            assertionFailure("Missing required CoreDesignSystem image: \(name)")
            return nil
        }

        // Asset 색을 그대로 써야 하므로 UIKit의 template tint를 타지 않게 둡니다.
        return image.withRenderingMode(.alwaysOriginal)
    }
}
