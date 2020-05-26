//
//  UIViewController+Extensions.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Chrystian Vieyra on 1/22/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import UIKit

extension UIViewController {
    func alert(title: String?, message: String? = nil, completionHandler: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) -> Void in
            completionHandler?()
        }))
        present(alertController, animated: true, completion: nil)
    }
}
