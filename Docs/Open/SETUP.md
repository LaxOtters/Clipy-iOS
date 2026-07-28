# Setup

Clipy iOS는 Tuist와 mise로 project 환경을 맞춥니다.

## 준비

```sh
mise trust
mise install
mise exec -- tuist version
```

현재 Tuist 버전은 `4.188.0`입니다.

## Project 생성

```sh
mise exec -- tuist generate --no-open
```

## Baseline 검증

project 생성과 기본 app scheme build를 한 번에 확인할 때는 아래 script를 씁니다.

```sh
./scripts/validate_ios_baseline.sh
```

script는 기본으로 `AppMain` scheme의 `build-for-testing`을 실행합니다.
simulator를 띄우지 않아서 빠르게 확인할 수 있습니다.
AppMain이 의존하는 module도 이 흐름에서 함께 build됩니다.

실제로 test를 실행해야 할 때는 `CLIPY_IOS_VALIDATION_MODE=test`를 같이 지정합니다.

```sh
CLIPY_IOS_VALIDATION_MODE=test \
  ./scripts/validate_ios_baseline.sh
```

## 작업 유형별 검증

작업 범위가 명확하면 profile을 골라 필요한 검증만 실행할 수 있습니다.
profile은 검증 방식과 비용을 정하고, module 대상은 `CLIPY_IOS_VALIDATION_SCHEMES`로 넘깁니다.
profile router는 기본으로 `build-for-testing`을 사용합니다.
일반 profile에서 simulator test까지 실행하려면 `CLIPY_IOS_VALIDATION_MODE=test`를 명시합니다.
다만 `CoreDesignSystem`을 직접 선택한 기본 profile은 font와 resource 계약을 확인하기 위해 해당 module test만 실행합니다.
build가 필요한 profile은 `tuist install`과 `tuist generate`를 한 번 실행한 뒤, 선택된 scheme 검증을 이어서 실행합니다.

```sh
CLIPY_IOS_VALIDATION_PROFILE=integration \
CLIPY_IOS_VALIDATION_SCHEMES=FeatureSession \
  ./scripts/validate_ios_profile.sh
```

지원하는 profile은 아래와 같습니다.

| Profile | 주로 쓰는 경우 |
| --- | --- |
| `docs-only` | 공개 문서와 GitHub template만 변경 |
| `tuist-foundation` | Tuist manifest 규칙과 generated artifact 확인 |
| `app-main` | AppMain 조립이나 app entry 변경 |
| `module` | 지정한 module scheme만 확인 |
| `integration` | 지정한 module scheme과 AppMain 조립을 함께 확인 |
| `project-setup` | Tuist manifest, module 구조, project 설정 변경 |
| `ci` | GitHub Actions나 validation 흐름 변경 |

`module`과 `integration`은 scheme을 같이 넘깁니다.

```sh
CLIPY_IOS_VALIDATION_PROFILE=module \
CLIPY_IOS_VALIDATION_SCHEMES="CoreDomain CorePersistence" \
  ./scripts/validate_ios_profile.sh
```

어떤 command가 선택되는지만 보고 싶을 때는 dry-run을 씁니다.

```sh
CLIPY_IOS_VALIDATION_PROFILE=project-setup \
CLIPY_IOS_VALIDATION_DRY_RUN=1 \
  ./scripts/validate_ios_profile.sh
```

`docs-only` profile은 변경 파일을 명시해야 합니다.

```sh
CLIPY_IOS_VALIDATION_PROFILE=docs-only \
CLIPY_IOS_CHANGED_FILES=$'Docs/Open/SETUP.md\nDocs/Open/PROJECT_STRUCTURE.md' \
  ./scripts/validate_ios_profile.sh
```

`docs-only`는 iOS build를 생략하는 대신, 입력된 파일이 문서나 GitHub template인지 확인합니다.
generated artifact 확인은 tracked file 기준의 preflight입니다.
PR을 올리기 전에는 `git status --short`로 untracked 생성물이 섞였는지도 따로 봅니다.

