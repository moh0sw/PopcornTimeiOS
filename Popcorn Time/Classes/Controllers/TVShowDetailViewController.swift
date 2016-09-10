

import UIKit
import AlamofireImage
import ColorArt
import PopcornTorrent

class TVShowDetailViewController: DetailItemOverviewViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate {
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var tableHeaderView: UIView!
    
    override var minimumHeight: CGFloat {
        get {
            return super.minimumHeight + 46.0
        }
    }
    
    let interactor = PCTEpisodeDetailPercentDrivenInteractiveTransition()

    var currentType: TraktTVAPI.type = .Shows
    var currentItem: PCTShow!
    var episodes: [PCTEpisode]?
    var seasons: [Int]?
    var episodesLeftInShow: [PCTEpisode]!
    
    /* Because UISplitViewControllers are not meant to be pushed to the navigation heirarchy, we are tricking it into thinking it is a root view controller when in fact it is just a childViewController of TVShowContainerViewController. Because of the fact that child view controllers should not be aware of their container view controllers, this variable had to be created to access the navigationController and the tabBarController of the viewController. In order to further trick the view controller, navigationController, navigationItem and tabBarController properties have been overridden to point to their corrisponding parent properties.
     */
    var parentTabBarController: UITabBarController?
    var parentNavigationController: UINavigationController?
    var parentNavigationItem: UINavigationItem?
    
    override var navigationItem: UINavigationItem {
        return parentNavigationItem ?? super.navigationItem
    }
    
    override var navigationController: UINavigationController? {
        return parentNavigationController
    }
    
    override var tabBarController: UITabBarController? {
        return parentTabBarController
    }
    
    var currentSeason: Int! {
        didSet {
            self.tableView.reloadData()
        }
    }
    var currentSeasonArray = [PCTEpisode]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.frame.size.width = splitViewController?.primaryColumnWidth ?? view.bounds.width
        WatchlistManager.episodeManager.getProgress()
        WatchlistManager.showManager.getWatched() {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.frame.size.width = UIScreen.mainScreen().bounds.width
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationController?.navigationBar.frame.size.width = splitViewController?.primaryColumnWidth ?? view.bounds.width
        splitViewController?.minimumPrimaryColumnWidth = UIScreen.mainScreen().bounds.width/1.7
        splitViewController?.maximumPrimaryColumnWidth = UIScreen.mainScreen().bounds.width/1.7
        self.tableView.sizeHeaderToFit()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        currentItem.coverImageAsString = currentItem.coverImageAsString?.stringByReplacingOccurrencesOfString("thumb", withString: "medium")
        splitViewController?.delegate = self
        splitViewController?.preferredDisplayMode = .AllVisible
//        let adjustForTabbarInsets = UIEdgeInsetsMake(0, 0, CGRectGetHeight(tabBarController!.tabBar.frame), 0)
//        tableView.contentInset = adjustForTabbarInsets
//        tableView.scrollIndicatorInsets = adjustForTabbarInsets
        tableView.rowHeight = UITableViewAutomaticDimension
        titleLabel.text = currentItem.title
        navigationItem.title = currentItem.title
        infoLabel.text = currentItem.year
        ratingView.rating = currentItem.rating
        if currentType == .Animes {
            AnimeAPI.sharedInstance.getAnimeInfo(currentItem.id, completion: { (status, synopsis, episodes, seasons) in
                self.currentItem.status = status
                self.currentItem.synopsis = synopsis
                var updatedEpisodes = [PCTEpisode]()
                for episode in episodes {
                    episode.show = self.currentItem
                    updatedEpisodes.append(episode)
                }
                self.episodes = updatedEpisodes
                self.seasons = seasons
                self.summaryView.text = synopsis
                self.infoLabel.text = "\(self.currentItem.year) ● \(self.currentItem.status!.capitalizedString) ● \(self.currentItem.genres![0].capitalizedString)"
                self.setUpSegmenedControl()
                self.tableView.reloadData()
            })
        } else {
            TVAPI.sharedInstance.getShowInfo(currentItem.id) { (genres, status, synopsis, episodes, seasons) in
                self.currentItem.genres = genres
                self.currentItem.status = status
                self.currentItem.synopsis = synopsis
                var updatedEpisodes = [PCTEpisode]()
                for episode in episodes {
                    episode.show = self.currentItem
                    updatedEpisodes.append(episode)
                }
                self.episodes = updatedEpisodes
                self.seasons = seasons
                self.summaryView.text = synopsis
                self.infoLabel.text = "\(self.currentItem.year) ● \(self.currentItem.status!.capitalizedString) ● \(self.currentItem.genres![0].capitalizedString)"
                self.setUpSegmenedControl()
                self.tableView.reloadData()
            }
        }
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if let coverImageAsString = currentItem.coverImageAsString,
            let backgroundImageAsString = currentItem.backgroundImageAsString {
            backgroundImageView.af_setImageWithURLRequest(NSURLRequest(URL: NSURL(string: splitViewController?.traitCollection.horizontalSizeClass == .Compact ? coverImageAsString : backgroundImageAsString)!), placeholderImage: UIImage(named: "Placeholder"), imageTransition: .CrossDissolve(animationLength))
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            tableView.tableHeaderView = tableHeaderView
            return 0
        }
        tableView.tableHeaderView = nil
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if episodes != nil {
            currentSeasonArray.removeAll()
            currentSeasonArray = getGroupedEpisodesBySeason(currentSeason)
            return currentSeasonArray.count
        }
        return 0
    }
    
