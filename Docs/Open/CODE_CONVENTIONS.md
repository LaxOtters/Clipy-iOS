# 코드 컨벤션

## 프로젝트 파일

- Xcode에서 생성된 `.xcodeproj`, `.xcworkspace`를 직접 고치지 않습니다.
- 구조 변경은 Tuist manifest에서 합니다.
- 생성된 Xcode 파일은 commit하지 않습니다.
- Tuist 버전은 `.mise.toml`에 고정합니다.

## Swift

- UI는 UIKit을 기준으로 작성합니다.
- 앱에서 사용자에게 보이는 문구는 영어를 우선으로 작성합니다.
- 한국어는 이후 localization 단계에서 제공합니다.
- 실제로 구조가 필요해지기 전까지는 단순한 UIKit/Foundation 타입을 씁니다.
- dependency는 필요할 때만 추가합니다.
- dependency를 추가하면 이유를 남깁니다.
- 테스트는 작고 동작 중심으로 둡니다.
- 테스트 이름만 봐도 지키는 규칙이 보여야 합니다.
- XCTest 이름은 `test_` 뒤를 의미 단위로 끊습니다.
- 끊는 지점에는 `_`를 쓰고, 각 덩어리는 lowerCamelCase로 씁니다.
- 작업 끝에는 임시 테스트를 정리합니다.

## Module

현재는 `AppMain`만 있습니다.

```plaintext
Modules/AppMain
```

아직 필요하지 않은 module은 미리 만들지 않습니다.
새 module을 추가할 때는 책임을 먼저 정하고, 의존 방향을 같이 정합니다.

### Module 추가 기준

새 module은 아래 조건이 맞을 때 추가합니다.

- 실제 구현 작업에서 책임이 필요합니다.
- module 책임을 한 문장으로 설명할 수 있습니다.
- Tuist `Project.swift`, scheme, test target 기준을 함께 정할 수 있습니다.
- 다른 작업 범위의 구현을 미리 당겨오지 않습니다.
- 빈 target이나 빈 directory만 만들지 않습니다.

### 기본 의존 방향

```plaintext
AppMain -> Feature -> Core
AppMain -> Core
Feature -x-> Feature
Core -x-> Feature
```

`AppMain`은 app 실행과 조립을 맡습니다.
제품 규칙, 저장, WebView primitive, 공용 UI primitive는 Core 계열에서 다룹니다.
Home과 Session처럼 사용자가 만나는 흐름은 Feature 계열에서 다룹니다.

Feature module끼리는 직접 의존하지 않습니다.
공유가 필요하면 먼저 Core로 올릴 책임인지, 아니면 아직 같은 Feature 안에 있어도 되는지 봅니다.

### DI 기준

DIContainer는 `AppMain`에서 시작합니다.
`AppMain`은 app의 composition root로 보고, Core 구현체와 Feature entry point를 조립합니다.

Feature는 container를 직접 들고 다니지 않습니다.
필요한 의존성은 initializer, factory, dependencies object로 받습니다.

좋은 방향입니다:

```swift
let viewModel = HomeViewModel(
    startNewSession: startNewSessionUseCase,
    loadSessions: loadSessionsUseCase
)
```

피할 방향입니다:

```swift
let viewModel = HomeViewModel(container: appDIContainer)
```

초기에는 별도 DI module을 만들지 않습니다.
DI 타입이 여러 Feature에서 반복되고 `AppMain`만으로 조립 기준을 설명하기 어려워질 때만 작은 공유 module을 검토합니다.

### Clean Architecture 기준

Clean Architecture는 폴더 이름보다 의존 방향을 먼저 지킵니다.

기본 흐름은 아래처럼 둡니다.

```plaintext
Feature UI
  -> UseCase
  -> Repository Protocol
       <- Repository Implementation
            -> Local DB / Web / Cache
```

`CoreDomain`은 entity, value object, 상태 전이 규칙, use case, repository protocol을 둡니다.
`CorePersistence`는 repository 구현체와 record mapping을 둡니다.
`CoreWeb`은 WebView, URL validation, capture 같은 platform primitive를 둡니다.

Feature는 UIKit 화면과 사용자 action 처리에 집중합니다.
Feature에서 local DB 구현체나 저장 schema를 직접 알지 않게 합니다.

### Session 중심 구조

Clipy는 Session 중심 앱입니다.
Home은 세션 진입과 관리에 집중하고, 대부분의 탐색, 수집, 비교, 결정, 리뷰는 Session 안에서 처리합니다.

그래서 아래 surface는 초기 기준에서 `FeatureSession` 책임으로 봅니다.

- WebView surface
- Contextual Overlay Actions
- Comparison Bottom Sheet
- Decision Screen
- Overlay Editor

`Decision Screen`과 `Overlay Editor`는 Session 내부 full-screen surface입니다.
별도 app-level feature module로 먼저 분리하지 않습니다.
