# 테스트 철학

테스트는 구현을 돕는 도구이면서, 나중에 제품 규칙을 읽는 문서이기도 합니다.
Clipy의 테스트는 coverage 숫자를 맞추기 위한 장치가 아닙니다.
Session, Decision, 저장/복원처럼 앱의 핵심 규칙을 안전하게 바꾸기 위한 장치입니다.

작업 중에는 TDD를 적극적으로 씁니다.
마지막에는 오래 남길 테스트만 정리해서 둡니다.
테스트 코드도 유지보수 비용이 있는 코드이기 때문입니다.

## 기본 생각

- 테스트 수보다 중요한 건 어떤 규칙을 지키는지입니다.
- 테스트 이름과 구조만 봐도 앱의 규칙이 보여야 합니다.
- 구현 detail에 묶인 테스트는 오래 가지 못합니다.
- 제품 이해에 도움이 안 되는 테스트는 통과하더라도 비용입니다.
- coverage는 낮으면 위험 신호지만, 높다고 좋은 테스트 suite를 보장하지는 않습니다.
- 좋은 테스트 suite는 개발 흐름 안에서 자주 돌릴 수 있어야 합니다.

## 타입 설계, 런타임 검증, 테스트

세 가지는 같은 계약을 서로 다른 시점에서 지킵니다.

| 수단 | 역할 |
| --- | --- |
| 타입 설계 | 가능하면 잘못된 상태 자체를 만들 수 없게 합니다. |
| 런타임 검증 | 실제 호출과 외부 입력에서 계약을 집행하고 안전하게 실패합니다. |
| 테스트 | 계약과 fallback이 구현됐는지 배포 전에 증명합니다. |

리뷰할 때는 타입 설계로 invalid state를 줄일 수 있는지 먼저 봅니다.
그래도 남는 동적 입력과 외부 경계는 실제 앱 코드에서 검증합니다.
마지막으로 남길 테스트가 정상 계약과 실패 동작을 설명하는지 확인합니다.

테스트가 통과한다고 실제 앱의 `guard`, error handling, fallback을 생략하지 않습니다.
반대로 런타임 검증이 있다고 계약 테스트를 생략하지 않습니다.
테스트는 실제 호출을 방어하지 않고, 런타임 검증은 계약 구현이 계속 맞는지 증명하지 않습니다.

## 좋은 테스트의 기준

Clipy에서는 테스트를 남길 때 아래 네 가지를 함께 봅니다.

| 기준 | Clipy iOS에서의 의미 |
| --- | --- |
| Regression 방지 | 실제 제품 규칙이 깨졌을 때 실패합니다. |
| Refactoring 저항성 | 내부 구조를 바꿔도 같은 동작이면 깨지지 않습니다. |
| 빠른 feedback | 작업 중 자주 돌릴 수 있을 만큼 빠릅니다. |
| 유지보수성 | fixture, mock, assertion이 테스트 의도를 가리지 않습니다. |

네 가지를 모두 최대로 만족하는 테스트는 거의 없습니다.
그래도 refactoring 저항성은 쉽게 포기하지 않습니다.
false alarm이 반복되면 테스트 suite를 믿지 않게 되고, 결국 실패를 무시하게 됩니다.

그래서 Clipy의 테스트는 내부 호출 순서보다 결과를 봅니다.
ViewModel helper 분리만으로 깨지는 테스트는 좋은 테스트가 아닙니다.
UIKit binding 방식 변경이나 repository 구현 교체에도 쉽게 깨지면 구현 detail에 묶였는지 봅니다.

## 테스트 깊이와 관찰 경계

외부 framework나 system component를 사용할 때는 앱이 소유한 규칙과 SDK 내부 동작을 나눠 봅니다.
앱이 정한 정책은 결정적으로 테스트하고, adapter 연결은 production에서 실제로 노출하는 결과로 확인합니다.
SDK 내부 구현까지 증명하려고 private 객체를 열거나 test-only API를 추가하지 않습니다.

