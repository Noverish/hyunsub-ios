//
//  TimelineAPI.swift
//  apps
//

import Foundation

struct TimelineCreateParams: Codable {
    let timestamp: Int64
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let speed: Double?
    let course: Double?
    let horizontalAccuracy: Double?
    let verticalAccuracy: Double?
    let speedAccuracy: Double?
    let courseAccuracy: Double?
}

class TimelineAPI {
    static let shared = TimelineAPI()

    private let baseURL = "https://timeline.hyunsub.kim/api/v1/device/timelines"

    private init() {}

    func sendTimeline(params: TimelineCreateParams) {
        guard let deviceKey = DeviceKeyStore.shared.load() else {
            Logger.log("Device key not registered — skip sending (timeline 웹의 '위치 기록 기기'에서 등록)")
            return
        }

        let urlString = "\(baseURL)/\(params.timestamp)"
        guard let url = URL(string: urlString) else {
            Logger.log("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(deviceKey)", forHTTPHeaderField: "Authorization")

        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(params)
        } catch {
            Logger.log("Failed to encode params: \(error.localizedDescription)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.log("Request failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                Logger.log("Response status code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    Logger.log("Device key rejected by server — 폐기됐다면 다시 등록 필요 (키는 지우지 않음)")
                }
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                Logger.log("Response: \(responseString)")
            }
        }

        task.resume()
    }
}
