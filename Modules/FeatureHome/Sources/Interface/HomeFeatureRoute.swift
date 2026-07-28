//
//  HomeFeatureRoute.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import Foundation

/// 저장이 끝난 새 Session으로 이동할 때 Home이 AppMain에 전달하는 값입니다.
public enum HomeFeatureRoute: Equatable {
    case session(UUID)
}
