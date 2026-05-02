# 테스트 철학

테스트는 구현을 돕는 도구이면서, 나중에 제품 규칙을 읽는 문서이기도 합니다.
작업 중에는 TDD를 적극적으로 씁니다.
다만 마지막에는 오래 남길 테스트만 정리해서 둡니다.

## 기본 생각

- 테스트 수보다 중요한 건 어떤 규칙을 지키는지입니다.
- 테스트 이름과 구조만 봐도 앱의 규칙이 보여야 합니다.
- 구현 detail에 묶인 테스트는 오래 가지 못합니다.
- 제품 이해에 도움이 안 되는 테스트는 통과하더라도 비용입니다.

## 오래 남길 테스트

Clipy에서는 아래 테스트를 우선 남깁니다.

1. Session 상태 전이
2. Item / Decision 정책
3. 저장 / 복원 / 재진입 규칙

이 셋은 앱의 핵심 흐름입니다.
coverage 숫자를 올리기 위한 테스트보다, 이 규칙을 잘 설명하는 테스트가 더 중요합니다.

## Layer별 감각

모든 layer를 같은 강도로 테스트하지 않습니다.

| Layer | 주로 남길 것 | 줄일 것 |
| --- | --- | --- |
| Domain / State Machine | 상태 전이, Decision 정책, invariant | 단순 mapping |
| Persistence | schema, migration, restore, failure fallback | 단순 CRUD 반복 |
| ViewModel / Feature Logic | 사용자 action 뒤 상태 변화 | UIKit render detail |
| UIKit View / ViewController | 핵심 진입 흐름 | layout detail unit test |

UIKit View와 ViewController를 unit test로 과하게 묶지 않습니다.
화면 확인은 상황에 따라 manual check, snapshot, UI test 중 가벼운 방법을 고릅니다.

## 남길 테스트

- 상태 전이 규칙
- 저장/복원/재진입 규칙
- error/fallback 규칙
- 기능 완료 기준을 직접 증명하는 테스트
- 깨지면 제품 의미가 바뀌는 테스트

## 지울 테스트

- 구현 중 임시로 만든 scaffolding 테스트
- getter/setter나 초기값만 보는 테스트
- private helper 구현 모양에 묶인 테스트
- 같은 규칙을 이름만 바꿔 반복하는 테스트
- fixture가 너무 길어서 의도가 안 보이는 테스트

## 테스트 이름

XCTest 이름은 아래 형태를 기본으로 씁니다.

```swift
func test_<givenOrTrigger>_<expectedOutcome>_<businessMeaning>()
```

항상 세 덩어리를 맞출 필요는 없습니다.
보통 두세 덩어리면 충분합니다.

`_`는 단어마다 넣지 않습니다.
상황, 행동, 기대 결과처럼 의미가 바뀌는 지점에만 넣습니다.
각 덩어리 안은 lowerCamelCase로 씁니다.

좋은 예입니다:

```swift
func test_startingNewSession_createsDraftSession_readyForBrowsing()
func test_restoringPendingSession_restoresWebViewAndBottomSheet_forReentry()
func test_decidingWithMultipleItems_marksSelectedItemsOnly_asDecided()
func test_invalidSourceUrl_disablesStartButton()
func test_pendingSession_restoresBrowsingState()
```

피할 예입니다:

```swift
func testInit()
func testMapping()
func testViewModel()
func test_starting_new_session_creates_draft_session_ready_for_browsing()
func testStartingNewSessionCreatesDraftSessionReadyForBrowsing()
```

이름이 너무 길어지면 테스트가 너무 많은 걸 검증하는지 먼저 봅니다.
`_`를 더 넣기보다 테스트를 나누는 쪽이 낫습니다.

## Fixture와 Mock

Fixture와 mock은 테스트 의도를 가리면 안 됩니다.
setup이 길어지면 규칙이 묻힙니다.

좋은 방향입니다:

```swift
let session = Session.draft(items: [.validItem])
```

피할 방향입니다:

```swift
let session = Session(
    id: UUID(),
    title: "...",
    createdAt: Date(),
    updatedAt: Date(),
    items: [...],
    viewState: ...,
    metadata: ...
)
```

`TestSupport`나 fixture factory는 필요해질 때 만듭니다.
다만 helper 이름도 제품 언어로 읽혀야 합니다.

## 주석

주석은 “왜 이 규칙이 중요한지”를 설명할 때만 남깁니다.
코드가 그대로 말하는 setup 설명은 적지 않습니다.

남길 만한 주석입니다:

```swift
// Pending session은 사용자가 비교를 중단한 상태입니다.
// 그래서 재진입 시 WebView와 Bottom Sheet 상태를 함께 복원해야 합니다.
func test_restoringPendingSession_keepsWebViewAndBottomSheetState()
```

## 작업 중 흐름

1. 현재 작업에서 지켜야 할 제품 규칙을 한 문장으로 뽑습니다.
2. 그 규칙을 실패하는 테스트로 먼저 씁니다.
3. 가장 작은 구현으로 통과시킵니다.
4. 중복과 임시 fixture를 줄입니다.
5. 마지막에 테스트 이름과 구조가 문서처럼 읽히는지 봅니다.

## 삭제 기준

아래 질문에 “아니오”라면 지우거나 더 의미 있는 테스트로 합칩니다.

> 이 테스트가 없으면 다음 개발자가 제품 규칙을 오해할까요?

## 마무리 체크

- [ ] 남은 테스트가 현재 작업의 핵심 규칙을 설명합니다.
- [ ] 테스트 이름만 봐도 흐름이 보입니다.
- [ ] `_`는 의미 덩어리 기준으로만 썼습니다.
- [ ] 구현 detail에 묶인 임시 테스트를 정리했습니다.
- [ ] 같은 규칙을 중복 검증하지 않습니다.
- [ ] fixture와 mock이 테스트 의도를 가리지 않습니다.
- [ ] 주석은 제품 이유를 설명할 때만 남겼습니다.
