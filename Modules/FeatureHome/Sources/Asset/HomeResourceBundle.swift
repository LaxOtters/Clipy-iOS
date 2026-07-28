//
//  HomeResourceBundle.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import Foundation

enum HomeResourceBundle {
    static let module = Bundle(for: BundleFinder.self)
}

// Tuist가 만드는 resource accessor 없이 FeatureHome bundle을 찾는 marker class입니다.
private final class BundleFinder {}
