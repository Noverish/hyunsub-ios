---
paths:
  - 'apps/*API.swift'
---

# 네트워킹 (URLSession + Codable)

API 클라이언트는 `*API.swift` 싱글톤으로 작성한다(예: `TimelineAPI`).

## 패턴

- 요청/응답 모델은 `Codable` 구조체. 인코딩 `JSONEncoder`, `URLSession.shared.dataTask`.
- base URL은 `https://<service>.hyunsub.kim/api/...`. 위치 업로드(`/api/v1/device/timelines/...`)는 `Authorization: Bearer <기기 키>`, 그 밖 API는 쿠키 `HYUNSUB_TOKEN`.
- 실패/상태코드/응답은 `Logger.log(...)`로 남긴다.

```swift
struct TimelineCreateParams: Codable { let timestamp: Int64; let latitude: Double /* ... */ }

class TimelineAPI {
    static let shared = TimelineAPI()
    private let baseURL = "https://timeline.hyunsub.kim/api/v1/timelines"
    func sendTimeline(params: TimelineCreateParams) {
        var request = URLRequest(url: ...)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(params)
        URLSession.shared.dataTask(with: request) { data, response, error in /* Logger.log */ }.resume()
    }
}
```

## ⚠️ 시크릿

- **토큰/자격증명을 소스에 하드코딩하지 않는다.** 위치 업로드는 Keychain의 기기 키(`DeviceKeyStore`)를 `Authorization: Bearer`로 보낸다.
- 신규 토큰도 Keychain 저장 또는 웹뷰 브리지/로그인 흐름으로 주입한다.

❌ Bad
```swift
private let token = "<소스에 박은 토큰 문자열>"   // ❌ 소스/깃 히스토리에 시크릿 노출
```
✅ Good — Keychain 등에서 주입
```swift
guard let key = DeviceKeyStore.shared.load() else { return }
```
**Why:** 소스에 박힌 토큰은 깃 히스토리·바이너리에서 추출 가능하고, 폐기/회전이 불가능하다.

<!-- TODO: 인증 토큰의 정식 획득 경로(로그인/공유 쿠키), 에러/재시도 정책, 응답 디코딩이 필요한 API가 생길 때의 표준 -->
