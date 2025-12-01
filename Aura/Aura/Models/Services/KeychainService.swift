//
//  KeychainService.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 25/11/2025.
//

import Security
import Foundation

/// A small utility for storing and retrieving string values in the Keychain.
///
/// This file exposes a lightweight `Keychain` helper that saves simple
/// string values under a given account key using the Generic Password class.
/// It also defines `KeychainError` to surface common failure cases.
enum KeychainError: Error {
    /// Errors that can occur when interacting with the Keychain.
    /// - unexpectedStatus: Wraps a non-success `OSStatus` returned by Security APIs.
    /// - dataEncodingFailed: Failed to encode a `String` into UTF-8 `Data`.
    /// - dataDecodingFailed: Failed to decode UTF-8 `Data` back into a `String`.
    case unexpectedStatus(OSStatus)
    case dataEncodingFailed
    case dataDecodingFailed
}

/// A convenience wrapper around the Keychain for simple string storage.
///
/// Values are saved and looked up using the Generic Password class (`kSecClassGenericPassword`)
/// with the provided `key` mapped to the `kSecAttrAccount` attribute.
struct Keychain {
    /// Stores a string value in the Keychain for the specified account key.
    ///
    /// If an item already exists for the same key, it is removed before inserting the new value.
    /// - Parameters:
    ///   - value: The string to store.
    ///   - key: The account key under which to store the value.
    /// - Throws: `KeychainError.dataEncodingFailed` if the string cannot be encoded as UTF-8,
    ///           or `KeychainError.unexpectedStatus` if the Security API returns an error.
    static func set(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.dataEncodingFailed }
        
        // Delete any existing value for this key
        let queryDelete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(queryDelete as CFDictionary)
        
        // Add the new value
        let queryAdd: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(queryAdd as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }
    
    /// Retrieves a string value from the Keychain for the specified account key.
    ///
    /// - Parameter key: The account key under which the value was stored.
    /// - Returns: The stored string if found, or `nil` if no item exists for the key.
    /// - Throws: `KeychainError.unexpectedStatus` if the Security API returns an error,
    ///           or `KeychainError.dataDecodingFailed` if the data cannot be decoded as UTF-8.
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

