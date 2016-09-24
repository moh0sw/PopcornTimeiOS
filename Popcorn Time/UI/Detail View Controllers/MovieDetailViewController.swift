

import UIKit
import XCDYouTubeKit
import AlamofireImage
import ColorArt
import PopcornTorrent
import PopcornKit

class MovieDetailViewController: DetailItemOverviewViewController, PCTTablePickerViewDelegate, UIViewControllerTransitioningDelegate {
    
    @IBOutlet var torrentHealth: CircularView!
    @IBOutlet var qualityBtn: UIButton!
    @IBOutlet var subtitlesButton: UIButton!
    @IBOutlet var playButton: PCTBorderButton!
    @IBOutlet var watchedBtn: UIBarButtonItem!
    @IBOutlet var trailerBtn: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var regularConstraints: [NSLayoutConstraint]!
    @IBOutlet var compactConstraints: [NSLayoutConstraint]!
    
    var currentItem: Movie!
    var relatedItems = [Movie]()
    var subtitlesTablePickerView: PCTTablePickerView!
    fileprivate var classContext = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        WatchlistManager.movie.getProgress()
        view.addObserver(self, forKeyPath: "frame", options: .new, context: &classContext)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.removeObserver(self, forKeyPath: "frame")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        subtitlesTablePickerView?.setNeedsLayout()
        subtitlesTablePickerView?.layoutIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = currentItem.title
        watchedBtn.image = getWatchedButtonImage()
        let adjustForTabbarInsets = UIEdgeInsetsMake(0, 0, tabBarController!.tabBar.frame.height, 0)
        scrollView.contentInset = adjustForTabbarInsets
        scrollView.scrollIndicatorInsets = adjustForTabbarInsets
        titleLabel.text = currentItem.title
        summaryView.text = currentItem.summary
        ratingView.rating = Float(currentItem.rating)
        infoLabel.text = "\(currentItem.year) ● \(currentItem.runtime) min ● \(currentItem.genres[0].capitalized)"
        playButton.borderColor = SLColorArt(image: backgroundImageView.image).secondaryColor
        trailerBtn.isEnabled = currentItem.trailer != nil
        if currentItem.torrents.isEmpty {
            PopcornKit.getMovieInfo(currentItem.id, completion: { (movie, error) in
                guard let movie = movie else { self.qualityBtn?.setTitle("Error loading torrents.", for: .normal); return}
                self.currentItem = movie
                self.updateTorrents()
            })
        } else {
            updateTorrents()
        }
        SubtitlesManager.shared.login({
            SubtitlesManager.shared.search(imdbId: self.currentItem.id, completion: { (subtitles, error) in
                guard error == nil else { self.subtitlesButton.setTitle("Error loading subtitles", for: .normal); return }
                self.currentItem.subtitles = subtitles
                if subtitles.count == 0 {
                    self.subtitlesButton.setTitle("No Subtitles Available", for: .normal)
                } else {
                    self.subtitlesButton.setTitle("None ▾", for: .normal)
                    self.subtitlesButton.isUserInteractionEnabled = true
                    if let preferredSubtitle = UserDefaults.standard.object(forKey: "PreferredSubtitleLanguage") as? String , preferredSubtitle != "None" {
                        let languages = subtitles.map({$0.language})
                        let index = languages.index{$0 == languages.filter({$0 == preferredSubtitle}).first!}
                        let subtitle = self.currentItem.subtitles![index!]
                        self.currentItem.currentSubtitle = subtitle
                        self.subtitlesButton.setTitle(subtitle.language + " ▾", for: .normal)
                    }
                }
                self.subtitlesTablePickerView = PCTTablePickerView(superView: self.view, sourceDict: Dictionary(keys: subtitles.map({$0.link}), values: subtitles.map({$0.language})), self)
                if let link = self.currentItem.currentSubtitle?.link {
                    self.subtitlesTablePickerView.selectedItems = [link]
                }
                self.tabBarController?.view.addSubview(self.subtitlesTablePickerView)
            })
        })
        TraktManager.shared.getRelated(currentItem) { (movies, _) in
            self.relatedItems = movies
            self.collectionView.reloadData()
        }
        TraktManager.shared.getPeople(forMediaOfType: .movies, id: currentItem.id) { (actors, crew, _) in
            self.currentItem.crew = crew
            self.currentItem.actors = actors
            self.collectionView.reloadData()
        }
    }
    
    func getWatchedButtonImage() -> UIImage {
        return WatchlistManager.movie.isWatched(currentItem.id) ? UIImage(named: "WatchedOn")! : UIImage(named: "WatchedOff")!
    }
    
    func updateTorrents() {
        self.qualityBtn?.isUserInteractionEnabled = self.currentItem.torrents.count > 1
        self.currentItem.currentTorrent = self.currentItem.torrents.filter({$0.quality == UserDefaults.standard.string(forKey: "PreferredQuality")}).first ?? self.currentItem.torrents.first
        if let torrent = self.currentItem.currentTorrent {
            self.qualityBtn?.setTitle("\(torrent.quality! + (self.currentItem.torrents.count > 1 ? " ▾" : ""))", for: .normal)
        } else {
            self.qualityBtn?.setTitle("No torrents available.", for: .normal)
        }
        self.torrentHealth.backgroundColor = self.currentItem.currentTorrent?.health.color()
        self.playButton.isEnabled = self.currentItem.currentTorrent?.url != nil
    }
    
    @IBAction func toggleWatched() {
        WatchlistManager.movie.toggleWatched(currentItem.id)
        watchedBtn.image = getWatchedButtonImage()
    }
    
    @IBAction func changeQualityTapped(_ sender: UIButton) {
        let quality = UIAlertController(title:"Select Quality", message:nil, preferredStyle:UIAlertControllerStyle.actionSheet)
        for var torrent in currentItem.torrents {
            quality.addAction(UIAlertAction(title: "\(torrent.quality!) \(torrent.size!)", style: .default, handler: { action in
                self.currentItem.currentTorrent = torrent
                self.playButton.isEnabled = self.currentItem.currentTorrent?.url != nil
                self.qualityBtn.setTitle("\(torrent.quality!) ▾", for: .normal)
                self.torrentHealth.backgroundColor = torrent.health.color()
            }))
        }
        quality.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        quality.popoverPresentationController?.sourceView = sender
        present(quality, animated: true, completion: nil)
    }
    
    @IBAction func changeSubtitlesTapped(_ sender: UIButton) {
        subtitlesTablePickerView.toggle()
    }
    
    @IBAction func watchNowTapped(_ sender: UIButton) {
        let onWifi: Bool = (UIApplication.shared.delegate! as! AppDelegate).reachability!.isReachableViaWiFi()
        let wifiOnly: Bool = !UserDefaults.standard.bool(forKey: "StreamOnCellular")
        if !wifiOnly || onWifi {
            loadMovieTorrent(currentItem)
        } else {
            let errorAlert = UIAlertController(title: "Cellular Data is Turned Off for streaming", message: "To enable it please go to settings.", preferredStyle: UIAlertControllerStyle.alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            errorAlert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                let settings = self.storyboard!.instantiateViewController(withIdentifier: "SettingsTableViewController") as! SettingsTableViewController
                self.navigationController?.pushViewController(settings, animated: true)
            }))
            self.present(errorAlert, animated: true, completion: nil)
        }
    }
    
    func loadMovieTorrent(_ media: Movie, onChromecast: Bool = GCKCastContext.sharedInstance().castState == .connected) {
        let loadingViewController = storyboard!.instantiateViewController(withIdentifier: "LoadingViewController") as! LoadingViewController
        loadingViewController.transitioningDelegate = self
        loadingViewController.backgroundImage = backgroundImageView.image
        present(loadingViewController, animated: true, completion: nil)
        PopcornKit.downloadTorrentFile(media.currentTorrent!.url!) { [unowned self] (url, error) in
            if let url = url {
                let moviePlayer = self.storyboard!.instantiateViewController(withIdentifier: "PCTPlayerViewController") as! PCTPlayerViewController
                moviePlayer.delegate = self
                let currentProgress = WatchlistManager.movie.currentProgress(media.id)
                let castDevice = GCKCastContext.sharedInstance().sessionManager.currentSession?.device
                PTTorrentStreamer.shared().startStreaming(fromFileOrMagnetLink: url, progress: { status in
                    loadingViewController.progress = status.bufferingProgress
                    loadingViewController.speed = Int(status.downloadSpeed)
                    loadingViewController.seeds = Int(status.seeds)
                    loadingViewController.updateProgress()
                    moviePlayer.bufferProgressView?.progress = status.totalProgreess
                    }, readyToPlay: {(videoFileURL, videoFilePath) in
                        loadingViewController.dismiss(animated: false, completion: nil)
                        if onChromecast {
                            if GCKCastContext.sharedInstance().sessionManager.currentSession == nil {
                                GCKCastContext.sharedInstance().sessionManager.startSession(with: castDevice!)
                            }
                            let castPlayerViewController = self.storyboard?.instantiateViewController(withIdentifier: "CastPlayerViewController") as! CastPlayerViewController
                            let castMetadata: CastMetaData = (title: media.title, image: media.smallCoverImage != nil ? URL(string: media.smallCoverImage!) : nil, contentType: "video/mp4", subtitles: media.subtitles, url: videoFileURL!.relativeString, mediaAssetsPath: videoFilePath!.deletingLastPathComponent())
                            GoogleCastManager(castMetadata: castMetadata).sessionManager(GCKCastContext.sharedInstance().sessionManager, didStart: GCKCastContext.sharedInstance().sessionManager.currentSession!)
                            castPlayerViewController.backgroundImage = self.backgroundImageView.image
                            castPlayerViewController.title = media.title
                            castPlayerViewController.media = media
                            castPlayerViewController.startPosition = TimeInterval(currentProgress)
                            castPlayerViewController.directory = videoFilePath!.deletingLastPathComponent()
                            self.present(castPlayerViewController, animated: true, completion: nil)
                        } else {
                            moviePlayer.play(media, fromURL: videoFileURL!, progress: currentProgress, directory: videoFilePath!.deletingLastPathComponent())
                            moviePlayer.delegate = self
                            self.present(moviePlayer, animated: true, completion: nil)
                        }
                }) { error in
                    loadingViewController.cancelButtonPressed()
                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    print("Error is \(error)")
                }
            } else if let error = error {
                loadingViewController.dismiss(animated: true, completion: { [unowned self] in
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    })
            }
        }
    }
    
	@IBAction func watchTrailerTapped() {
        let vc = XCDYouTubeVideoPlayerViewController(videoIdentifier: currentItem.trailerCode)
        present(vc, animated: true, completion: nil)
	}
    
    func tablePickerView(_ tablePickerView: PCTTablePickerView, didClose items: [String]) {
        if items.count == 0 {
            currentItem.currentSubtitle = nil
            subtitlesButton.setTitle("None ▾", for: .normal)
        } else {
            let links = currentItem.subtitles?.map({$0.link})
            let index = links?.index{$0 == links?.filter({$0 == items.first!}).first!}
            let subtitle = currentItem.subtitles![index!]
            currentItem.currentSubtitle = subtitle
            subtitlesButton.setTitle(subtitle.language + " ▾", for: .normal)
        }
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presented is LoadingViewController ? PCTLoadingViewAnimatedTransitioning(isPresenting: true, sourceController: source) : nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissed is LoadingViewController ? PCTLoadingViewAnimatedTransitioning(isPresenting: false, sourceController: self) : nil
    }
}

