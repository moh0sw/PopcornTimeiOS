//
//  AnimeCell.swift
//  PopcornTime
//
//  Created by Alex on 10/09/2016.
//  Copyright © 2016 Popcorn Time. All rights reserved.
//

import UIKit

class AnimeCell: CoverCollectionViewCell {
    
    var anime: PCTShow? {
        didSet {
            guard let anime = self.anime else {return}
            if let image = anime.coverImageAsString,
                let url = NSURL(string: image) {
                self.coverImage.af_setImageWithURL(url,
                                                   placeholderImage: R.image.placeholder(),
                                                   imageTransition: .CrossDissolve(animationLength))
            }
            self.titleLabel.text = anime.title
            self.yearLabel.text = anime.year
        }
    }
    
    override func awakeFromNib() {

    }
    
}