    func getGroupedEpisodesBySeason(season: Int) -> [PCTEpisode] {
        var array = [PCTEpisode]()
        for index in seasons! {
            if season == index {
                array += episodes!.filter({$0.season == index})
            }
        }
        return array
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EpisodeCell", forIndexPath: indexPath) as! TVShowDetailTableViewCell
        cell.titleLabel.text = currentSeasonArray[indexPath.row].title
        cell.seasonLabel.text = "E" + String(currentSeasonArray[indexPath.row].episode)
        cell.tvdbId = currentSeasonArray[indexPath.row].id
        return cell
    }
    
    
    // MARK: - SegmentedControl
    
    func setUpSegmenedControl() {
        segmentedControl.removeAllSegments()
        segmentedControl.insertSegmentWithTitle("ABOUT", atIndex: 0, animated: true)
        for index in seasons! {
            segmentedControl.insertSegmentWithTitle("SEASON \(index)", atIndex: index, animated: true)
        }
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(11, weight: UIFontWeightMedium)],forState: UIControlState.Normal)
        segmentedControlDidChangeSegment(segmentedControl)
    }
    
    @IBAction func segmentedControlDidChangeSegment(segmentedControl: UISegmentedControl) {
        currentSeason = segmentedControl.selectedSegmentIndex == 0 ? Int.max: seasons?[segmentedControl.selectedSegmentIndex - 1]
        if tableView.frame.height > tableView.contentSize.height + tableView.contentInset.bottom {
            resetToEnd(tableView)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == "showDetail" {
            let indexPath = tableView.indexPathForCell(sender as! TVShowDetailTableViewCell)
            let destinationController = segue.destinationViewController as! EpisodeDetailViewController
            destinationController.currentItem = currentSeasonArray[indexPath!.row]
            var allEpisodes = [PCTEpisode]()
            for index in segmentedControl.selectedSegmentIndex..<segmentedControl.numberOfSegments {
                let season = seasons![index - 1]
                allEpisodes += getGroupedEpisodesBySeason(season)
                if season == currentSeason // Remove episodes up to the next episode eg. If row 2 is selected, row 0-2 will be deleted.
                {
                    allEpisodes.removeFirst(indexPath!.row + 1)
                }
            }
            episodesLeftInShow = allEpisodes
            destinationController.delegate = self
            destinationController.transitioningDelegate = self
            destinationController.modalPresentationStyle = .Custom
            destinationController.interactor = interactor
        }
    }
    
    func loadMovieTorrent(media: PCTEpisode, animated: Bool, onChromecast: Bool = GCKCastContext.sharedInstance().castState == .Connected) {
        let loadingViewController = storyboard!.instantiateViewControllerWithIdentifier("LoadingViewController") as! LoadingViewController
        loadingViewController.transitioningDelegate = self
        loadingViewController.backgroundImage = backgroundImageView.image
        presentViewController(loadingViewController, animated: animated, completion: nil)
        downloadTorrentFile(media.currentTorrent.url!) { [unowned self] (url, error) in
            if let url = url {
                let moviePlayer = self.storyboard!.instantiateViewControllerWithIdentifier("PCTPlayerViewController") as! PCTPlayerViewController
                moviePlayer.delegate = self
                let currentProgress = WatchlistManager.episodeManager.currentProgress(media.id)
                let castDevice = GCKCastContext.sharedInstance().sessionManager.currentSession?.device
                PTTorrentStreamer.sharedStreamer().startStreamingFromFileOrMagnetLink(url, progress: { status in
                    loadingViewController.progress = status.bufferingProgress
                    loadingViewController.speed = Int(status.downloadSpeed)
                    loadingViewController.seeds = Int(status.seeds)
                    loadingViewController.updateProgress()
                    moviePlayer.bufferProgressView?.progress = status.totalProgreess
                    }, readyToPlay: {(videoFileURL, videoFilePath) in
                        loadingViewController.dismissViewControllerAnimated(false, completion: nil)
                        var nextEpisode: PCTEpisode? = nil
                        if self.episodesLeftInShow.count > 0 {
                            nextEpisode = self.episodesLeftInShow.first
                            self.episodesLeftInShow.removeFirst()
                        }
                        if onChromecast {
                            if GCKCastContext.sharedInstance().sessionManager.currentSession == nil {
                                GCKCastContext.sharedInstance().sessionManager.startSessionWithDevice(castDevice!)
                            }
                            let castPlayerViewController = self.storyboard?.instantiateViewControllerWithIdentifier("CastPlayerViewController") as! CastPlayerViewController
                            let castMetadata = PCTCastMetaData(episode: media, url: videoFileURL.relativeString!, mediaAssetsPath: videoFilePath.URLByDeletingLastPathComponent!)
                            GoogleCastManager(castMetadata: castMetadata).sessionManager(GCKCastContext.sharedInstance().sessionManager, didStartSession: GCKCastContext.sharedInstance().sessionManager.currentSession!)
                            castPlayerViewController.backgroundImage = self.backgroundImageView.image
                            castPlayerViewController.title = media.title
                            castPlayerViewController.media = media
                            castPlayerViewController.startPosition = NSTimeInterval(currentProgress)
                            castPlayerViewController.directory = videoFilePath.URLByDeletingLastPathComponent!
                            self.presentViewController(castPlayerViewController, animated: true, completion: nil)
                        } else {
                            moviePlayer.play(media, fromURL: videoFileURL, progress: currentProgress, nextEpisode: nextEpisode, directory: videoFilePath.URLByDeletingLastPathComponent!)
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
    
    override func playNext(episode: PCTEpisode) {
        episode.currentTorrent = episode.currentTorrent ?? episode.torrents.first!
        loadMovieTorrent(episode, animated: false)
    }
    
    // MARK: - Presentation
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented is LoadingViewController {
            return PCTLoadingViewAnimatedTransitioning(isPresenting: true, sourceController: source)
        } else if presented is EpisodeDetailViewController {
            return PCTEpisodeDetailAnimatedTransitioning(isPresenting: true)
        }
        return nil
        
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed is LoadingViewController {
            return PCTLoadingViewAnimatedTransitioning(isPresenting: false, sourceController: self)
        } else if dismissed is EpisodeDetailViewController {
            return PCTEpisodeDetailAnimatedTransitioning(isPresenting: false)
        }
        return nil
    }
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        return presented is EpisodeDetailViewController ? PCTEpisodeDetailPresentationController(presentedViewController: presented, presentingViewController: presenting) : nil
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animator is PCTEpisodeDetailAnimatedTransitioning && interactor.hasStarted && splitViewController!.collapsed  {
            return interactor
        }
        return nil
    }
}

extension TVShowDetailViewController: UISplitViewControllerDelegate {
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        guard let secondaryViewController = secondaryViewController as? EpisodeDetailViewController where secondaryViewController.currentItem != nil else { return false }
        primaryViewController.presentViewController(secondaryViewController, animated: true, completion: nil)
        return true
    }
    
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        if primaryViewController.presentedViewController is EpisodeDetailViewController {
            return primaryViewController.presentedViewController
        }
        return nil
    }
}
