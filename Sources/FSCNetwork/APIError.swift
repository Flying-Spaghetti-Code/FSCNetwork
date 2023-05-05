//
//  APIError.swift
//  FSCNetwork
//
//  Created by Giovanni Trovato on 05/01/22.
//  Copyright © 2022 Flying Spaghetti Code. All rights reserved.
//

import Foundation

public enum NetworkError: Error {
    case noInternet
    case serverFailure(withHTTPCode: Int, rawData: Data)
    case failedToParse(body: String)
    case failedtoRefreshToken
    case aborted
    case maxAttemptsExceeded
    case noData
    case custom(message: String)
}


extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .noInternet: return "No internet connection"
            case .noData: return "Server response is empty"
            case .serverFailure(withHTTPCode: let withHTTPCode): return "Unable to get data! http code: \(withHTTPCode)"
            case .failedToParse(let body): return "Failed to parse data: \(body)"
            case .failedtoRefreshToken: return "Unable to refresh token"
            case .maxAttemptsExceeded: return "Max number of authentication attempts exceeded"
            case .custom(let message): return "\(message)"
            case .aborted: return "Call aborted"
        }
    }
}

extension NetworkError {
    public var rawBody: Data? {
        switch self {
            case .serverFailure(_ , let data): return data
            default: return nil
        }
    }
}