extension MovieDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        var sections = 0
        if relatedItems.count > 0 {sections += 1}; if currentItem.actors.count > 0 {sections += 1}
        return sections
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? relatedItems.count : currentItem.actors.count
    }
    
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> CGSize {
        var items = 1
        while (collectionView.bounds.width/CGFloat(items))-8 > 195 {
            items += 1
        }
        let width = (collectionView.bounds.width/CGFloat(items))-8
        let ratio = width/195.0
        let height = 280.0 * ratio
        return CGSize(width: width, height: height)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if &classContext == context && keyPath == "frame" {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: UICollectionViewCell
        if indexPath.section == 0 {
            cell = {
               let coverCell = collectionView.dequeueReusableCell(withReuseIdentifier: "relatedCell", for: indexPath) as! CoverCollectionViewCell
                coverCell.titleLabel.text = relatedItems[indexPath.row].title
                coverCell.yearLabel.text = relatedItems[indexPath.row].year
                if let image = relatedItems[indexPath.row].smallCoverImage,
                    let url = URL(string: image) {
                    coverCell.coverImage.af_setImage(withURL: url, placeholderImage: UIImage(named: "Placeholder"))
                }
                coverCell.watched = WatchlistManager.movie.isWatched(relatedItems[indexPath.row].id)
                return coverCell
            }()
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "castCell", for: indexPath)
            let imageView = cell.viewWithTag(1) as! UIImageView
            if let image = currentItem.actors[indexPath.row].smallImage,
                let url = URL(string: image) {
                imageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "Placeholder"))
            }
            imageView.layer.cornerRadius = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath).width/2
            (cell.viewWithTag(2) as! UILabel).text = currentItem.actors[indexPath.row].name
            (cell.viewWithTag(3) as! UILabel).text = currentItem.actors[indexPath.row].characterName
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let movieDetail = storyboard?.instantiateViewController(withIdentifier: "MovieDetailViewController") as! MovieDetailViewController
            movieDetail.currentItem = relatedItems[indexPath.row]
            navigationController?.pushViewController(movieDetail, animated: true)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if let coverImageAsString = currentItem.mediumCoverImage,
            let backgroundImageAsString = currentItem.largeBackgroundImage {
            backgroundImageView.af_setImage(withURLRequest: URLRequest(url: URL(string: traitCollection.horizontalSizeClass == .compact ? coverImageAsString : backgroundImageAsString)!), placeholderImage: UIImage(named: "Placeholder"), imageTransition: .crossDissolve(animationLength), completion: {
                if let value = $0.result.value {
                    self.playButton.borderColor = SLColorArt(image: value).secondaryColor
                }
            })
        }
        
        for constraint in compactConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 999 : 240
        }
        for constraint in regularConstraints {
            constraint.priority = traitCollection.horizontalSizeClass == .compact ? 240 : 999
        }
        UIView.animate(withDuration: animationLength, animations: {
            self.view.layoutIfNeeded()
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            return {
               let element = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
                (element.viewWithTag(1) as! UILabel).text = indexPath.section == 0 ? "RELATED" : "CAST"
                return element
            }()
        }
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "footer", for: indexPath)
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return collectionView.gestureRecognizers?.filter({$0 == gestureRecognizer || $0 == otherGestureRecognizer}).first == nil
    }
}
