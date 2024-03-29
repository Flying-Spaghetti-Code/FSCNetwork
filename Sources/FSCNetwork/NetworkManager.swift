//
//  NetworkManager.swift
//  FSCNetwork
//
//  Created by Giovanni Trovato on 28/05/2020.
//  Copyright © 2020 Flying Spaghetti Code. All rights reserved.
//

import Foundation
import OSLog

public typealias NetCallBack = (Result<Data, NetworkError>) -> (Void)
public typealias NetCallReply = Result<Data, NetworkError>

public class NetworkManager: NSObject{
    
    private var currentTask: URLSessionDataTask?
    private var maxAttempts: Int
    private var attempts: Int
    
    public init(maxAttempts : Int = 2 ){
        self.maxAttempts = maxAttempts
        self.attempts = maxAttempts
    }
    
    deinit {
        log.debug("[RETAIN] - NetworkManager was deinit")
    }
    
    fileprivate func handleAuthentication(_ handler: NetworkRequest, _ completion: @escaping NetCallBack, _ urlRequest: inout URLRequest) {
        if handler.needAuthentication {
            guard let token = handler.token else {
                cancelCurrentTaskIfRunning()
                handleTokenRefresh(request: handler, completion: completion)
                return
            }
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    public func fire(request: NetworkRequest, completion: @escaping NetCallBack){
        
        let urlString = "\(request.url)"
        
        log.debug("Calling: \(urlString)")
        guard let callURL = URL(string: urlString) else {
            log.error("Tried to call an invalid URL at '\(urlString)'")
            completion(.failure(.aborted))
            return
        }
        var urlRequest = URLRequest(url: callURL)
        handleAuthentication(request, completion, &urlRequest)
        
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setCustomHeaders(request.customHeaders)
        urlRequest.httpBody = request.body
        urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        if let etag = request.eTag {
            urlRequest.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        log.debug("Request Body: \(request.body.decoded)")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        if case .post = request.method {
            urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        
        let config = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: config, delegate: request.sessionDelegate, delegateQueue: nil)
        cancelCurrentTaskIfRunning()
        currentTask = urlSession.dataTask(with: urlRequest) { data, response, error in
            
            // check if the request was cancelled in the meantime
            if let error = error as NSError?, error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                // task was cancelled
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                completion(.failure(.noData))
                return
            }
            
            if response.statusCode == 401 {
                self.cancelCurrentTaskIfRunning()
                self.handleTokenRefresh(request: request, completion: completion)
                return
            }

            guard (200 ... 299) ~= response.statusCode || response.statusCode == 304 else {
                var message = "Server responded with error code \(response.statusCode) to request \(request) at: \(urlString)"
                message.append("\n \(urlRequest.formattedString)\(response.formattedString(for: data))\n")
                log.error("\(message)")
                completion(.failure(.serverFailure(withHTTPCode: response.statusCode, rawData: data)))
                return
            }
            
            if let cachedData = request.getETagDataIfAvailable(response, data) {
                completion(.success(cachedData))
                return
            }
            
            guard request.isResponseValid(response, with: self, completion: completion) else{
                return
            }
                        
            // if everything is fine the counter can be resetted
            self.attempts = self.maxAttempts
            log.debug("\(response.formattedString(for: data))")
            completion(.success(data))
        
        }
        currentTask?.resume()
    }
    
    public func cancelCurrentTaskIfRunning(){
        if currentTask?.state == .running {
            currentTask?.cancel()
        }
    }
    
    private func handleTokenRefresh(request: NetworkRequest, completion: @escaping NetCallBack) {
        let queue = WaitingRequestQueue.instance
        queue.enqueue(request, completion)
        if self.attempts > 0 {
            request.refreshToken { (response) in
                switch response {
                    case .refreshed :
                        self.attempts -= 1
                        while let element = queue.dequeue() {
                            log.info("Token refreshed. Refiring the call")
                            self.fire(request: element.request, completion: element.completion)
                        }
                    case .aborted : break
                    case .failed : completion(.failure(.failedtoRefreshToken))
                }
            }
        } else {
            completion(.failure(.maxAttemptsExceeded))
        }
    }
    
    public func fire(request: NetworkRequest) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            fire(request: request) { result in
                switch result {
                    case .success(let data): continuation.resume(returning: data)
                    case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }    
}

extension URLRequest {
    mutating func setCustomHeaders(_ headersDictionary : [String : String]?) {
        headersDictionary?.forEach { key, value in
            setValue(value, forHTTPHeaderField: key)
        }
    }
}