| 경계 | 테스트 방향 |
| --- | --- |
| 앱이 소유한 정책과 상태 전이 | unit test나 state test로 빠르고 결정적으로 검증합니다. |
| 앱이 만든 adapter의 연결 | production output을 이용한 좁은 integration test를 둡니다. |
| framework 내부 동작 | 앱 계약에 필요한 결과까지만 확인하고 exhaustive하게 다시 검증하지 않습니다. |
| 아직 production 관찰 경계가 없는 동작 | 테스트를 위해 경계를 만들지 않고 후속 범위와 다시 열 조건을 기록합니다. |

더 깊은 테스트가 항상 더 좋은 테스트는 아닙니다.
private 접근, reflection, test-only initializer나 진단 API가 필요하다면 먼저 그 검증이 현재 제품 위험을 실제로 줄이는지 봅니다.
현재 adapter가 보장해야 할 결과를 이미 확인했다면 framework 내부 관찰을 위해 production 구조를 넓히지 않습니다.

검증을 미룰 때는 막연히 “나중에 테스트”라고만 적지 않습니다.

- 지금 검증하는 앱 계약
- 현재 범위에서 검증하지 않는 framework 내부 동작
- 다시 검증을 열 제품 기능이나 위험
- 그때 production에 생길 관찰 경계
- 후속 테스트에서 확인할 결과

기능이 확장되어 앱이 더 많은 lifecycle, 복구, bridge, telemetry를 소유하게 되면 테스트 범위도 함께 넓힙니다.
반대로 앱 책임이 늘지 않았는데 테스트만 깊어지는 구조는 피합니다.

## Unit test의 단위

Unit test의 단위는 class 하나가 아니라 behavior 하나입니다.
여러 객체가 함께 동작해도 괜찮습니다.
하나의 제품 규칙을 빠르고 독립적으로 검증한다면 unit test로 봅니다.

예를 들어 아래 테스트는 class 단위가 아니라 behavior 단위입니다.

- 새 Session을 시작하면 draft session이 만들어집니다.
- pending session으로 재진입하면 WebView와 Bottom Sheet 상태가 함께 복원됩니다.
- 여러 item 중 사용자가 고른 item만 decided 상태가 됩니다.

method 하나만 호출해도 제품 규칙을 설명하지 못할 수 있습니다.
private helper 분기나 collaborator 호출 순서만 확인한다면 구현 detail에 가깝습니다.

## 오래 남길 테스트

Clipy에서는 아래 테스트를 우선 남깁니다.

1. Session 상태 전이
2. Item / Decision 정책
3. 저장 / 복원 / 재진입 규칙
4. error / fallback 규칙
5. 외부 boundary로 나가는 중요한 contract

이 흐름은 앱의 핵심입니다.
coverage 숫자를 올리기 위한 테스트보다, 이 규칙을 설명하는 테스트가 더 중요합니다.

## Layer별 감각

| Layer | 주로 남길 것 | 줄일 것 |
| --- | --- | --- |
| Domain / State Machine | 상태 전이, Decision 정책, invariant | 단순 mapping |
| Persistence | schema, migration, restore, failure fallback | 단순 CRUD 반복 |
| ViewModel / Feature Logic | 사용자 action 뒤 상태 변화 | 내부 helper 호출 순서 |
| UIKit View / ViewController | 핵심 진입 흐름, 화면 조립 smoke | layout detail unit test |
| External Boundary | API request contract, analytics event, system adapter 호출 | third-party type 직접 mock |

UIKit View와 ViewController를 unit test로 과하게 묶지 않습니다.
화면 확인은 상황에 따라 manual check, snapshot, UI test 중 가벼운 방법을 고릅니다.

화면 테스트를 고를 때도 기준은 같습니다.
먼저 제품 규칙이 어디에 있는지 봅니다.
보임, 숨김, 전이, 입력 가능 여부처럼 화면에서 드러나는 규칙이라도, 그 판단이 Policy나 ViewModel state로 표현된다면 그쪽을 테스트합니다.
UIKit subview가 실제로 붙어 있는지까지 unit test로 고정하지 않습니다.

복잡한 로직이 UIKit, persistence, network와 한곳에 섞이면 테스트가 비싸집니다.
이때는 mock을 늘리기보다 제품 규칙을 먼저 분리합니다.

