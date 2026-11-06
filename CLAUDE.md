# hyunsub-ios

Hyunsub의 **iOS 앱** (SwiftUI). 두 가지 일을 한다: (1) `apps.hyunsub.kim`을 띄우는 **WKWebView 쉘**, (2) **백그라운드 위치 추적기** — 의미 있는 위치 변화를 timeline API로 PUT 전송. 외부 패키지 의존성 없음(SwiftUI + Foundation + CoreLocation + WebKit).

> 이 문서는 **얇은 라우터**다. 상세 규칙은 [.claude/rules/](.claude/rules/)(파일 편집 시 자동 로드), 심화 레퍼런스는 [agent_docs/](agent_docs/)에 있다.

## Quick Reference

| 알고 싶은 것 | 문서 |
|---|---|
| 앱 실행 흐름·두 책임(WebView/위치)·데이터 흐름 | [agent_docs/maps/architecture.md](agent_docs/maps/architecture.md) |
| 런타임 함정(위치 업로드 기기 키·ATS·백그라운드 위치·scheme) | [agent_docs/maps/gotchas.md](agent_docs/maps/gotchas.md) |
| 빌드/서명/권한 설정값 | [agent_docs/specs/build-and-signing.md](agent_docs/specs/build-and-signing.md) |

## Directory Structure

```
apps.xcodeproj/          # Xcode 프로젝트 (스킴은 xcuserdata에만 — 공유 안 됨)
apps/
├── appsApp.swift        # @main SwiftUI App, UIApplicationDelegateAdaptor 연결
├── AppDelegate.swift    # 실행 시 위치 권한 요청 / 위치 이벤트 기동
├── ContentView.swift    # WKWebView(apps.hyunsub.kim) 래퍼(UIViewRepresentable)
├── LocationManager.swift # CLLocationManager 싱글톤(significant changes, 백그라운드)
├── TimelineAPI.swift    # URLSession 싱글톤, timeline API로 위치 PUT
├── Logger.swift         # 타임스탬프 print 로거
├── Info.plist           # 위치 권한 문구, 백그라운드 모드, ATS
└── Assets.xcassets
appsTests/  appsUITests/ # XCTest (현재 템플릿 스텁)
```

## Commands

```bash
# 빌드 (기기/시뮬레이터)
xcodebuild -project apps.xcodeproj -scheme apps -destination 'generic/platform=iOS' build
# 테스트 (시뮬레이터)
xcodebuild -project apps.xcodeproj -scheme apps -destination 'platform=iOS Simulator,name=iPhone 15' test
```

> 스킴 `apps`가 공유(shared)되어 있지 않다(xcuserdata에만 존재) → 다른 머신/CI에서 `-scheme apps`가 안 보일 수 있다([agent_docs/maps/gotchas.md](agent_docs/maps/gotchas.md)). 일상 작업은 Xcode GUI로도 가능.

## Guides (피드포워드 — 작성 전 참고)

`.claude/rules/*.md`는 매칭 파일 편집 시 자동 로드. 자동 로드가 안 되면 아래 링크로 직접 연다.

| 파일을 편집할 때 | 규칙 |
|---|---|
| `apps/**/*.swift` | [architecture.md](.claude/rules/architecture.md) — SwiftUI 수명주기·싱글톤·위치·WebView·스타일 |
| `apps/*API.swift` | [networking.md](.claude/rules/networking.md) — URLSession·Codable·토큰/시크릿 |

## Sensors (피드백 — 작성 후 검증)

| 센서 | 명령 | 검증 |
|---|---|---|
| 빌드 | `xcodebuild ... build` | 컴파일 |
| 테스트 | `xcodebuild ... test` | XCTest(현재 템플릿 스텁 — 커버리지 없음) |

린트(SwiftLint 등)·CI 워크플로는 **설정되어 있지 않다**.

## Core Conventions

- **싱글톤 매니저**: `LocationManager.shared`, `TimelineAPI.shared`, `Logger`. 위치/네트워크 같은 부수효과는 이 싱글톤들에 모은다.
- **로깅은 `Logger.log(...)`** (파일/라인 자동 포함). `print` 직접 사용 지양.
- **위치 정확도**: `startMonitoringSignificantLocationChanges`(저전력, 백그라운드 부활 가능)를 쓴다 — 연속 GPS가 아니다.
- **WebView**: `ContentView`가 단일 WKWebView로 웹앱을 띄운다(네이티브 화면이 거의 없음). 커스텀 UA에 ` Hyunsub/1.0.0` 부착.

## Key Rules

1. **시크릿을 소스에 하드코딩하지 않는다.** 위치 업로드 인증은 Keychain의 기기 키(`DeviceKeyStore`)를 쓴다 — 토큰을 소스 상수로 두지 말 것. ([.claude/rules/networking.md](.claude/rules/networking.md), [agent_docs/maps/gotchas.md](agent_docs/maps/gotchas.md))
2. **위치 권한/백그라운드 전제**: significant-change 모니터링과 백그라운드 위치는 `Info.plist`(권한 문구 + `UIBackgroundModes: location`)와 "Always" 권한에 의존한다. 권한 흐름을 깨지 말 것.
3. <!-- TODO: 도메인 규칙 — 위치 전송 빈도/배터리 정책, 오프라인 시 버퍼링/재전송 여부, WebView↔네이티브 브리지(JS) 사용 여부 -->

## Tech Stack

SwiftUI · Swift 5.0 · iOS Deployment Target 16.1 · CoreLocation · WebKit(WKWebView) · URLSession. 외부 의존성(SPM/CocoaPods) 없음. 번들 ID `kim.hyunsub.apps`.
