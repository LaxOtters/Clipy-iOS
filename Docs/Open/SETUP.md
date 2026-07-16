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
mise exec -- tuist generate
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

GitHub Actions에서는 `iOS Baseline` workflow가 PR label을 보고 validation profile을 고릅니다.
workflow가 label과 changed files를 준비하고, 실제 검증은 local과 같은 `./scripts/validate_ios_profile.sh`가 실행합니다.
CI도 기본 mode는 `build-for-testing`입니다.
`CoreDesignSystem`이 직접 선택되면 해당 module의 contract test만 simulator에서 실행하고, 다른 module과 AppMain은 `build-for-testing`을 유지합니다.
그 밖의 simulator test는 필요한 PR에서 별도로 확인합니다.

| PR label | CI profile | Scheme |
| --- | --- | --- |
| `TYPE \| Docs` + `AREA \| Docs` | `docs-only` | 없음 |
| `AREA \| Project Setup` | `project-setup` | router 내부 기준 |
| `AREA \| CI` | `ci` | 함께 지정한 검증 scheme |
| `AREA \| AppMain` | `app-main` | 없음 |
| `AREA \| CoreDomain` | `integration` | `CoreDomain` |
| `AREA \| CorePersistence` | `integration` | `CorePersistence` |
| `AREA \| UI System` | `integration` | `CoreDesignSystem` |
| `AREA \| FeatureSession` | `integration` | `FeatureSession` |

검증 scheme이 정해진 AREA는 CI에서 `module`이 아니라 `integration`으로 확인합니다.
해당 module만 build되는지보다 AppMain 조립까지 같이 보는 편이 안전하기 때문입니다.
label이 없거나 지원하지 않는 조합이면 CI는 추정하지 않고 실패합니다.
`AREA | CI`가 검증 scheme이 있는 AREA와 같이 있으면 `ci` profile에서 YAML·AppMain 검증과 해당 module 검증을 같이 실행합니다.
manual dispatch에서 `docs-only`를 고를 때는 changed files 입력도 같이 넘겨야 합니다.

label mapping만 로컬에서 확인할 수도 있습니다.

```sh
CLIPY_IOS_PR_LABELS=$'TYPE | Refactor\nAREA | FeatureSession' \
  ./scripts/resolve_ios_validation_from_labels.sh
```

위 결과를 profile router dry-run에 넘기면 실제 CI가 어떤 검증을 고르는지 build 없이 확인할 수 있습니다.

```sh
CLIPY_IOS_VALIDATION_PROFILE=integration \
CLIPY_IOS_VALIDATION_SCHEMES=FeatureSession \
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
