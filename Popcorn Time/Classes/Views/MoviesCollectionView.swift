//
//  MoviesCollectionView.swift
//  PopcornTime
//
//

import UIKit

protocol MoviesCollectionDelegate {
    func didSelectMovie(movie: PCTMovie)
}

class MoviesCollectionView {
    
    var movies = [PCTMovie]()
    var moviesCollectionDelegate: MoviesCollectionDelegate?
    var itemSize = CGSizeMake(100, 200)
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    
    func collectionView(collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return itemSize
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let coverCell = collectionView.dequeueReusableCellWithReuseIdentifier("relatedCell", forIndexPath: indexPath) as! MainItemCell
        let movie = movies[indexPath.row]
        
        if let image = movie.coverImageAsString,
            let url = NSURL(string: image) {
            coverCell.coverImage.af_setImageWithURL(url, placeholderImage: R.image.placeholder())
        }
        coverCell.titleLabel.text = movie.title
        coverCell.yearLabel.text = movie.year
        coverCell.watched = WatchlistManager.movieManager.isWatched(movie.id)
        
        return coverCell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let movie = movies[indexPath.row]
        self.moviesCollectionDelegate?.didSelectMovie(movie)
    }
    
}
