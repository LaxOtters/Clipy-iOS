//
//  HomeAsset.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import UIKit

enum HomeAsset {
    static let browse = image(named: "HomeBrowse")
    static let collect = image(named: "HomeCollect")
    static let decide = image(named: "HomeDecide")

    private static func image(named name: String) -> UIImage? {
        guard let image = UIImage(named: name, in: HomeResourceBundle.module, compatibleWith: nil) else {
            assertionFailure("Missing required FeatureHome asset: \(name)")
            return nil
        }

        return image
    }
}
