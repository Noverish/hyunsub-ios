# 런타임 함정 (gotchas)

각 항목 **문제 → 근본 원인 → 수정 → 감지**.

## 위치 업로드는 기기 키가 없으면 보내지 않는다

- **문제**: 앱을 새로 설치했거나 서버에서 키를 폐기하면 위치가 서버에 쌓이지 않는다(로그에 `Device key not registered` 또는 응답 `401`).
- **근본 원인**: 위치 업로드는 로그인 쿠키가 아니라 **Keychain의 기기 키(`hsdk_…`)** 로 인증한다(`DeviceKeyStore`). 키는 소스에 없고, timeline 웹의 "위치 기록 기기" 화면에서 등록할 때 앱으로 전달된다.
- **수정**: 앱 안에서 timeline 웹 `/device` → "이 기기를 위치 기록 기기로 등록". 폐기도 같은 화면에서 한다. 401이어도 앱은 키를 지우지 않는다(서버 배포 실수로 키를 잃지 않게).
- **감지**: `Logger` 출력의 `Device key …` / `Response status code: 401`.
- **이력**: 예전에는 `TimelineAPI.swift`에 admin JWT가 하드코딩돼 있었다(공개 repo 노출). 소스에서는 제거했고, git 히스토리에 남은 토큰은 서버의 토큰 서명 키를 교체해 무효화한다. `git grep -n "eyJ" apps/` 가 비어 있어야 한다.

## 다른 머신/CI에서 `-scheme apps`가 안 보인다

- **문제**: `xcodebuild -scheme apps`가 "scheme not found".
- **근본 원인**: 스킴이 공유(shared)되지 않고 `apps.xcodeproj/xcuserdata`에만 있다 → 다른 사용자/CI에서 미인식.
- **수정**: Xcode에서 스킴을 "Shared"로 체크해 `xcshareddata/xcschemes`에 커밋하거나, `xcodebuild -list`로 사용 가능한 스킴 확인.

## 백그라운드에서 위치가 안 올라온다

- **문제**: 앱을 내리면 timeline 전송이 멈춘다.
- **근본 원인**: "Always" 권한 미허용, 또는 `UIBackgroundModes: location` 누락, 또는 significant-change 미가용 기기.
- **수정**: 권한 Always 확인, Info.plist 백그라운드 모드 유지, `significantLocationChangeMonitoringAvailable()` 체크. `pausesLocationUpdatesAutomatically=false`·`allowsBackgroundLocationUpdates=true` 유지.
- **감지**: `Logger` 출력에 "Authorization: …" / "Started monitoring …" 확인.

## HTTP 호출이 막히지 않는다(의도된 ATS 비활성)

- **문제**: ATS 위반인데 통과해서 보안 점검에 안 걸림.
- **근본 원인**: `Info.plist`의 `NSAllowsArbitraryLoads = true`로 ATS 전체 비활성.
- **수정**: 모든 통신이 https라면 ATS 예외를 도메인 한정으로 좁히는 것을 검토.

<!-- TODO 후보:
- 위치 전송 실패 시 재시도/버퍼링 없음 — 유실 허용 여부
- WKWebView 캐시 정책(returnCacheDataElseLoad)으로 오래된 웹앱이 뜰 가능성
-->
