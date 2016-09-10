//
//  BlurButton.swift
//  PopcornTime
//
//  Created by Alex on 10/09/2016.
//  Copyright © 2016 Popcorn Time. All rights reserved.
//

import UIKit

@IBDesignable class BlurButton: UIButton {
    
    var backgroundView: UIVisualEffectView
    private var updatedImageView = UIImageView()
    var cornerRadius: CGFloat = 0.0 {
        didSet {
            backgroundView.layer.cornerRadius = cornerRadius
            backgroundView.layer.masksToBounds = cornerRadius > 0
        }
    }
    @IBInspectable var blurTint: UIColor = UIColor.clearColor() {
        didSet {
            backgroundView.contentView.backgroundColor = blurTint
        }
    }
    var blurStyle: UIBlurEffectStyle = .Light {
        didSet {
            backgroundView.effect = UIBlurEffect(style: blurStyle)
        }
    }
    var imageTransform: CGAffineTransform = CGAffineTransformMakeScale(0.5, 0.5) {
        didSet {
            updatedImageView.transform = imageTransform
        }
    }
    
    override init(frame: CGRect) {
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        super.init(frame: frame)
        setUpButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        super.init(coder: aDecoder)
        setUpButton()
    }
    
    func setUpButton() {
        backgroundView.frame = bounds
        backgroundView.userInteractionEnabled = false
        insertSubview(backgroundView, atIndex: 0)
        updatedImageView = UIImageView(image: self.imageView!.image)
        updatedImageView.frame = self.imageView!.bounds
        updatedImageView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        updatedImageView.userInteractionEnabled = false
        self.imageView?.removeFromSuperview()
        addSubview(updatedImageView)
        updatedImageView.transform = imageTransform
        cornerRadius = frame.width/2
    }
    
    override var highlighted: Bool {
        didSet {
            updateColor(highlighted)
        }
    }
    
    func updateColor(tint: Bool) {
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.backgroundView.contentView.backgroundColor = tint ? UIColor.whiteColor() : self.blurTint
            }, completion: nil)
    }
}
