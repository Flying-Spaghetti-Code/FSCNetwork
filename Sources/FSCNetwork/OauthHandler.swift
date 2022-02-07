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
    func refreshToken(callback: ((Bool)->())?)
}

// MARK: - default is: authentication not needed
public extension OAuthHandler {
    var needAuthentication: Bool { return false }
    var token: String? { return nil }
    func refreshToken(callback: ((Bool)->())?) { /* do nothing */ }
}

