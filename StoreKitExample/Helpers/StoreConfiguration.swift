//
//  StoreConfiguration.swift
//  StoreKitExample
//
//  Created by Artem Grebinik on 26.07.2022.
//

import Foundation

typealias ProductId = String

struct StoreConfiguration {
    
    static func readConfigFile() ->Set<ProductId>? {
        
        guard let result = PropertyFile.read(filename: Constants.ConfigFile) else {
            return nil
        }
        
        guard result.count > 0 else {
            return nil
        }
        
        guard let values = result[Constants.ConfigFile] as? [String] else {
            return nil
        }
        
        return Set<ProductId>(values.compactMap { $0 })
    }
}
