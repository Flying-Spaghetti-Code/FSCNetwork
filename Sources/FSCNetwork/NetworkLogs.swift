//
//  NetworkLogs.swift
//  ezeep
//
//  Created by Giovanni Trovato on 04/02/21.
//  Copyright © 2021 Cortado AG. All rights reserved.
//

import Foundation
import OSLog
import UIKit

let log = Logger()

public extension URLRequest{
    var formattedString : String {
        var message = "---REQUEST------------------\n"
        message.append("URL: \(self.url?.description ?? "NO URL")\n")
        message.append("METHOD: \(httpMethod ?? "CUSTOM")\n")
        
        for field in allHTTPHeaderFields ?? [String: String](){
            message.append("\(field.key): \(field.value)\n")
        }
        
        var body = "EMPTY BODY"
        if let bodyData = httpBody,
           let decodedBody = String(data: bodyData, encoding: .utf8){
            body = decodedBody
        }
        
        message.append("\(body)\n")
        message.append("---------------------------\n")
        return message
    }
    
}

public extension HTTPURLResponse{
    private var formattedString : String {
        var message = "---RESPONSE------------------\n"
        message.append("URL: \(url?.description ?? "NO URL")\n")
        message.append("MIME TYPE: \(mimeType ?? "NO MIME TYPE")")
        message.append("STATUS CODE: \(statusCode)\n")
        
        for field in allHeaderFields{
            message.append("\(field.key): \(field.value)\n")
        }
       
        return message
    }
    
    func formattedString(for data: Data) -> String{
        var message = formattedString
        
        var body = "EMPTY BODY"
        if let decodedBody = String(data: data, encoding: .utf8){
            body = decodedBody
        }
        
        message.append("\(body)\n")
        message.append("---------------------------\n")
        return message
    }
}
