//
//  ProgressiveProperty.swift
//  Recyclone
//
//  Created by Evan Huang on 1/7/21.
//

import Foundation
import SpriteKit

enum ProgressionMode {
    case multiply
    case add
}

struct Progressor {
    var progressionMode: ProgressionMode
    var value: CGFloat
    private var apply: (CGFloat, CGFloat) -> CGFloat
    private var deapply: (CGFloat, CGFloat) -> CGFloat
    
    init(increaseBy value: CGFloat, how progressionMode: ProgressionMode) {
        self.value = value
        self.progressionMode = progressionMode
        
        switch progressionMode {
        
        case ProgressionMode.multiply :
            self.apply = { (propertyValue, progressorValue) -> CGFloat in
                return propertyValue * progressorValue
            }
            
            self.deapply = { (propertyValue, progressorValue) -> CGFloat in
                return propertyValue / progressorValue
            }
        case ProgressionMode.add :
            self.apply = { (propertyValue, progressorValue) -> CGFloat in
                return propertyValue + progressorValue
            }
            
            self.deapply = { (propertyValue, progressorValue) -> CGFloat in
                return propertyValue - progressorValue
            }
        }
    }
    
    func apply(on value: CGFloat) -> CGFloat {
        return self.apply(value, self.value)
    }
    
    func deapply(on value: CGFloat) -> CGFloat {
        return self.deapply(value, self.value)
    }
}

//this should probably be in another struct
typealias ConditionalCallback = () -> Void
typealias Condition = (ProgressiveProperty) -> Bool
class ProgressiveProperty {
    var value: CGFloat
    var callback: ConditionalCallback?
    var condition: Condition?
    var progressor: Progressor
    
    init(startingAt value: CGFloat, progressor: Progressor, callback: ConditionalCallback? = nil, when condition: Condition? = nil ){ //add default somehow
        self.value = value
        self.progressor = progressor
        self.callback = callback
        self.condition = condition
    }
    
    convenience init(startingAt propertyValue: CGFloat, increaseBy progressionValue: CGFloat, how progressionMode: ProgressionMode) {
        let progressor = Progressor(increaseBy: progressionValue, how: progressionMode)
        self.init(startingAt: propertyValue, progressor: progressor)
    }
    
    func progressValue(count: Int = 1) {
        for _ in 0..<count {
            self.value = progressor.apply(on: self.value)
            if let condition = self.condition,
               let callback = self.callback {
                if condition(self) {
                    callback()
                }
            }
        }
    }
    
    func regressValue(count: Int = 1) {
        for _ in 0..<count {
            self.value = progressor.deapply(on: self.value)
        }
    }
}
