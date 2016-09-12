

import UIKit
import XCDYouTubeKit
import AlamofireImage
import ColorArt
import PopcornTorrent
import SwiftyUserDefaults

class MovieDetailViewController: DetailItemOverviewViewController, PCTTablePickerViewDelegate, UIViewControllerTransitioningDelegate {

    @IBOutlet var headerView: UIView!
    @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var headerTopConstraint: NSLayoutConstraint!

    @IBOutlet var torrentHealth: CircularView!
    @IBOutlet var qualityBtn: UIButton!
    @IBOutlet var subtitlesButton: UIButton!
    @IBOutlet var playButton: PCTBorderButton!
    @IBOutlet var watchedBtn: UIBarButtonItem!
    @IBOutlet var trailerBtn: UIButton!
    @IBOutlet var moviesCollectionView: MoviesCollectionView!
    @IBOutlet var castCollectionView: CastCollectionView!
    
    var currentItem: PCTMovie!
    var cast = [PCTActor]()
    var subtitlesTablePickerView: PCTTablePickerView!
    private var classContext = 0
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        WatchlistManager.movieManager.getProgress()
        self.scrollView.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currentItem.title
        
        currentItem.coverImageAsString = currentItem.coverImageAsString?.stringByReplacingOccurrencesOfString("thumb", withString: "medium")
        watchedBtn.image = getWatchedButtonImage()
        titleLabel.text = currentItem.title
        summaryView.text = currentItem.summary
        ratingView.rating = Float(currentItem.rating)
        infoLabel.text = "\(currentItem.year) ● \(currentItem.runtime) min ● \(currentItem.genres[0].capitalizedString)"
        playButton.borderColor = SLColorArt(image: backgroundImageView.image).secondaryColor
        trailerBtn.enabled = currentItem.trailerURLString != nil
        
        MovieAPI.sharedInstance.getMovieInfo(currentItem.id, completion: {
            self.currentItem.torrents = $0
            self.currentItem.currentTorrent = self.currentItem.torrents.filter({$0.quality == Defaults[.PreferredQuality]}).first ?? self.currentItem.torrents.first!
            self.torrentHealth.backgroundColor = self.currentItem.currentTorrent.health.color()
            self.playButton.enabled = self.currentItem.currentTorrent.url != nil
            self.qualityBtn?.userInteractionEnabled = self.currentItem.torrents.count > 1
            self.qualityBtn?.setTitle("\(self.currentItem.currentTorrent.quality! + (self.currentItem.torrents.count > 1 ? " ▾" : ""))", forState: .Normal)
        })
        
