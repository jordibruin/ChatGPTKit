//
//  File.swift
//  
//
//  Created by Sai Kambampati on 3/1/23.
//

import Foundation

// Enums
public enum Model: String, CaseIterable, Identifiable {
    // Base
    case turbo = "gpt-3.5-turbo"
    case turbo31 = "gpt-3.5-turbo-0301"
    case gpt4 = "gpt-4"
    
    var id: String { self.rawValue }
}
