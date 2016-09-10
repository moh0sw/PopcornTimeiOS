//
//  BorderButton.swift
//  PopcornTime
//
//  Created by Alex on 10/09/2016.
//  Copyright © 2016 Popcorn Time. All rights reserved.
//

import UIKit

@IBDesignable class BorderButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.CGColor
            setTitleColor(borderColor, forState: .Normal)
        }
    }
    override var highlighted: Bool {
        didSet {
            updateColor(highlighted, borderColor)
        }
    }
    
    override func tintColorDidChange() {
        if tintAdjustmentMode == .Dimmed {
            updateColor(false)
        } else {
            updateColor(false, borderColor)
        }
    }
    
    func updateColor(highlighted: Bool, _ color: UIColor? = nil) {
        UIView.animateWithDuration(0.25) {
            if highlighted {
                self.backgroundColor =  color ?? self.tintColor
                self.layer.borderColor = color?.CGColor ?? self.tintColor?.CGColor
                self.setTitleColor(UIColor.whiteColor(), forState: .Highlighted)
            } else {
                self.backgroundColor = UIColor.clearColor()
                self.layer.borderColor = color?.CGColor ?? self.tintColor?.CGColor
                self.setTitleColor(color ?? self.tintColor, forState: .Normal)
            }
        }
    }
}