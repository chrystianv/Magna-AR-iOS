//
//  UIView+Extensions.swift
//  Physics Toolbox Field Visualizer iOS
//
//  Created by Tyler Angert on 8/4/19.
//  Copyright © 2019 Vieyra Software. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func addIcon(imageName: String, extraDx: CGFloat = 0, extraDy: CGFloat = 0) {
        let icon = UIImageView(image: UIImage.init(named: imageName))
        self.addSubview(icon)
        icon.frame = icon.frame.offsetBy(dx: self.frame.width/2 - icon.frame.width/2 - extraDx, dy: self.frame.height/2 - icon.frame.height/2 - extraDy)
    }
    
    func blur(with style: UIBlurEffect.Style, alpha: CGFloat, color: UIColor? = nil) {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = alpha
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        blurEffectView.contentView.addSubview(vibrancyView)
        
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let c = color {
            blurEffectView.contentView.backgroundColor = c
        }
        
        // Prevents touches on the parent from being ignored
        blurEffectView.isUserInteractionEnabled = false
        self.insertSubview(blurEffectView, at: 0)
    }
    
    func changeBlurStyle(style: UIBlurEffect.Style) {
        for s in self.subviews {
            if s is UIVisualEffectView {
                let v = s as! UIVisualEffectView
                v.effect = UIBlurEffect(style: style)
            }
        }
    }
    
    func unblur() {
        for subview in self.subviews {
            if subview is UIVisualEffectView {
                subview.removeFromSuperview()
            }
        }
    }
    
    private func addAlignedConstrains() {
        translatesAutoresizingMaskIntoConstraints = false
        addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute.top)
        addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute.leading)
        addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute.trailing)
        addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute.bottom)
    }
    
    private func addAlignConstraintToSuperview(attribute: NSLayoutConstraint.Attribute) {
        superview?.addConstraint(
            NSLayoutConstraint(
                item: self,
                attribute: attribute,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: superview,
                attribute: attribute,
                multiplier: 1,
                constant: 0
            )
        )
    }
    
    func roundCorners(amount: CGFloat) {
        self.layer.cornerRadius = amount
        self.clipsToBounds = true
    }
    func round() {
        self.layer.cornerRadius = self.bounds.width/2
        self.clipsToBounds = true
    }
}