## iOS 화면 코드 테스트 기준

UIKit 화면 코드는 가능한 한 얇게 둡니다.
ViewController는 navigation, binding, rendering에 집중합니다.
비교, 결정, 복원 같은 규칙은 먼저 그 동작을 소유하는 Domain이나 ViewModel로 옮깁니다.
이벤트 순서와 interruption 자체가 규칙이면 해당 소유자 내부의 상태머신으로 분리합니다.

좋은 방향은 ViewController가 직접 판단하지 않는 구조입니다.
ViewController는 ViewModel state를 렌더링합니다.
WebView, Bottom Sheet, navigation은 직접 unit test하기보다 그 상태를 결정하는 policy를 테스트합니다.

ViewModel 테스트는 화면 입력 뒤 렌더링 상태, 라우트, 오류와 외부 작업 결과를 봅니다.
상태머신 테스트는 허용되는 상태 전환, 중복 이벤트, interruption 규칙만 봅니다.
ViewModel이 상태머신을 사용하더라도 같은 전환 규칙을 양쪽 테스트에서 반복하지 않습니다.

화면 테스트는 아래 순서로 판단합니다.

| 질문 | 테스트 방향 |
| --- | --- |
| 화면 상태가 제품 규칙인가? | Policy나 ViewModel state test로 먼저 증명합니다. |
| UIKit view가 단순히 그 state를 그리는가? | unit test로 view hierarchy를 고정하지 않습니다. |
| 실제 화면이 깨졌는지 눈으로 확인해야 하는가? | manual check나 PR screenshot으로 확인합니다. |
| 시각 차이가 제품 contract에 가까운가? | 대표 상태만 snapshot 후보로 봅니다. |
| 여러 화면을 지나야만 깨지는 흐름인가? | 최소 UI test 후보로 봅니다. |

아래 방향은 피합니다.

- button tap 뒤 private method가 호출됐는지 확인합니다.
- layout constraint 값을 unit test에서 촘촘히 검증합니다.
- ViewController 내부 collaborator를 모두 mock으로 바꿔 호출 순서를 검증합니다.
- placeholder label이나 임시 subview가 존재하는지만 확인합니다.
- 보임/숨김 규칙을 state가 아니라 subview hierarchy로만 검증합니다.
- unit test가 UIKit view를 찾을 목적으로 `accessibilityIdentifier`나 `tag`를 제품 코드에 추가하지 않습니다.

`accessibilityIdentifier`는 실제 접근성 요구나 UI test처럼 제품과 검증 환경에서 함께 쓰는 이유가 있을 때만 둡니다.
unit test helper 하나를 위해 추가했다면 테스트 경계를 다시 봅니다.
이때 hierarchy 탐색을 없앤다는 이유로 그 테스트가 함께 확인하던 제품 규칙까지 삭제하지 않습니다.
route mapping, dependency 생성 실패, 재시도처럼 UI 밖에서도 설명할 수 있는 규칙은 작은 `Mapper`, `Policy`, 작업 타입으로 옮겨 직접 테스트합니다.

## 이미지와 리소스 테스트

화면을 꾸미는 정적 이미지가 asset catalog에 들어 있는지만 확인하는 unit test는 기본적으로 남기지 않습니다.
아이콘 이름, PNG 크기, 1x/2x/3x rendition처럼 디자인 교체에 따라 바뀌는 값도 같은 기준으로 봅니다.
이런 차이는 unit test보다 build, screenshot, source review로 확인하는 편이 낫습니다.

리소스 테스트를 남기려면 누락됐을 때 깨지는 제품 규칙과 앱의 처리 방식이 먼저 정해져 있어야 합니다.
예를 들어 placeholder로 바꾸거나 오류 상태를 보여주는 동작이 제품 규칙이라면, 특정 파일의 존재 여부가 아니라 그 대체 동작을 테스트합니다.
CoreDesignSystem이 외부 모듈에 공개하는 아이콘처럼 크기와 rendering mode가 API 규약인 경우에는 해당 공개 규약만 좁게 검증할 수 있습니다.

