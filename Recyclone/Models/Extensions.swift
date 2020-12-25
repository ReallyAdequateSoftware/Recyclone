//
//  Extensions.swift
//  Recyclone
//
//  Created by Evan Huang on 12/17/20.
//

import Foundation
import SpriteKit

extension DispatchQueue {
    static func dispatchTask(to qos: DispatchQoS.QoSClass, task: (() -> Void)? = nil, onCompletion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: qos).async {
            task?()
            if let onCompletion = onCompletion {
                DispatchQueue.main.async {
                    onCompletion()
                }
            }
        }
    }
}

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}
