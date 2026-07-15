//
//  CoreDesignSystemResourceBundle.swift
//  Clipy
//
//  Created by 박민서 on 7/15/26.
//

import Foundation

enum CoreDesignSystemResourceBundle {
    static let module = Bundle(for: BundleFinder.self)
}

// Tuist가 생성하는 Bundle accessor 없이 framework resource를 찾을 때 사용하는 marker class입니다.
private final class BundleFinder {}
