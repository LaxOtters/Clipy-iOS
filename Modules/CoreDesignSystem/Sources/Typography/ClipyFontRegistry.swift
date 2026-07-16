//
//  ClipyFontRegistry.swift
//  Clipy
//
//  Created by 박민서 on 7/16/26.
//

import CoreText
import Foundation
import UIKit

enum ClipyFontRegistry {
    // Pretendard를 불러오지 못해도 텍스트가 표시되도록 같은 weight의 system font를 반환합니다.
    static func font(
        postScriptName: String,
        size: CGFloat,
        fallbackWeight: UIFont.Weight
    ) -> UIFont {
        if let font = UIFont(name: postScriptName, size: size) {
            return font
        }

        guard let url = CoreDesignSystemResourceBundle.module.url(
            forResource: postScriptName,
            withExtension: "otf"
        ) else {
            return UIFont.systemFont(ofSize: size, weight: fallbackWeight)
        }

        var unmanagedError: Unmanaged<CFError>?
        let didRegister = CTFontManagerRegisterFontsForURL(
            url as CFURL,
            .process,
            &unmanagedError
        )

        if !didRegister {
            let error = unmanagedError?.takeRetainedValue()
            let isAlreadyRegistered = error.map {
                CFErrorGetCode($0) == CTFontManagerError.alreadyRegistered.rawValue
            } ?? false

            guard isAlreadyRegistered else {
                return UIFont.systemFont(ofSize: size, weight: fallbackWeight)
            }
        }

        return UIFont(name: postScriptName, size: size)
            ?? UIFont.systemFont(ofSize: size, weight: fallbackWeight)
    }
}
