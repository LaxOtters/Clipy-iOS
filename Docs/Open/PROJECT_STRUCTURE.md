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

## Tuist 기준 파일

- `Workspace.swift`
- `Tuist.swift`
- `Tuist/ProjectDescriptionHelpers/*`
- `Modules/*/Project.swift`

생성된 `.xcodeproj`, `.xcworkspace`는 기준 파일로 보지 않습니다.
