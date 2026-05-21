//
//  SessionBottomSheetState.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

/// Session 안에서 Bottom Sheet primitive가 가질 수 있는 노출 상태입니다.
enum SessionBottomSheetState: Equatable, CaseIterable {
    case hidden
    case peek
    case expanded
}
