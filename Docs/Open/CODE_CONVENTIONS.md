# 코드 컨벤션

Clipy iOS 코드를 작성할 때 반복해서 보는 공개 기준입니다.
module 구조는 `PROJECT_STRUCTURE.md`, 테스트 기준은 `TESTING_GUIDE.md`에 둡니다.

## 프로젝트 파일

- Xcode에서 생성된 `.xcodeproj`, `.xcworkspace`를 직접 고치지 않습니다.
- 구조 변경은 Tuist manifest에서 합니다.
- 생성된 Xcode 파일과 `Derived/`는 commit하지 않습니다.
- Tuist 버전은 `.mise.toml`에 고정합니다.

## Swift 기본 기준

- UI는 UIKit을 기준으로 작성합니다.
- SwiftUI는 명시적으로 필요해질 때만 검토합니다.
- 앱에서 사용자에게 보이는 문구는 영어를 우선으로 작성합니다.
- 한국어는 이후 localization 단계에서 제공합니다.
- 실제로 구조가 필요해지기 전까지는 단순한 UIKit/Foundation 타입을 씁니다.
- dependency는 필요할 때만 추가하고, 추가한 이유를 남깁니다.

## 공개 API의 타입 관리

공개 타입은 이름보다 먼저 관리 책임을 봅니다.

- 컴포넌트나 기능 없이 독립적인 의미가 없는 보조 타입은 해당 진입점 아래 한 단계로 중첩합니다.
  예를 들어 버튼의 표현 종류는 `ClipyButton.Variant`, 다이얼로그의 응답은
  `ClipyDialog.Response`처럼 둡니다.
- 여러 영역에서 독립적으로 재사용되거나 타입 자체가 호출 진입점이면 top-level에 둡니다.
  `ClipyButton`, `ClipyTextStyle` 같은 타입을 억지로 다른 namespace 아래에 넣지 않습니다.
- `Models`, `Types`, `Contracts`, `Common`처럼 실제 관리 책임을 드러내지 않는 namespace는 만들지 않습니다.
- `ClipyDialog.Configuration.Button.Layout`처럼 두 단계 이상 깊어지는 중첩은 피합니다.
  한 단계 안에서 역할을 설명할 수 없으면 타입의 책임이나 분리 기준을 다시 봅니다.
- 중첩은 접근 제어를 대신하지 않습니다. 다른 모듈의 public API가 사용하는 타입은 중첩 여부와
  관계없이 필요한 접근 수준을 유지합니다.
- 타입 묶음이 커지면 `extension`으로 파일을 나눌 수 있지만, 보조 enum마다 파일을 하나씩 만들지는 않습니다.

기존 API는 이 규칙만 적용하려고 한 번에 바꾸지 않습니다. 새 API와 현재 수정하는 영역부터 적용하고,
호출부가 많은 기존 API는 별도 리팩토링 범위에서 바꿉니다.

## Swift 파일 header

새 Swift 파일은 Xcode 기본 header 형태를 유지합니다.
project 이름은 `Clipy`로 씁니다.

```swift
//
//  FileName.swift
//  Clipy
//
//  Created by 박민서 on M/D/YY.
//
```

날짜는 파일이 들어가는 commit 날짜와 맞춥니다.
generated Swift 파일이나 외부에서 생성된 파일에는 억지로 header를 붙이지 않습니다.

## 화면 코드

UIKit 화면 코드는 가능한 한 얇게 둡니다.
ViewController는 navigation, binding, rendering에 집중합니다.

제품 규칙은 ViewController 내부에 오래 두지 않습니다.
비교, 결정, 저장/복원 같은 규칙은 먼저 그 동작을 소유하는 Domain이나 ViewModel로 옮깁니다.

ViewModel은 화면 동작의 소유자입니다.
사용자 action뿐 아니라 화면 동작에 영향을 주는 lifecycle이나 system event도 input으로 받을 수 있습니다.
UIKit callback을 그대로 전달하기보다 `screenBecameVisible`, `refreshRequested`처럼 화면에서 의미 있는 event로 바꿉니다.

State Machine은 별도의 화면 계층이 아닙니다.
event 순서, 중복, interruption처럼 허용되는 상태 전이가 중요한 경우 Domain, ViewModel, Coordinator 같은 소유자 내부에서 사용합니다.
직접 UIKit을 렌더링하거나 navigation, repository, 외부 SDK를 실행하지 않고 현재 state와 event로 다음 state와 command만 결정합니다.

## 의존성

외부 SDK나 system service를 직접 퍼뜨리지 않습니다.
여러 곳에서 쓰거나 테스트 경계가 필요하면 project-owned protocol이나 adapter를 먼저 둡니다.

좋은 방향입니다.

```swift
protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
}
```

피할 방향입니다.

```swift
final class HomeViewModel {
    private let thirdPartyAnalytics: ThirdPartyAnalytics
}
```

## 테스트

테스트는 작고 동작 중심으로 둡니다.
테스트 이름만 봐도 지키는 제품 규칙이 보여야 합니다.

자세한 기준은 `TESTING_GUIDE.md`를 봅니다.
테스트 이름, fixture, mock/stub/spy, UIKit 화면 테스트 기준도 그 문서에서 다룹니다.

## Module

Module은 필요할 때만 추가합니다.
새 module을 만들기 전에는 책임, 의존 방향, test target, 검증 방법을 함께 정합니다.

자세한 구조 기준은 `PROJECT_STRUCTURE.md`를 봅니다.
