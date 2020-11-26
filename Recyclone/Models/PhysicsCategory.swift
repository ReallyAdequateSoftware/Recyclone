//
//  PhysicsCategory.swift
//  Recyclone
//
//  Created by Evan Huang on 11/25/20.
//

import Foundation

struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let boundary  : UInt32 = 0b1
    static let item      : UInt32 = 0b10
    
}
