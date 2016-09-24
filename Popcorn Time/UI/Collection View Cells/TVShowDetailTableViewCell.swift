

import UIKit
import PopcornKit

class TVShowDetailTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var seasonLabel: UILabel!
    @IBOutlet var watchedButton: UIButton!
    
    var tvdbId: String! {
        didSet {
            watchedButton.setImage(watchedButtonImage, for: .normal)
        }
    }
    
    var watchedButtonImage: UIImage {
        return WatchlistManager.episode.isWatched(tvdbId) ? UIImage(named: "WatchedOn")! : UIImage(named: "WatchedOff")!
    }
    
    @IBAction func toggleWatched() {
        WatchlistManager.episode.toggleWatched(tvdbId)
        watchedButton.setImage(watchedButtonImage, for: .normal)
    }
}
