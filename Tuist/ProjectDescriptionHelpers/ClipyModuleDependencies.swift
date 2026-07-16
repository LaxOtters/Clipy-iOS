//
//  ClipyModuleDependencies.swift
//  Clipy
//
//  Created by 박민서 on 6/11/26.
//

/// 현재 module graph를 한 곳에서 읽기 위한 dependency map입니다.
public enum ClipyDependencies {
    public static let appMain: [AppDependency] = [
        .feature(.featureSession),
        .core(.corePersistence),
        .core(.coreDesignSystem)
    ]

    public static let coreDomain: [CoreDependency] = []

    public static let corePersistence: [CoreDependency] = [
        .core(.coreDomain)
    ]

    public static let coreDesignSystem: [CoreDependency] = []

    public static let featureSession: [FeatureDependency] = [
        .external(.rxSwift),
        .external(.rxCocoa),
        .external(.rxRelay),
        .core(.coreDomain),
        .core(.coreDesignSystem)
    ]
}
