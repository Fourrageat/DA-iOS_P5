//
//  KeychainService.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 25/11/2025.
//

import Security
import Foundation

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
    case dataEncodingFailed
    case dataDecodingFailed
}

struct Keychain {
    static func set(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.dataEncodingFailed }
        
        // Supprimer une éventuelle valeur existante
        let queryDelete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(queryDelete as CFDictionary)
        
        // Ajouter la nouvelle valeur
        let queryAdd: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(queryAdd as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }
    
    static func get(_ key: String) throws -> String? {
        let queryGet: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(queryGet as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let value = String(data: data, encoding: .utf8) else { throw KeychainError.dataDecodingFailed }
        return value
    }
}
