# Setup

Clipy iOS는 Tuist와 mise로 project를 맞춥니다.

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

project 생성과 AppMain test를 한 번에 확인할 때는 아래 script를 씁니다.

```sh
./scripts/validate_ios_baseline.sh
```

script는 기본으로 사용 가능한 iPhone simulator를 찾아 `AppMain` scheme test를 실행합니다.
필요하면 destination을 직접 지정할 수 있습니다.

```sh
CLIPY_IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' \
  ./scripts/validate_ios_baseline.sh
```

## Test

```sh
xcodebuild test \
  -workspace Clipy.xcworkspace \
  -scheme AppMain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4'
```

로컬에 같은 simulator가 없으면 설치된 iPhone simulator로 바꿔서 실행합니다.

## CI

GitHub Actions에서는 `iOS Baseline` workflow가 같은 baseline script를 실행합니다.
CI도 Tuist manifest를 기준으로 project를 생성하고 `AppMain` test를 확인합니다.

## Generated files

아래 파일은 Tuist가 생성합니다.
직접 수정하거나 commit하지 않습니다.

```plaintext
*.xcodeproj
*.xcworkspace
Derived/
```
