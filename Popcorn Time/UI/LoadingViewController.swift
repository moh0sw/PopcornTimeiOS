

import UIKit
import PopcornTorrent
import AlamofireImage

class LoadingViewController: UIViewController {
    
    @IBOutlet fileprivate weak var progressLabel: UILabel!
    @IBOutlet fileprivate weak var progressView: UIProgressView!
    @IBOutlet fileprivate weak var speedLabel: UILabel!
    @IBOutlet fileprivate weak var seedsLabel: UILabel!
    @IBOutlet fileprivate weak var loadingView: UIView!
    @IBOutlet fileprivate weak var backgroundImageView: UIImageView!

    
    var progress: Float = 0.0
    var speed: Int = 0
    var seeds: Int = 0
    var backgroundImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        if let backgroundImage = backgroundImage {
            backgroundImageView.image = backgroundImage
        }
    }
    
    func updateProgress() {
        loadingView.isHidden = true
        for view in [progressLabel, speedLabel, seedsLabel, progressView] as [UIView] {
            view.isHidden = false
        }
        progressView.progress = progress
        progressLabel.text = String(format: "%.0f%%", progress*100)
        speedLabel.text = ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .binary) + "/s"
        seedsLabel.text = "\(seeds) seeds"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    @IBAction func cancelButtonPressed() {
        PTTorrentStreamer.shared().cancelStreamingAndDeleteData(UserDefaults.standard.bool(forKey: "removeCacheOnPlayerExit"))
        dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
}