아래 테스트는 삭제 후보입니다.

- static illustration을 `XCTAssertNotNil`로 나열합니다.
- `UIImageAsset`에서 scale별 rendition이 선택되는지 반복 확인합니다.
- asset의 pixel 크기나 파일명을 production 상수와 그대로 비교합니다.
- placeholder 파일이 catalog에 존재하는지만 확인합니다.

## 테스트 스타일 우선순위

가능하면 아래 순서로 테스트합니다.

1. Output-based test
2. State-based test
3. Communication-based test

Output-based test는 입력과 출력만 봅니다.
Domain policy나 formatter처럼 순수한 코드에 가장 잘 맞습니다.

State-based test는 action 뒤 상태 변화를 봅니다.
ViewModel과 feature logic에 현실적으로 많이 씁니다.

Communication-based test는 dependency 호출 여부를 봅니다.
이 방식은 외부 boundary에서만 제한적으로 씁니다.
내부 객체끼리의 호출 순서를 검증하기 시작하면 refactoring에 약해집니다.

## Mock, Stub, Spy

Test double은 의도를 가리지 않을 때만 씁니다.
mock을 많이 쓰는 테스트는 보통 구현 detail에 가까워집니다.

Clipy에서는 아래처럼 구분합니다.

| Test double | 쓰는 곳 | 주의할 점 |
| --- | --- | --- |
| Stub | 테스트 입력을 고정할 때 | stub이 호출됐는지는 검증하지 않습니다. |
| Spy | 외부 boundary로 나간 결과를 기록할 때 | analytics, network adapter, external URL에 적합합니다. |
| Mock | 외부 contract를 검증할 때 | 내부 domain 객체끼리는 되도록 쓰지 않습니다. |

Mock은 system edge에서 가장 가치가 큽니다.
analytics event, remote API request, external URL open처럼 앱 밖으로 나가는 contract를 검증할 때 씁니다.

third-party type은 직접 mock하지 않습니다.
우리가 소유한 protocol이나 adapter를 두고 그 경계를 검증합니다.

호출 횟수가 제품 contract라면 검증할 수 있습니다.
그렇지 않다면 결과 state나 외부 contract를 보는 쪽이 낫습니다.

피할 방향입니다.

```swift
XCTAssertTrue(repository.saveCalled)
XCTAssertTrue(viewModel.didCallPrivateUpdateState)
```

## Persistence와 integration test

저장소는 앱이 소유하는 managed dependency와 앱 밖의 unmanaged dependency를 나눠 봅니다.

| 구분 | 예 | 테스트 방향 |
| --- | --- | --- |
| Managed dependency | local database, file store, app-owned cache | 실제 구현에 가까운 integration test를 둡니다. |
| Unmanaged dependency | remote API, analytics backend, system service | owned adapter를 stub/spy/mock으로 대체합니다. |

Persistence test는 단순 CRUD를 반복하기보다 제품 규칙을 검증합니다.

Clipy에서 우선순위가 높은 persistence test입니다.

- pending session 저장 후 재진입
- decision 결과 저장 후 복원
- migration 뒤 핵심 흐름 유지
- 손상된 cache나 누락된 데이터의 fallback

Repository 자체가 단순 wrapper라면 직접 unit test 우선순위는 낮습니다.
복잡한 mapping이나 복원 규칙은 pure mapper, policy, factory로 뺍니다.
그 규칙은 unit test로 검증합니다.
Repository는 대표 저장/복원 integration 흐름에서 검증합니다.

## Time, UUID, randomness

시간, UUID, random 값은 테스트를 불안정하게 만들기 쉽습니다.
Domain 내부에서 `Date()`, `UUID()`, random 값을 직접 만들지 않습니다.

가능하면 operation 시작 지점에서 값을 만들고, 내부에는 plain value로 전달합니다.
service injection이 필요하면 앱 boundary에서만 사용합니다.

좋은 방향입니다.

```swift
let now = Date(timeIntervalSince1970: 1_800_000_000)
let session = Session.start(now: now)
```

피할 방향입니다.

