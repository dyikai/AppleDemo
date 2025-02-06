//
//  Item.swift
//  iOSDemo
//
//  Created by 邓壹恺 on 2025-01-07.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
