//
//  ClipyModuleIdentifiers.swift
//  Clipy
//
//  Created by 박민서 on 6/11/26.
//

import ProjectDescription

/// Tuist helper 내부에서 module 이름, bundle suffix, project path를 한 곳에서 읽기 위한 식별자입니다.
protocol ClipyModuleIdentifiable {
    /// Tuist target과 project 이름으로 쓰는 module 이름입니다.
    var name: String { get }

    /// `com.laxotters.clipy` 뒤에 붙는 module별 bundle id suffix입니다.
    var bundleIdSuffix: String { get }
}

extension ClipyModuleIdentifiable {
    /// `Modules/<module name>` 규칙으로 계산한 Tuist project path입니다.
    var projectPath: Path {
        .relativeToRoot("\(ClipyProjectConfig.modulesRoot)/\(name)")
    }
}

/// App target으로 생성되는 module입니다.
public enum AppModule {
    case appMain
}

extension AppModule: ClipyModuleIdentifiable {
    var name: String {
        switch self {
        case .appMain:
            return "AppMain"
        }
    }

    var bundleIdSuffix: String {
        switch self {
        case .appMain:
            return "app"
        }
    }
}

/// Domain과 platform 구현처럼 feature 밖에서 공유되는 core module입니다.
public enum CoreModule {
    case coreDomain
    case corePersistence
    case coreDesignSystem
}

extension CoreModule: ClipyModuleIdentifiable {
    var name: String {
        switch self {
        case .coreDomain:
            return "CoreDomain"
        case .corePersistence:
            return "CorePersistence"
        case .coreDesignSystem:
            return "CoreDesignSystem"
        }
    }

    var bundleIdSuffix: String {
        switch self {
        case .coreDomain:
            return "core-domain"
        case .corePersistence:
            return "core-persistence"
        case .coreDesignSystem:
            return "core-design-system"
        }
    }
}

/// 화면이나 사용자 흐름 단위로 나뉘는 feature module입니다.
public enum FeatureModule {
    case featureHome
    case featureSession
}

extension FeatureModule: ClipyModuleIdentifiable {
    var name: String {
        switch self {
        case .featureHome:
            return "FeatureHome"
        case .featureSession:
            return "FeatureSession"
        }
    }

    var bundleIdSuffix: String {
        switch self {
        case .featureHome:
            return "feature-home"
        case .featureSession:
            return "feature-session"
        }
    }
}
