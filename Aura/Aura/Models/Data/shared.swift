//
//  Transaction.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 26/11/2025.
//

/// Represents a simple transaction that can be displayed in the UI.
/// - Parameters:
///   - label: A user-readable label (e.g., "Coffee").
///   - value: A formatted value (e.g., "-€3.50").
struct Transaction {
    let label: String   // Transaction label
    let value: String   // Displayed amount or value
}

/// Possible errors when performing HTTP calls.
/// Provides specific cases to help diagnose and present issues to the user.
enum HTTPError: Error {
    // The provided URL is invalid
    case invalidURL
    // Non-2xx HTTP status with optional code and message
    case badStatus(code: Int, message: String?)
    // Failed to decode the response (JSON, etc.)
    case decodingFailed(underlying: Error)
    // Unclassified error
    case unknown                                     // Unclassified error
}

