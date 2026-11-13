---
paths:
  - 'apps/**/*.swift'
---

# 아키텍처 & 코드 스타일 (SwiftUI)

## 앱 구성

```
appsApp (@main, App)
  └ UIApplicationDelegateAdaptor → AppDelegate
        └ 실행 시 LocationManager.shared.requestPermission()
  └ WindowGroup { ContentView }            # WKWebView(apps.hyunsub.kim)

LocationManager.shared (CLLocationManagerDelegate)
  └ didUpdateLocations → TimelineCreateParams → TimelineAPI.shared.sendTimeline(...)
```

앱은 **웹뷰 쉘 + 백그라운드 위치 추적**의 두 책임만 갖는다. 네이티브 화면은 `ContentView`(WebView) 하나뿐.

## 싱글톤 매니저

- 부수효과(위치, 네트워크, 로깅)는 `*.shared` 싱글톤에 모은다: `LocationManager.shared`, `TimelineAPI.shared`, `Logger`.
- 새 부수효과를 뷰에 직접 넣지 말고 매니저로 분리한다.

## 위치 추적 규칙

- **`startMonitoringSignificantLocationChanges`** 를 쓴다(연속 GPS 아님 — 저전력, 종료된 앱도 위치 이벤트로 부활).
- 백그라운드 동작 전제: `Info.plist`의 `UIBackgroundModes: [location]`, "Always" 권한. `allowsBackgroundLocationUpdates = true`, `pausesLocationUpdatesAutomatically = false`.
- 권한 변경 콜백(`locationManagerDidChangeAuthorization`)에서 Always/WhenInUse면 모니터링 시작. 이 흐름을 바꾸면 백그라운드 추적이 멈춘다.

## WebView

- `ContentView`의 `UIViewRepresentable`로 `WKWebView`를 감싼다. 커스텀 UA에 ` Hyunsub/1.0.0` 부착, 당겨서 새로고침(웹이 `hyunsubPullToRefresh` 메시지로 페이지별 on/off, 새 문서마다 켜짐으로 초기화), iOS 16.4+에서 `isInspectable`.

## 코드 스타일

- 로깅은 **`Logger.log(...)`** (타임스탬프·파일·라인 자동). `print` 직접 사용 지양.
- Swift 5, SwiftUI 관용구. 외부 의존성 추가는 신중히(현재 0개 — SPM/CocoaPods 미사용).

<!-- TODO: WebView와 네이티브 간 메시지 브리지(WKScriptMessageHandler) 사용 여부, 화면 추가 시 네비게이션 방침 -->
