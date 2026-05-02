# Clipy iOS Docs

이 폴더는 Clipy iOS 작업에 필요한 문서를 모아두는 곳입니다.
공개 repo에는 실행, 구조, 코드 기준, 테스트 기준처럼 외부에서 읽어도 되는 문서만 둡니다.

## 구조

```plaintext
Docs/
  Open/   공개 repo에 같이 올릴 수 있는 문서
```

## Open

`Docs/Open/`에는 repo를 처음 보는 개발자가 project를 실행하고 구조를 이해하는 데 필요한 내용만 둡니다.

- `Open/SETUP.md` — 로컬 환경 준비, project 생성, test 실행
- `Open/PROJECT_STRUCTURE.md` — 현재 project 구조와 Tuist 기준 파일
- `Open/CODE_CONVENTIONS.md` — 코드 작성 기준
- `Open/TESTING_GUIDE.md` — 테스트 작성 기준

## 내부 문서

Jira, Confluence, Sprint, 결정 기록처럼 팀 내부 맥락이 필요한 문서는 public repo와 분리해서 관리합니다.
공개 문서로 옮길 때는 내부 맥락을 걷어내고 다시 씁니다.
