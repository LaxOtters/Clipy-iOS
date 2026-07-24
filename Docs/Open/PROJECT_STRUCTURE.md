# Project Structure

Clipy iOS는 Tuist-first 구조입니다.
Xcode project가 아니라 Tuist manifest를 기준으로 봅니다.

## 현재 구조

```plaintext
Clipy-iOS/
  Workspace.swift
  Tuist.swift
  Tuist/
    ProjectDescriptionHelpers/
  Modules/
    AppMain/
      Project.swift
      Sources/
      Tests/
    FeatureSession/
      Project.swift
      Sources/
        Interface/
        SessionView/
        SessionWeb/
      Tests/
        SessionView/
    CoreDomain/
      Project.swift
      Sources/
      Tests/
    CorePersistence/
      Project.swift
      Resources/
      Sources/
      Tests/
    CoreDesignSystem/
      Project.swift
      Resources/
        Assets.xcassets/
          Icon/
        Fonts/
        Licenses/
      Sources/
        Color/
        Component/
          ActionMenu/
        Icon/
        Resource/
        Typography/
      Tests/
        Color/
        Component/
          ActionMenu/
        Icon/
        Typography/
```

## 현재 module

| Module | 책임 |
| --- | --- |
| `AppMain` | app entry point, scene lifecycle, app 조립 |
| `FeatureSession` | Session 화면 진입, UIKit shell, WebView wrapper |
| `CoreDomain` | Session, Item, Decision, Capture, SessionSnapshot와 repository contract |
| `CorePersistence` | CoreData 기반 local 저장 구조, entity mapping, repository 구현 |
| `CoreDesignSystem` | 공용 UIKit typography·color Foundation, 기본 component, Pretendard·icon resource |

module이 늘어나도 기본 구조는 같습니다.
각 module은 자기 `Project.swift`와 `Sources/`를 가집니다.
`Tests/`는 오래 남길 테스트가 생길 때 추가합니다.
파일이 생기기 전의 빈 directory는 유지하지 않습니다.

Feature module 내부는 public entry와 제품 기능 surface를 기준으로 나눕니다.
`Interface/`에는 다른 module이 아는 진입 API를 둡니다.
나머지는 `SessionView/`, `SessionWeb/`처럼 feature 내부 기능 단위로 둡니다.

세부 ViewController / ViewModel 작성 기준은 팀 내부 규칙에서 관리합니다.
공개 문서에서는 module 구조와 의존 방향만 설명합니다.

## Module 확장 기준

Module은 화면 수가 아니라 책임 경계를 기준으로 늘립니다.
아직 필요하지 않은 target이나 directory를 미리 만들지 않습니다.

새 module은 아래 조건이 맞을 때 추가합니다.

- 실제 구현 작업에서 책임이 필요합니다.
- module 책임을 한 문장으로 설명할 수 있습니다.
- 의존 방향이 기존 구조와 어긋나지 않습니다.
- `Project.swift`, scheme, 테스트 필요 여부, 검증 방법을 함께 정할 수 있습니다.
- 다음 작업 범위의 구현을 미리 당겨오지 않습니다.

## 의존 방향

현재 module 의존은 아래처럼 둡니다.

```plaintext
AppMain -> FeatureSession -> CoreDomain
AppMain -> CorePersistence -> CoreDomain
AppMain -> CoreDesignSystem
FeatureSession -> CoreDesignSystem
```

`AppMain`은 app entry point와 composition root를 맡습니다.
`FeatureSession`은 Session 화면과 WebView wrapper를 맡습니다.
`CorePersistence`는 `CoreDomain`의 repository contract를 CoreData로 구현합니다.
`CoreDomain`은 저장소 구현, WebView, UIKit detail을 모릅니다.
`CoreDesignSystem`은 다른 Core module에 의존하지 않고 UIKit에서 사용할 typography·color API와 기본 component를 제공합니다.

Feature module이 생기면 기본 의존 방향은 아래처럼 둡니다.

```plaintext
AppMain -> Feature -> Core
AppMain -> Core
Feature -x-> Feature
Core -x-> Feature
```

Feature끼리는 직접 의존하지 않습니다.
공유해야 하는 규칙이나 타입이 생기면 먼저 Core 책임인지 봅니다.

## Tuist manifest 작성 기준

module `Project.swift`는 직접 `TargetDependency`를 조립하지 않고, 역할별 helper를 통해 target을 만듭니다.

| 역할 | helper |
| --- | --- |
| App target | `ClipyModuleFactory.makeApp` |
| Core framework | `ClipyModuleFactory.makeCore` |
| Feature framework | `ClipyModuleFactory.makeFeature` |

의존성은 `ClipyDependencies`에 모아두고, App/Core/Feature 역할에 맞는 typed dependency로 표현합니다.
module 이름과 bundle suffix는 module identifier에서 읽고, `Project.swift`는 어떤 module을 만들지 선언하는 쪽에 가깝게 둡니다.
이렇게 두면 module이 늘어나도 의존 방향과 target 이름을 `Project.swift`마다 다시 해석하지 않아도 됩니다.

module 하나만 확인할 때는 아래 command를 씁니다.

```bash
./scripts/validate_ios_module.sh CoreDomain
./scripts/validate_ios_module.sh CoreDesignSystem
./scripts/validate_ios_module.sh FeatureSession
```

