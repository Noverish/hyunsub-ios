# 아키텍처 지도

## 실행 흐름

```
appsApp (@main)
  ├ UIApplicationDelegateAdaptor → AppDelegate.application(didFinishLaunching)
  │     ├ LocationManager.shared.requestPermission()        # Always 권한 요청
  │     └ launchOptions[.location] != nil 면                # 위치 이벤트로 부활한 경우
  │           LocationManager.shared.startMonitoringSignificantLocationChanges()
  └ WindowGroup { ContentView }                             # WKWebView(apps.hyunsub.kim)
```

## 두 가지 책임

| 책임 | 구현 | 비고 |
|---|---|---|
| 웹앱 쉘 | `ContentView` → `WKWebView` | `https://apps.hyunsub.kim` 로드, 커스텀 UA `… Hyunsub/1.0.0`, 당겨서 새로고침(웹이 페이지별로 끌 수 있음) |
| 백그라운드 위치 추적 | `LocationManager` + `TimelineAPI` | significant location change → timeline API PUT |

## 위치 데이터 흐름

```
CLLocationManager (significant changes, 백그라운드)
  → LocationManager.didUpdateLocations(location)
      → TimelineCreateParams(timestamp(ms), lat, lng, altitude, speed, course, accuracy...)
          (음수 정확도/속도는 nil 처리)
      → TimelineAPI.shared.sendTimeline(params)
          → PUT https://timeline.hyunsub.kim/api/v1/device/timelines/{timestamp}
             Authorization: Bearer <기기 키>   (Keychain, 없으면 전송 생략 — gotchas 참조)
```

## 기기 키 등록 (웹뷰 → 네이티브)

timeline 웹(`/device`)이 키를 발급받아 `window.webkit.messageHandlers.hyunsubDeviceKey.postMessage(key)`로 넘기면
`DeviceKeyMessageHandler`(ContentView.swift)가 **https://timeline.hyunsub.kim 메인 프레임에서 온 메시지만** 받아 `DeviceKeyStore`(Keychain,
`AfterFirstUnlockThisDeviceOnly`)에 저장한다. 서버는 키의 SHA-256만 보관하고, 키로는 위치 저장(PUT)만 할 수 있다.

## 당겨서 새로고침 켜기/끄기 (웹뷰 → 네이티브)

기본은 켜짐. 전체 화면에 고정된 페이지(chat 등 `HsShell fixed`)는 웹이 `window.webkit.messageHandlers.hyunsubPullToRefresh.postMessage(false)`로 끄고,
벗어날 때 `true`로 되돌린다. `PullToRefreshMessageHandler`(ContentView.swift)는 **https://hyunsub.kim·*.hyunsub.kim 메인 프레임** 메시지만 받는다.
끄면 `scrollView.refreshControl`을 떼고 `bounces`도 꺼서 화면이 끌려 내려오지 않는다. 새 문서가 열리면(`didCommit`) 다시 켜짐으로 돌아간다.

권한 변경 시(`locationManagerDidChangeAuthorization`) Always/WhenInUse면 모니터링을 (재)시작한다.

## 권한·백그라운드 전제 (Info.plist)

- `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationWhenInUseUsageDescription` — 권한 문구.
- `UIBackgroundModes: [location]` — 백그라운드 위치.
- `NSAppTransportSecurity.NSAllowsArbitraryLoads = true` — ATS 비활성(임의 HTTP 허용).

<!-- TODO: WebView와 네이티브(위치/푸시) 사이 연동이 있는지, 앱이 timeline 외 다른 API도 호출하는지 -->
