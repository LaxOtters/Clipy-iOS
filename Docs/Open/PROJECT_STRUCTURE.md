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
```

## 현재 module

| Module | 책임 |
| --- | --- |
| `AppMain` | app entry point, scene lifecycle, app 조립 |
| `FeatureSession` | Session 화면 진입, UIKit shell, WebView wrapper |
| `CoreDomain` | Session, Item, Decision, Capture, SessionSnapshot와 repository contract |
| `CorePersistence` | CoreData 기반 local 저장 구조, entity mapping, repository 구현 |

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
```

`AppMain`은 app entry point와 composition root를 맡습니다.
`FeatureSession`은 Session 화면과 WebView wrapper를 맡습니다.
`CorePersistence`는 `CoreDomain`의 repository contract를 CoreData로 구현합니다.
`CoreDomain`은 저장소 구현, WebView, UIKit detail을 모릅니다.

Feature module이 생기면 기본 의존 방향은 아래처럼 둡니다.

```plaintext
AppMain -> Feature -> Core
AppMain -> Core
Feature -x-> Feature
Core -x-> Feature
```

Feature끼리는 직접 의존하지 않습니다.
공유해야 하는 규칙이나 타입이 생기면 먼저 Core 책임인지 봅니다.

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
| 공용 UIKit style/component | `CoreUI` |
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
