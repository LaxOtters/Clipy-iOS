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
