//
//  UIImageView+Extensions.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Tyler Angert on 8/4/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    func transitionImage(newImage: String) {
        UIView.transition(with: self,
                          duration: 0.2,
                          options: .transitionCrossDissolve,
                          animations: { self.image = UIImage(named: newImage) },
                          completion: nil)
    }
}