## Test

test를 직접 실행할 때는 AppMain scheme을 지정합니다.

```sh
xcodebuild test \
  -workspace Clipy.xcworkspace \
  -scheme AppMain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4'
```

로컬에 같은 simulator가 없으면 설치된 iPhone simulator로 바꿔서 실행합니다.

## CI

GitHub Actions에서는 `iOS Baseline` workflow가 PR label과 changed files에서 필요한 검증을 각각 찾습니다.
두 결과를 중복 없는 capability 집합으로 합친 뒤, 실제 검증은 local과 같은 `./scripts/validate_ios_profile.sh`가 실행합니다.
CI도 기본 mode는 `build-for-testing`입니다.
`CoreDesignSystem`이 직접 선택되면 해당 module의 contract test만 simulator에서 실행하고, 다른 module과 AppMain은 `build-for-testing`을 유지합니다.
그 밖의 simulator test는 필요한 PR에서 별도로 확인합니다.

| PR label | 추가되는 검증 |
| --- | --- |
| `AREA \| Docs` | 다른 검증이 없을 때 문서 경로와 generated artifact 확인 |
| `AREA \| Project Setup` | Tuist 정책, 전체 module, AppMain |
| `AREA \| CI` | Tuist 정책, routing contract, workflow YAML, AppMain |
| `AREA \| AppMain` | AppMain |
| `AREA \| CoreDomain` | `CoreDomain`, AppMain |
| `AREA \| CorePersistence` | `CorePersistence`, AppMain |
| `AREA \| UI System` | `CoreDesignSystem` contract test, AppMain |
| `AREA \| FeatureHome` | `FeatureHome`, AppMain |
| `AREA \| FeatureSession` | `FeatureSession`, AppMain |

최종 범위는 `label 요구사항 ∪ changed-file 요구사항`입니다.
같은 검증은 한 번만 실행하고, 같은 module에 `build`와 `test`가 함께 잡히면 `test`만 남깁니다.
`AREA | Docs`는 코드나 CI 범위가 함께 있으면 build 범위를 줄이지 않습니다.
label보다 넓은 파일 변경이 발견되면 changed files 쪽 요구사항을 추가합니다.
PR changed files는 rename을 delete/add 양쪽 경로로 풀고 NUL 구분자로 전달합니다.
module 사이에서 파일을 옮기거나 한글 파일명을 써도 기존 경로와 새 경로를 그대로 검증 범위에 반영합니다.
`.swiftlint.yml`이 바뀌면 저장소 기본 도구만으로 YAML 형식을 확인합니다.
SwiftLint 실행은 아직 저장소 toolchain과 CI 계약에 포함하지 않습니다.
지원하지 않는 label이나 mapping이 없는 경로는 좁은 검증으로 추정하지 않고 실패합니다.
`TYPE | Docs`인데 코드성 capability가 발견되는 조합도 분류 오류로 실패합니다.
manual dispatch에서 `docs-only`를 고를 때는 changed files 입력도 같이 넘겨야 합니다.

label mapping만 로컬에서 확인할 수도 있습니다.

```sh
CLIPY_IOS_PR_LABELS=$'TYPE | Refactor\nAREA | FeatureSession' \
  ./scripts/resolve_ios_validation_from_labels.sh
```

위 결과의 `CLIPY_IOS_VALIDATION_CAPABILITIES`를 profile router dry-run에 넘기면 실제 CI plan을 build 없이 확인할 수 있습니다.

```sh
CLIPY_IOS_VALIDATION_PROFILE=capabilities \
CLIPY_IOS_VALIDATION_CAPABILITIES=module:FeatureSession:build \
CLIPY_IOS_VALIDATION_DRY_RUN=1 \
  ./scripts/validate_ios_profile.sh
```

## Generated files

아래 파일은 Tuist가 생성합니다.
직접 수정하거나 commit하지 않습니다.

```plaintext
*.xcodeproj
*.xcworkspace
Derived/
```
