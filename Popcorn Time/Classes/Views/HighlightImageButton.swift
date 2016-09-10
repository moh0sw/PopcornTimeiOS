//
//  HighlightImageButton.swift
//  PopcornTime
//
//  Created by Alex on 10/09/2016.
//  Copyright © 2016 Popcorn Time. All rights reserved.
//

import UIKit

@IBDesignable class HighlightImageButton: UIButton {
    @IBInspectable var highlightedImageTintColor: UIColor = UIColor.whiteColor()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setImage(self.imageView?.image?.withColor(highlightedImageTintColor), forState: .Highlighted)
    }
    
    override func setImage(image: UIImage?, forState state: UIControlState) {
        super.setImage(image, forState: state)
        super.setImage(image?.withColor(highlightedImageTintColor), forState: .Highlighted)
    }
}