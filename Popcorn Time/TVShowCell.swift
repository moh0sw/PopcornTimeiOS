//
//  TVShowCoverCell.swift
//  PopcornTime
//
//  Created by Alex on 10/09/2016.
//  Copyright © 2016 Popcorn Time. All rights reserved.
//

import UIKit

class TVShowCell: CoverCollectionViewCell {
    
    var show: PCTShow? {
        didSet {
            guard let show = self.show else {return}
            if let image = show.coverImageAsString,
                let url = NSURL(string: image) {
                self.coverImage.af_setImageWithURL(url,
                                                   placeholderImage: R.image.placeholder(),
                                                   imageTransition: .CrossDissolve(animationLength))
            }
            self.titleLabel.text = show.title
            self.yearLabel.text = show.year
        }
    }
    
    override func awakeFromNib() {
        self.gradientView.hidden = true
    }
    
}