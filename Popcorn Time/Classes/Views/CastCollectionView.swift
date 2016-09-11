//
//  CastCollectionView.swift
//  PopcornTime
//

import UIKit

class CastCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate { 
    
    var actors = [PCTActor]()
    var castCollectionDelegate: MoviesCollectionDelegate?
    var itemSize = CGSizeMake(98, 140)
    
    override func awakeFromNib() {
    self.dataSource = self
    self.delegate = self
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actors.count
    }
    
    func collectionView(collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return itemSize
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("castCell", forIndexPath: indexPath)
        let actor = actors[indexPath.row]
        let imageView = cell.viewWithTag(1) as! UIImageView
        if let image = actor.imageAsString,
            let url = NSURL(string: image) {
            imageView.af_setImageWithURL(url, placeholderImage: R.image.placeholder())
        }
        imageView.layer.cornerRadius = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAtIndexPath: indexPath).width/2
        (cell.viewWithTag(2) as! UILabel).text = actor.name
        (cell.viewWithTag(3) as! UILabel).text = actor.character
        
        return cell
    }
    
}
