//
//  SessionTopBarState.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

/// 상단 floating bar를 전체로 보여줄지, 접어서 보여줄지 나타냅니다.
enum SessionTopBarState: Equatable {
    case folded
    case unfolded

    var toggled: SessionTopBarState {
        switch self {
        case .folded:
            return .unfolded
        case .unfolded:
            return .folded
        }
    }
}
