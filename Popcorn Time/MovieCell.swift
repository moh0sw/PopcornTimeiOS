//
//  MoviesCoverCell.swift
//  PopcornTime
//
//  Created by Alex on 10/09/2016.
//  Copyright © 2016 Popcorn Time. All rights reserved.
//

import UIKit

class MovieCell: CoverCollectionViewCell {
    
    var movie: PCTMovie? {
        didSet {
            guard let movie = self.movie else {return}
            if let image = movie.coverImageAsString,
                let url = NSURL(string: image) {
                self.coverImage.af_setImageWithURL(url,
                                                   placeholderImage: R.image.placeholder(),
                                                   imageTransition: .CrossDissolve(animationLength))
            }
            self.titleLabel.text = movie.title
            self.yearLabel.text = movie.year
        }
    }
    
    override func awakeFromNib() {
        self.gradientView.hidden = true
    }
    
}