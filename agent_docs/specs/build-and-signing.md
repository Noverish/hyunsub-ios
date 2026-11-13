# 빌드 · 서명 · 권한 (spec)

`apps.xcodeproj/project.pbxproj`에서 추출한 값.

## 타깃

| 항목 | 값 |
|---|---|
| 타깃 / 스킴 | `apps` (스킴은 공유 안 됨 — xcuserdata에만) |
| 번들 ID | `kim.hyunsub.apps` (테스트: `kim.hyunsub.appsTests`, UI테스트: `kim.hyunsub.appsUITests`) |
| iOS Deployment Target | 16.1 |
| Swift 버전 | 5.0 |
| Marketing Version | 1.0 / 1.0.0 |
| Development Team | `28A4E58A28` (pbxproj에 하드코딩) |

## 의존성

- 외부 패키지 **없음**(SPM `Package.swift`·CocoaPods `Podfile` 모두 없음). 시스템 프레임워크만: SwiftUI, UIKit, WebKit, CoreLocation, Foundation.
- 따라서 진입점은 `.xcodeproj`다(`.xcworkspace` CocoaPods 통합 아님).

## Info.plist 권한 / 설정

| 키 | 값 | 의미 |
|---|---|---|
| `NSLocationAlwaysAndWhenInUseUsageDescription` | (한국어 문구) | 백그라운드 위치 추적 |
| `NSLocationWhenInUseUsageDescription` | (한국어 문구) | 위치 기반 서비스 |
| `UIBackgroundModes` | `[location]` | 백그라운드 위치 |
| `NSAppTransportSecurity.NSAllowsArbitraryLoads` | `true` | ATS 비활성(임의 HTTP) |

## 빌드 명령

```bash
xcodebuild -list -project apps.xcodeproj           # 사용 가능한 스킴 확인
xcodebuild -project apps.xcodeproj -scheme apps -destination 'generic/platform=iOS' build
xcodebuild -project apps.xcodeproj -scheme apps -destination 'platform=iOS Simulator,name=iPhone 15' test
```

<!-- TODO: 서명 방식(자동/수동, 프로비저닝 프로파일), 배포 채널(TestFlight/Ad-hoc), App Store 메타데이터 관리 주체. CI가 없으므로 릴리스는 수동 Xcode Archive로 추정 -->

## 앱 아이콘·스플래시

- **앱 아이콘**(`Assets.xcassets/AppIcon.appiconset/*.png`, 알파 없는 RGB)과 **스플래시 이미지**(`hyunsub_spash.imageset/hyunsub_spash.png`, 1290×2796, 보라 그라데이션 전체 + 가운데 흰 `fa-instalod`)는 손으로 만들지 않고 web repo의 `scripts/brand/generate.mjs --ios <Assets.xcassets 경로>`가 만든다(사용법은 스크립트 머리 주석, 디자인 규칙은 web design-system.md "서비스 로고와 favicon").
- `LaunchScreen.storyboard`는 이 이미지를 전체 화면에 `scaleAspectFill`로 깐다. 기기 비율이 달라도 가운데 글리프는 유지된다.
- iOS는 런치 스크린을 캐시한다. 바뀐 스플래시가 안 보이면 앱을 지우고 다시 설치한다.
