# Project Structure

현재 iOS project는 Tuist-first 구조입니다.
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
```

## AppMain

`AppMain`은 현재 유일한 app module입니다.
앱 entry point와 최소 실행 화면만 가집니다.

아직 Core/Feature module은 없습니다.
module이 늘어나면 각 module은 자기 `Project.swift`를 가집니다.

## Module 확장 방향

Clipy는 Session 중심 앱입니다.
Home은 세션 진입과 관리에 집중하고, 탐색, 수집, 비교, 결정, 리뷰는 대부분 Session 안에서 처리합니다.

그래서 module은 화면 수를 그대로 따라가기보다 책임 경계를 기준으로 늘립니다.
현재는 `AppMain`만 두고, 실제 구현 작업에서 책임이 분명해질 때 Core/Feature module을 추가합니다.

예상 확장 방향은 아래와 같습니다.

```plaintext
Modules/
  AppMain/
  CoreDomain/
  CorePersistence/
  CoreWeb/
  CoreUI/              # 공용 UIKit style/component가 필요해질 때만 추가
  FeatureHome/
  FeatureSession/
```

위 구조는 최종 확정 target 목록이 아닙니다.
새 module은 해당 책임을 가진 실제 구현 작업이 열릴 때 만듭니다.

## Module 책임

| Module | 책임 |
| --- | --- |
| `AppMain` | app entry point, app 조립, scene lifecycle |
| `CoreDomain` | Session, Item, Decision, Capture, 상태 전이 규칙 |
| `CorePersistence` | local DB, repository 구현, SessionViewState 저장, image cache 연결 |
| `CoreWeb` | WebView wrapper, URL validation, web page와 app 사이의 primitive |
| `CoreUI` | typography, color, 공용 UIKit component. 필요해질 때만 추가 |
| `FeatureHome` | Home, session list, start/reopen entry flow |
| `FeatureSession` | Session screen, WebView surface, overlay actions, bottom sheet, Decision surface, Overlay Editor |

`Decision Screen`과 `Overlay Editor`는 별도 app-level section이 아니라 Session 내부 surface로 봅니다.
따라서 초기 기준에서는 `FeatureDecision`이나 `FeatureOverlayEditor`를 따로 만들지 않습니다.

## 의존 방향

기본 의존 방향은 아래처럼 둡니다.

```plaintext
AppMain -> Feature -> Core
AppMain -> Core
Feature -x-> Feature
Core -x-> Feature
```

Feature끼리 직접 의존하지 않습니다.
Feature 사이에 공유해야 하는 규칙이나 타입이 생기면 먼저 Core 책임인지 봅니다.

## DI 조립 위치

DIContainer는 `AppMain`에서 시작합니다.
`AppMain`은 app의 composition root로 보고, Core 구현체와 Feature entry point를 조립합니다.

```plaintext
AppMain
  ├ AppDIContainer
  ├ FeatureHome factory
  ├ FeatureSession factory
  └ Core concrete instance wiring
```

Feature module은 `AppMain`을 알지 않습니다.
Feature는 필요한 use case, repository protocol, factory를 initializer나 dependencies object로 받습니다.
Core module도 `AppMain`을 알지 않습니다.

초기에는 별도 `CoreDI` module을 만들지 않습니다.
DI 관련 타입이 여러 Feature에서 반복되고 `AppMain`만으로 감당하기 어려워질 때만 작은 공유 module을 검토합니다.

## Clean Architecture 방향

Clipy의 Clean Architecture는 module 수를 먼저 늘리는 방식이 아니라, 의존 방향을 지키면서 필요한 layer를 나누는 방식으로 갑니다.

기본 흐름은 아래와 같습니다.

```plaintext
Feature UI
  -> UseCase
  -> Repository Protocol
       <- Repository Implementation
            -> Local DB / Web / Cache
```

module 기준으로 보면 아래처럼 연결됩니다.

```plaintext
FeatureHome / FeatureSession -> CoreDomain
CorePersistence -> CoreDomain
FeatureSession -> CoreWeb
AppMain -> FeatureHome / FeatureSession / CorePersistence / CoreWeb
```

`CoreDomain`은 entity, value object, 상태 전이 규칙, use case, repository protocol을 둡니다.
`CorePersistence`는 repository 구현체와 record mapping을 둡니다.
`CoreWeb`은 WebView와 URL 처리 같은 platform primitive를 둡니다.

Feature는 UIKit 화면, ViewController, ViewModel, 화면 action 처리를 맡습니다.
Feature에서 local DB 구현체를 직접 알지 않게 하고, `AppMain`에서 실제 구현체를 주입합니다.

## 예상 code 배치

각 module은 기본적으로 아래 구조를 가집니다.

```plaintext
Modules/<ModuleName>/
  Project.swift
  Sources/
  Tests/
```

module 안쪽 폴더는 구현이 생길 때 작게 나눕니다.
예상되는 배치는 아래 정도입니다.

```plaintext
CoreDomain/Sources/
  Session/
  Item/
  Decision/
  Capture/
  State/
  UseCases/
  Repositories/

CorePersistence/Sources/
  Records/
  Repositories/
  ViewState/
  ImageCache/

CoreWeb/Sources/
  WebView/
  URL/
  Capture/

FeatureHome/Sources/
  Home/
  SessionList/

FeatureSession/Sources/
  Session/
  BottomSheet/
  OverlayActions/
  Decision/
  OverlayEditor/
```

처음부터 이 폴더를 모두 만들지는 않습니다.
파일이 생기기 전의 빈 directory는 유지하지 않습니다.

## Tuist 기준 파일

- `Workspace.swift`
- `Tuist.swift`
- `Tuist/ProjectDescriptionHelpers/*`
- `Modules/*/Project.swift`

생성된 `.xcodeproj`, `.xcworkspace`는 기준 파일로 보지 않습니다.
