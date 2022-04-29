//
//  File.swift
//  
//
//  Created by Giovanni Trovato on 07/02/22.
//

import Foundation

public protocol OAuthHandler {
    var needAuthentication: Bool {get}
    var token: String? { get }
    func refreshToken(callback: ((TokenResponse)->())?)
}

public enum TokenResponse{
    case refreshed
    case aborted
    case failed
}

// MARK: - default is: authentication not needed
public extension OAuthHandler {
    var needAuthentication: Bool { return false }
    var token: String? { return nil }
    func refreshToken(callback: ((Bool)->())?) { /* do nothing */ }
}