```swift
let session = Session.start()
XCTAssertEqual(session.createdAt, Date())
```

Session 생성일, decision timestamp, expiry 규칙은 고정된 값으로 테스트합니다.

## 테스트 구조

XCTest는 Arrange / Act / Assert 흐름으로 씁니다.
주석을 꼭 붙일 필요는 없지만, 구조는 눈에 보여야 합니다.

```swift
let session = Session.draft(items: [.validItem])
let sut = DecisionPolicy()

let result = sut.decide(itemID: .validItem, in: session)

XCTAssertEqual(result.decidedItems, [.validItem])
```

Unit test에서 Act가 여러 줄이면 먼저 API를 의심합니다.
항상 함께 호출해야 하는 단계가 밖으로 새어 있으면 invariant가 깨질 수 있습니다.

피할 방향입니다.

```swift
sut.prepare()
sut.validate()
sut.commit()
```

이 세 단계가 항상 함께 실행되어야 한다면 production API를 의심합니다.
하나의 business operation으로 묶는 편이 나을 수 있습니다.

테스트 안의 `if`도 피합니다.
분기가 필요하면 보통 시나리오가 두 개입니다.
테스트를 나누는 쪽이 읽기 쉽습니다.

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

좋은 예입니다.

```swift
func test_startingNewSession_createsDraftSession_readyForBrowsing()
func test_restoringPendingSession_restoresWebViewAndBottomSheet_forReentry()
func test_decidingWithMultipleItems_marksSelectedItemsOnly_asDecided()
func test_invalidSourceUrl_disablesStartButton()
func test_pendingSession_restoresBrowsingState()
```

피할 예입니다.

```swift
func testInit()
func testMapping()
func testViewModel()
func test_starting_new_session_creates_draft_session_ready_for_browsing()
func testStartingNewSessionCreatesDraftSessionReadyForBrowsing()
```

이름이 너무 길어지면 테스트가 너무 많은 걸 검증하는지 먼저 봅니다.
`_`를 더 넣기보다 테스트를 나누는 쪽이 낫습니다.

## Fixture와 helper

Fixture와 helper는 테스트 의도를 가리면 안 됩니다.
setup이 길어지면 규칙이 묻힙니다.

좋은 방향입니다.

```swift
let session = Session.draft(items: [.validItem])
```

피할 방향입니다.

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
helper 이름도 제품 언어로 읽혀야 합니다.

공통 `setUp()`에 많은 상태를 숨기지 않습니다.
테스트마다 중요한 arrange가 바로 보이는 편이 낫습니다.

Parameterized 또는 table-driven test는 중복을 줄일 때 도움이 됩니다.
실패 메시지와 테스트 이름이 흐려지면 분리된 테스트가 낫습니다.
제품 규칙이 다른 case라면 반복 제거보다 읽기 쉬운 테스트를 우선합니다.

## 주석

주석은 “왜 이 규칙이 중요한지”를 설명할 때만 남깁니다.
코드가 그대로 말하는 setup 설명은 적지 않습니다.

남길 만한 주석입니다.

```swift
// Pending session은 사용자가 비교를 중단한 상태입니다.
// 그래서 재진입 시 WebView와 Bottom Sheet 상태를 함께 복원해야 합니다.
func test_restoringPendingSession_keepsWebViewAndBottomSheetState()
```

## 피해야 할 테스트

아래 테스트는 지우거나 더 의미 있는 테스트로 바꿉니다.

- 구현 중 임시로 만든 scaffolding 테스트
- getter/setter나 초기값만 보는 테스트
- private helper 구현 모양에 묶인 테스트
- private method를 테스트하기 위해 access level을 올리는 테스트
- 테스트만을 위해 production API나 state를 노출하는 코드
- 같은 규칙을 이름만 바꿔 반복하는 테스트
- fixture가 너무 길어서 의도가 안 보이는 테스트
- stub 호출 여부를 검증하는 테스트
- production constant를 그대로 가져와 비교하는 tautology test
- UIKit layout detail에 과하게 묶인 unit test
- static asset 존재 여부나 scale별 rendition만 확인하는 resource test

