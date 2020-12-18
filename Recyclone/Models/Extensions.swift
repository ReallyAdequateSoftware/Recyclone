//
//  Extensions.swift
//  Recyclone
//
//  Created by Evan Huang on 12/17/20.
//

import Foundation

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
