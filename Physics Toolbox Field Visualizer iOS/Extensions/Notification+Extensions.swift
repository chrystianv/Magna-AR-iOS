//
//  Notification+Extensions.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Tyler Angert on 11/3/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let didReceiveData = Notification.Name("didReceiveData")
    static let didCompleteTask = Notification.Name("didCompleteTask")
    static let completedLengthyDownload = Notification.Name("completedLengthyDownload")
}