Private method가 너무 복잡해서 직접 테스트하고 싶다면 숨은 abstraction이 있다는 신호일 수 있습니다.
access level을 올리기보다 `Policy`, `Mapper`, `StateMachine` 같은 타입으로 분리할지 봅니다.

## 작업 중 흐름

1. 현재 작업에서 지켜야 할 제품 규칙을 한 문장으로 뽑습니다.
2. 그 규칙을 실패하는 테스트로 먼저 씁니다.
3. 가장 작은 구현으로 통과시킵니다.
4. 중복과 임시 fixture를 줄입니다.
5. 마지막에 테스트 이름과 구조가 문서처럼 읽히는지 봅니다.

TDD 중에는 임시 테스트를 더 많이 둘 수 있습니다.
다만 PR에 남기는 테스트는 한 번 더 걸러냅니다.
임시 테스트가 구현을 찾는 데만 필요했다면 삭제합니다.
제품 규칙을 설명하고 다음 변경에서 regression을 막는다면 남깁니다.

## 삭제 기준

아래 질문에 “아니오”라면 지우거나 더 의미 있는 테스트로 합칩니다.

> 이 테스트가 없으면 다음 개발자가 제품 규칙을 오해할까요?

아래 질문도 함께 봅니다.

- 이 테스트가 refactoring이 아니라 제품 동작 변경에 반응하나요?
- 실패했을 때 고쳐야 할 production behavior가 분명한가요?
- mock setup보다 제품 규칙이 더 잘 보이나요?
- UIKit이나 persistence 구현 detail이 아니라 사용자 관점의 결과를 검증하나요?
- 화면 test라면 UIKit view 존재가 아니라 상태 규칙이나 사용자 흐름을 설명하나요?

아래 테스트는 PR에 남기기 전에 다시 봅니다.

| 테스트 형태 | 기본 판단 |
| --- | --- |
| placeholder view 존재 확인 | 삭제 후보입니다. screenshot 보조 표현이면 테스트하지 않습니다. |
| constraint 상수 비교 | 삭제 후보입니다. 제품 규칙으로 승격된 수치인지 먼저 봅니다. |
| `isHidden` 값만 확인 | state rule로 검증할 수 있으면 view test로 남기지 않습니다. |
| Policy와 ViewModel에서 같은 규칙 반복 검증 | 둘 다 필요한지 봅니다. ViewModel은 input/output 연결 의미가 있을 때만 남깁니다. |
| manual check로 충분한 화면 조립 | unit test보다 PR screenshot이나 simulator 확인이 낫습니다. |

## 마무리 체크

- [ ] 남은 테스트가 현재 작업의 핵심 규칙을 설명합니다.
- [ ] 테스트 이름만 봐도 흐름이 보입니다.
- [ ] `_`는 의미 덩어리 기준으로만 썼습니다.
- [ ] 구현 detail에 묶인 임시 테스트를 정리했습니다.
- [ ] 같은 규칙을 중복 검증하지 않습니다.
- [ ] fixture와 mock이 테스트 의도를 가리지 않습니다.
- [ ] mock은 system edge 중심으로만 남겼습니다.
- [ ] 시간, UUID, random 값은 고정하거나 명시적으로 주입했습니다.
- [ ] UIKit 화면 코드는 unit test보다 더 가벼운 확인 방법이 맞는지 봤습니다.
- [ ] placeholder, subview hierarchy, constraint 같은 UI 존재 테스트를 PR에 남길 이유가 분명합니다.
- [ ] asset 존재 여부나 pixel 크기를 unit test로 고정하지 않았습니다.
- [ ] unit test를 위해 accessibility metadata나 view tag를 제품 코드에 추가하지 않았습니다.
- [ ] framework 내부를 보기 위해 private 접근이나 test-only production API를 추가하지 않았습니다.
- [ ] 이번에 미룬 검증이 있다면 다시 열 조건과 후속 테스트 범위를 기록했습니다.
- [ ] TDD 중 임시 테스트와 오래 남길 regression 테스트를 구분했습니다.
- [ ] 주석은 제품 이유를 설명할 때만 남겼습니다.
