//
//  WaitingRequestQueue.swift
//  
//
//  Created by Giovanni Trovato on 29/04/22.
//

import Foundation

class WaitingRequestQueue {
    
    public static let instance = WaitingRequestQueue()
    private let dispatcher = DispatchQueue(label: "thread-safe-queue", attributes: .concurrent)
    private var elements : [(request: NetworkRequest, completion: NetCallBack)] = []

    private init () {}
    
    func enqueue(_ request: NetworkRequest, _ completion: @escaping NetCallBack) {
        dispatcher.async(flags: .barrier) {
            print("WaitingRequestQueue - Enqueuing \(request.url) ")
            self.elements.append((request, completion))
        }
    }
    
    func dequeue() -> (request: NetworkRequest, completion: NetCallBack)? {
        dispatcher.sync(flags: .barrier) {
            guard !elements.isEmpty else {
                print("WaitingRequestQueue - The request queue is empty")
                return nil
            }
            let element = elements.removeFirst()
            print("WaitingRequestQueue - Dequeuing \(element.request.url) ")
            return element
        }
    }
}
