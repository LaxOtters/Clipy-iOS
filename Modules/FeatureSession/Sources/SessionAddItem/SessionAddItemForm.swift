//
//  SessionAddItemForm.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import Foundation

/// Add Item 카드를 열 때 채울 처음 값입니다.
enum SessionAddItemForm {
    /// 현재 페이지가 없으면 URL을 비워 두고 사용자가 직접 입력하게 합니다.
    static func initialValues(currentPageURL: URL?) -> SessionItemFormValues {
        SessionItemFormValues(
            urlText: currentPageURL?.absoluteString ?? "",
            productName: "",
            priceText: "",
            currency: .krw,
            note: "",
            status: .interested
        )
    }
}
