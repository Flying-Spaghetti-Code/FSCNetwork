//
//  NetworkRequest.swift
//  FSCNetwork
//
//  Created by Giovanni Trovato on 11/06/2020.
//  Copyright © 2020 Flying Spaghetti Code. All rights reserved.
//

import Foundation

public protocol NetworkRequest: OAuthHandler{
    var url: String {get}
    var method: HTTPMethod {get}
    var body: Data? {get}
    var eTag: String? { get }
    var customHeaders: [String : String]? { get }
    var sessionDelegate: URLSessionDelegate & URLSessionTaskDelegate { get }
    func getETagDataIfAvailable(_ response: HTTPURLResponse, _ data: Data) -> Data?
    func isResponseValid(_ response: HTTPURLResponse, with networkManager: NetworkManager, completion: @escaping NetCallBack) -> Bool
}

public extension NetworkRequest {
    // default values
    var body : Data? { nil }
    var customHeaders : [String : String]? { nil }
    
    func isResponseValid(_ response: HTTPURLResponse, with networkManager: NetworkManager, completion: @escaping NetCallBack) -> Bool {
        return true
    }
    
}

public enum HTTPMethod : String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
}
