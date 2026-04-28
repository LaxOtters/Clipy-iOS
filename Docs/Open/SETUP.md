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

## Test

```sh
xcodebuild test \
  -workspace Clipy.xcworkspace \
  -scheme AppMain \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4'
```

로컬에 같은 simulator가 없으면 설치된 iPhone simulator로 바꿔서 실행합니다.

## Generated files

아래 파일은 Tuist가 생성합니다.
직접 수정하거나 commit하지 않습니다.

```plaintext
*.xcodeproj
*.xcworkspace
Derived/
```
