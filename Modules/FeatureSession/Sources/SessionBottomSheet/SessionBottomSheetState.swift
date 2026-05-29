//
//  SessionBottomSheetState.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

/// Session 안에서 Bottom Sheet primitive가 가질 수 있는 노출 상태입니다.
enum SessionBottomSheetState: Equatable, CaseIterable {
    /// URL bar만 남기는 가장 낮은 노출 상태입니다.
    case minimized
    /// URL bar와 sheet 진입 단서가 보이는 낮은 노출 상태입니다.
    case hidden
    /// item 가로 스크롤 영역까지 보이는 기본 탐색 상태입니다.
    case peek
    /// Bottom Sheet가 화면 전체 높이를 채우는 비교 상태입니다.
    case expanded
}
