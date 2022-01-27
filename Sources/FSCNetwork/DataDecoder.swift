//
//  DataDecoder.swift
//  ezeep
//
//  Created by Giovanni Trovato on 11/09/2020.
//  Copyright © 2020 Cortado AG. All rights reserved.
//

import Foundation

public extension Optional where Wrapped == Data {
    var decoded: String {
        
        guard let data = self else {
            return "--empty--"
        }
        
        return data.decoded
        
    }
}

public extension Data {
    var decoded: String {
        guard let decodedData = String(data: self, encoding: .utf8) else {
            return "--not decodable as string--"
        }
        return decodedData
    }
}