기본은 `build-for-testing` mode입니다.
simulator에서 test까지 실행해야 할 때만 `CLIPY_IOS_VALIDATION_MODE=test`를 명시합니다.

```bash
CLIPY_IOS_VALIDATION_MODE=build-for-testing ./scripts/validate_ios_module.sh FeatureSession
```

Tuist manifest 규칙만 빠르게 확인할 때는 아래 command를 씁니다.

```bash
./scripts/validate_tuist_foundation.sh
```

이 검증은 module `Project.swift`에서 raw `.project`, `.external`, `TargetDependency` 조립, generic factory 직접 호출이 helper 밖으로 새지 않았는지 확인합니다.
생성된 `.xcodeproj`, `.xcworkspace`, `Derived/`가 tracked file로 들어오는지도 함께 막습니다.
tracked file 기준 검증이라서, PR 전에는 `git status --short`로 untracked 생성물도 따로 확인합니다.

작업 범위에 맞는 검증 묶음은 profile router로 실행합니다.
profile은 검증 방식과 비용을 정하고, module 대상은 scheme 입력으로 분리합니다.

```bash
CLIPY_IOS_VALIDATION_PROFILE=project-setup ./scripts/validate_ios_profile.sh

CLIPY_IOS_VALIDATION_PROFILE=integration \
CLIPY_IOS_VALIDATION_SCHEMES=FeatureSession \
./scripts/validate_ios_profile.sh
```

## DI 조립 위치

DIContainer는 `AppMain`에서 시작합니다.
`AppMain`은 Core 구현체와 Feature entry point를 조립합니다.

Feature는 container를 직접 들고 다니지 않습니다.
필요한 의존성은 initializer, factory, dependencies object로 받습니다.

좋은 방향입니다.

```swift
let viewModel = HomeViewModel(
    startNewSession: startNewSessionUseCase,
    loadSessions: loadSessionsUseCase
)
```

피할 방향입니다.

```swift
let viewModel = HomeViewModel(container: appDIContainer)
```

초기에는 별도 DI module을 만들지 않습니다.
DI 타입이 여러 Feature에서 반복되면 그때 작은 공유 module을 검토합니다.
`AppMain`만으로 조립 기준을 설명하기 어려울 때가 기준입니다.

## Clean Architecture 방향

Clipy의 Clean Architecture는 폴더 이름보다 의존 방향을 먼저 지킵니다.
기본 흐름은 아래처럼 둡니다.

```plaintext
Feature UI
  -> UseCase
  -> Repository Protocol
       <- Repository Implementation
            -> Local DB / Web / Cache
```

현재 `CoreDomain`은 entity, value object, `SessionViewState`, `SessionSnapshot`, repository protocol 같은 제품 상태 계약을 둡니다.
상태 전이 규칙과 use case는 해당 Feature 작업에서 실제 필요가 생길 때 추가합니다.

`CorePersistence`는 CoreData schema, entity mapping, `SessionRepository` 구현을 맡습니다.
Persistence, WebView, cache 같은 platform detail은 Domain 안으로 들어오지 않습니다.

`CoreDesignSystem`은 Figma에서 확인한 Light mode typography와 color 값을 UIKit API로 제공합니다.
`ClipyButton`, `ClipyFooterActionButton`, `ClipyDivider`, `ClipyActionMenuView`는 Foundation 값을 component Style에 매핑합니다.
Feature가 Foundation token을 화면마다 직접 선택하지 않도록 해, Figma semantic이 도입되면 Style mapping만 바꿀 수 있게 둡니다.
Pretendard font 파일과 등록 과정은 `CoreDesignSystem` 내부에서 관리하며, Feature가 bundle 경로나 font 파일 이름을 직접 알지 않습니다.
Action Menu도 item 목록과 표시·숨김 animation까지만 component가 맡고, 화면의 anchor·배치·dismiss 정책은 Feature가 맡습니다.

Feature는 UIKit 화면, ViewController, ViewModel, 화면 action 처리를 맡습니다.
Feature에서 local DB 구현체나 저장 schema를 직접 알지 않게 합니다.

## Session 중심 구조

Clipy는 Session 중심 앱입니다.
Home은 세션 진입과 관리에 집중합니다.
탐색, 수집, 비교, 결정, 리뷰는 대부분 Session 안에서 처리합니다.

그래서 module은 아래 방향으로 확장될 수 있습니다.
실제 target은 해당 책임을 가진 구현 작업이 열릴 때 만듭니다. `FeatureSession`은 Session shell과 WebView wrapper 책임이 필요해지면서 추가했습니다.

| 책임 | 예시 module |
| --- | --- |
| WebView, URL validation, web primitive | `CoreWeb` |
| 공용 UIKit component | `CoreDesignSystem` 확장 |
| Home, session list, start/reopen entry flow | `FeatureHome` |
| Session screen, bottom sheet, Decision surface | `FeatureSession` |

`Decision Screen`과 `Overlay Editor`는 초기 기준에서 Session 내부 surface로 봅니다.
별도 app-level feature module로 먼저 분리하지 않습니다.

## Tuist 기준 파일

- `Workspace.swift`
- `Tuist.swift`
- `Tuist/ProjectDescriptionHelpers/*`
- `Modules/*/Project.swift`

생성된 `.xcodeproj`, `.xcworkspace`, `Derived/`는 기준 파일로 보지 않습니다.
