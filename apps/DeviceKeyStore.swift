//
//  DeviceKeyStore.swift
//  apps
//

import Foundation
import Security

/// 위치 업로드 전용 기기 키(`hsdk_…`)를 Keychain에 보관한다.
/// 백그라운드 위치 이벤트로 앱이 깨어났을 때(기기 잠금 해제 이후)도 읽을 수 있고, 백업·다른 기기로는 옮겨지지 않는다.
final class DeviceKeyStore {
    static let shared = DeviceKeyStore()

    static let keyPrefix = "hsdk_"

    private let service = "kim.hyunsub.apps.deviceKey"
    private let account = "timeline"

    private init() {}

    func load() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                Logger.log("Keychain load failed: status=\(status)")
            }
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    func save(_ key: String) -> Bool {
        guard key.hasPrefix(Self.keyPrefix), let data = key.data(using: .utf8) else {
            Logger.log("Device key rejected: invalid format")
            return false
        }

        let updateStatus = SecItemUpdate(
            baseQuery() as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecSuccess {
            return true
        }

        var addQuery = baseQuery()
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus != errSecSuccess {
            Logger.log("Keychain save failed: status=\(addStatus)")
        }
        return addStatus == errSecSuccess
    }

    func delete() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
