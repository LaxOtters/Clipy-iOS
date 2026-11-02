//
//  SessionItemFormValues.swift
//  Clipy
//
//  Created by 박민서 on 11/2/26.
//

import Foundation

import CoreDomain

/// 상품 입력 카드의 각 칸에 채울 값과, 고를 수 있는 선택지·글자 수 제한입니다.
struct SessionItemFormValues: Equatable {
    static let productNameLimit = 50
    static let noteLimit = 200
    static let currencyOptions = SessionItemCurrency.allCases
    static let statusOptions = ItemIntentState.allCases

    var urlText: String
    var productName: String
    var priceText: String
    var currency: SessionItemCurrency
    var note: String
    var status: ItemIntentState
}

/// 상품 입력에서 고를 수 있는 통화입니다.
/// 저장 모델의 통화는 문자열이라, 선택지는 입력 카드가 가집니다.
enum SessionItemCurrency: String, CaseIterable {
    case krw = "KRW"
    case usd = "USD"
    case jpy = "JPY"
    case cny = "CNY"
    case eur = "EUR"
}