        OpenSubtitles.sharedInstance.login({
            OpenSubtitles.sharedInstance.search(imdbId: self.currentItem.id, completion: {
                subtitles in
                self.currentItem.subtitles = subtitles
                if subtitles.count == 0 {
                    self.subtitlesButton.setTitle("No Subtitles Available", forState: .Normal)
                } else {
                    self.subtitlesButton.setTitle("None ▾", forState: .Normal)
                    self.subtitlesButton.userInteractionEnabled = true
                    if let preferredSubtitle = Defaults[.PreferredSubtitleLanguage] where preferredSubtitle != "None" {
                        let languages = subtitles.map({$0.language})
                        let index = languages.indexOf(languages.filter({$0 == preferredSubtitle}).first!)!
                        let subtitle = self.currentItem.subtitles![index]
                        self.currentItem.currentSubtitle = subtitle
                        self.subtitlesButton.setTitle(subtitle.language + " ▾", forState: .Normal)
                    }
                }
                self.subtitlesTablePickerView = PCTTablePickerView(superView: self.view, sourceDict: PCTSubtitle.dictValue(subtitles), self)
                if let link = self.currentItem.currentSubtitle?.link {
                    self.subtitlesTablePickerView.selectedItems = [link]
                }
                self.tabBarController?.view.addSubview(self.subtitlesTablePickerView)
            })
        })
        
        
        MovieAPI.sharedInstance.getDetailedMovieInfo(currentItem.id) { (actors, related) in
            self.moviesCollectionView.movies = related as! [PCTMovie]
            self.moviesCollectionView.reloadData()
            
            self.castCollectionView.actors = actors
            self.castCollectionView.reloadData()
        }
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        if let coverImageAsString = currentItem.coverImageAsString,
            let backgroundImageAsString = currentItem.backgroundImageAsString {
            backgroundImageView.af_setImageWithURLRequest(NSURLRequest(URL: NSURL(string: traitCollection.horizontalSizeClass == .Compact ? coverImageAsString : backgroundImageAsString)!), placeholderImage: R.image.placeholder(), imageTransition: .CrossDissolve(animationLength), completion: {
                if let value = $0.result.value {
                    self.playButton.borderColor = SLColorArt(image: value).secondaryColor
                }
            })
        }
    }
    
    func getWatchedButtonImage() -> UIImage {
        return WatchlistManager.movieManager.isWatched(currentItem.id) ? R.image.watchedOn()! : R.image.watchedOff()!
    }
    
    @IBAction func toggleWatched() {
        WatchlistManager.movieManager.toggleWatched(currentItem.id)
        watchedBtn.image = getWatchedButtonImage()
    }
    
    @IBAction func changeQualityTapped(sender: UIButton) {
        let quality = UIAlertController(title:"Select Quality", message:nil, preferredStyle:UIAlertControllerStyle.ActionSheet)
        for torrent in currentItem.torrents {
            quality.addAction(UIAlertAction(title: "\(torrent.quality!) \(torrent.size!)", style: .Default, handler: { action in
                self.currentItem.currentTorrent = torrent
                self.playButton.enabled = self.currentItem.currentTorrent.url != nil
                self.qualityBtn.setTitle("\(torrent.quality!) ▾", forState: .Normal)
                self.torrentHealth.backgroundColor = torrent.health.color()
            }))
        }
        quality.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        quality.popoverPresentationController?.sourceView = sender
        fixPopOverAnchor(quality)
        presentViewController(quality, animated: true, completion: nil)
    }
    
    @IBAction func changeSubtitlesTapped(sender: UIButton) {
        subtitlesTablePickerView.toggle()
    }
    
    @IBAction func watchNowTapped(sender: UIButton) {
        let onWifi: Bool = (UIApplication.sharedApplication().delegate! as! AppDelegate).reachability!.isReachableViaWiFi()
        let wifiOnly: Bool = Defaults[.StreamOnCellular]
        if !wifiOnly || onWifi {
            loadMovieTorrent(currentItem)
        } else {
            let errorAlert = UIAlertController(title: "Cellular Data is Turned Off for streaming", message: "To enable it please go to settings.", preferredStyle: UIAlertControllerStyle.Alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            errorAlert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { _ in
                let settings = self.storyboard!.instantiateViewControllerWithIdentifier("SettingsTableViewController") as! SettingsTableViewController
                self.navigationController?.pushViewController(settings, animated: true)
            }))
            self.presentViewController(errorAlert, animated: true, completion: nil)
        }
    }
    
    func loadMovieTorrent(media: PCTMovie, onChromecast: Bool = GCKCastContext.sharedInstance().castState == .Connected) {
        let loadingViewController = R.storyboard.commons.loadingViewController()!
        loadingViewController.transitioningDelegate = self
        loadingViewController.backgroundImage = backgroundImageView.image
        presentViewController(loadingViewController, animated: true, completion: nil)
        
        downloadTorrentFile(media.currentTorrent.url!) { [unowned self] (url, error) in
            if let url = url {
                let moviePlayer = self.storyboard!.instantiateViewControllerWithIdentifier("PCTPlayerViewController") as! PCTPlayerViewController
                moviePlayer.delegate = self
                let currentProgress = WatchlistManager.movieManager.currentProgress(media.id)
                let castDevice = GCKCastContext.sharedInstance().sessionManager.currentSession?.device
                PTTorrentStreamer.sharedStreamer().startStreamingFromFileOrMagnetLink(url, progress: { status in
                    loadingViewController.progress = status.bufferingProgress
                    loadingViewController.speed = Int(status.downloadSpeed)
                    loadingViewController.seeds = Int(status.seeds)
                    loadingViewController.updateProgress()
                    moviePlayer.bufferProgressView?.progress = status.totalProgreess
                    }, readyToPlay: {(videoFileURL, videoFilePath) in
                        loadingViewController.dismissViewControllerAnimated(false, completion: nil)
                        if onChromecast {
                            if GCKCastContext.sharedInstance().sessionManager.currentSession == nil {
                                GCKCastContext.sharedInstance().sessionManager.startSessionWithDevice(castDevice!)
                            }
                            let castPlayerViewController = self.storyboard?.instantiateViewControllerWithIdentifier("CastPlayerViewController") as! CastPlayerViewController
                            let castMetadata = PCTCastMetaData(movie: media, url: videoFileURL.relativeString!, mediaAssetsPath: videoFilePath.URLByDeletingLastPathComponent!)
                            GoogleCastManager(castMetadata: castMetadata).sessionManager(GCKCastContext.sharedInstance().sessionManager, didStartSession: GCKCastContext.sharedInstance().sessionManager.currentSession!)
                            castPlayerViewController.backgroundImage = self.backgroundImageView.image
                            castPlayerViewController.title = media.title
                            castPlayerViewController.media = media
                            castPlayerViewController.startPosition = NSTimeInterval(currentProgress)
                            castPlayerViewController.directory = videoFilePath.URLByDeletingLastPathComponent!
                            self.presentViewController(castPlayerViewController, animated: true, completion: nil)
                        } else {
                            moviePlayer.play(media, fromURL: videoFileURL, progress: currentProgress, directory: videoFilePath.URLByDeletingLastPathComponent!)
                            moviePlayer.delegate = self
                            self.presentViewController(moviePlayer, animated: true, completion: nil)
                        }
                }) { error in
                    loadingViewController.cancelButtonPressed()
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    print("Error is \(error)")
                }
            } else if let error = error {
                loadingViewController.dismissViewControllerAnimated(true, completion: { [unowned self] in
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    })
            }
        }
    }
    
	@IBAction func watchTrailerTapped() {
        let vc = XCDYouTubeVideoPlayerViewController(videoIdentifier: currentItem.trailerURLString)
        presentViewController(vc, animated: true, completion: nil)
	}
    
    func tablePickerView(tablePickerView: PCTTablePickerView, didClose items: [String]) {
        if items.count == 0 {
            currentItem.currentSubtitle = nil
            subtitlesButton.setTitle("None ▾", forState: .Normal)
        } else {
            let links = currentItem.subtitles!.map({$0.link})
            let index = links.indexOf(links.filter({$0 == items.first!}).first!)!
            let subtitle = currentItem.subtitles![index]
            currentItem.currentSubtitle = subtitle
            subtitlesButton.setTitle(subtitle.language + " ▾", forState: .Normal)
        }
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presented is LoadingViewController ? PCTLoadingViewAnimatedTransitioning(isPresenting: true, sourceController: source) : nil
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissed is LoadingViewController ? PCTLoadingViewAnimatedTransitioning(isPresenting: false, sourceController: self) : nil
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        self.headerTopConstraint.constant = offset
        self.headerHeightConstraint.constant = max(0,self.view.bounds.height * 0.6 - offset)
    }
}
