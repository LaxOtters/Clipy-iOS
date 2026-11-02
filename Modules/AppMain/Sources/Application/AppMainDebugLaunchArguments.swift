//
//  AppMainDebugLaunchArguments.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import Foundation

/// Debug 빌드에서 시뮬레이터 확인용으로 받는 실행 인자를 읽습니다.
/// Release 빌드에서는 항상 인자가 없는 것처럼 동작합니다.
enum AppMainDebugLaunchArguments {
    /// `-ClipyDebugSessionStartURL <url>`로 실행하면 새 Session이 기본 주소 대신 이 주소에서 시작합니다.
    static var sessionStartURL: URL? {
        #if DEBUG
            UserDefaults.standard.string(forKey: "ClipyDebugSessionStartURL").flatMap(URL.init(string:))
        #else
            nil
        #endif
    }
}
