

import UIKit

class TVShowDetailTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var seasonLabel: UILabel!
    @IBOutlet var watchedButton: UIButton!
    
    var tvdbId: String! {
        didSet {
            watchedButton.setImage(watchedButtonImage, forState: .Normal)
        }
    }
    
    var watchedButtonImage: UIImage {
        return WatchlistManager.episodeManager.isWatched(tvdbId) ? R.image.watchedOn()! : R.image.watchedOff()!
    }
    
    @IBAction func toggleWatched() {
        WatchlistManager.episodeManager.toggleWatched(tvdbId)
        watchedButton.setImage(watchedButtonImage, forState: .Normal)
    }
}
