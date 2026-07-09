//
//  Item.swift
//  TouToiMoment
//
//  Created by 森田有美子 on 2026/07/09.
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
