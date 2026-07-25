//
//  ClipyModuleDependencyTypes.swift
//  Clipy
//
//  Created by 박민서 on 6/11/26.
//

/// Tuist Package dependency를 manifest에서 raw string 없이 고르기 위한 enum입니다.
public enum ExternalDependency {
    case lottie
    case rxSwift
    case rxCocoa
    case rxRelay

    var packageName: String {
        switch self {
        case .lottie:
            return "Lottie"
        case .rxSwift:
            return "RxSwift"
        case .rxCocoa:
            return "RxCocoa"
        case .rxRelay:
            return "RxRelay"
        }
    }
}

/// Core module이 의존할 수 있는 대상입니다. Feature module은 여기서 열지 않습니다.
public enum CoreDependency {
    case core(CoreModule)
    case external(ExternalDependency)
}

/// Feature module이 의존할 수 있는 대상입니다. Feature끼리 직접 연결하지 않습니다.
public enum FeatureDependency {
    case core(CoreModule)
    case external(ExternalDependency)
}

/// App target이 composition root로 조립할 수 있는 대상입니다.
public enum AppDependency {
    case core(CoreModule)
    case feature(FeatureModule)
    case external(ExternalDependency)
}
