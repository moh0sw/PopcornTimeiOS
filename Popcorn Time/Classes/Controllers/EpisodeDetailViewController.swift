

import UIKit
import AlamofireImage
import SwiftyUserDefaults

protocol EpisodeDetailViewControllerDelegate: class {
    func didDismissViewController(vc: EpisodeDetailViewController)
    func loadMovieTorrent(media: PCTEpisode, animated: Bool, onChromecast: Bool)
}

class EpisodeDetailViewController: UIViewController, PCTTablePickerViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var backgroundImageView: UIImageView?
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var episodeAndSeasonLabel: UILabel!
    @IBOutlet var summaryView: UITextView!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var qualityBtn: UIButton?
    @IBOutlet var playNowBtn: PCTBorderButton?
    @IBOutlet var subtitlesButton: UIButton!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var torrentHealth: CircularView!
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    
    var currentItem: PCTEpisode?
    var subtitlesTablePickerView: PCTTablePickerView!
    
    weak var delegate: EpisodeDetailViewControllerDelegate?
    var interactor: PCTEpisodeDetailPercentDrivenInteractiveTransition?
    
    override var navigationController: UINavigationController? {
        return splitViewController?.viewControllers.first?.navigationController
    }
    
    override var tabBarController: UITabBarController? {
        return splitViewController?.viewControllers.first?.tabBarController
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if transitionCoordinator()?.viewControllerForKey(UITransitionContextToViewControllerKey) == self.presentingViewController {
            delegate?.didDismissViewController(self)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let adjustForTabbarInsets = tabBarController?.tabBar.frame.height ?? 0
        scrollView.contentInset.bottom = adjustForTabbarInsets
        scrollView.scrollIndicatorInsets.bottom = adjustForTabbarInsets
        subtitlesTablePickerView?.tableView.contentInset.bottom = adjustForTabbarInsets
        heightConstraint.constant = UIScreen.mainScreen().bounds.height * 0.35
        subtitlesTablePickerView?.setNeedsLayout()
        subtitlesTablePickerView?.layoutIfNeeded()
        preferredContentSize = scrollView.contentSize
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        heightConstraint.constant = UIScreen.mainScreen().bounds.height * 0.35
        if let currentItem = currentItem {
            TVAPI.sharedInstance.getEpisodeInfo(currentItem) { (imageURLAsString, subtitles) in
                currentItem.coverImageAsString = imageURLAsString
                if let imageURLAsString = imageURLAsString,
                    url = NSURL(string: imageURLAsString) {
                    self.backgroundImageView!.af_setImageWithURL(url, placeholderImage: R.image.placeholder(), imageTransition: .CrossDissolve(animationLength))
                }
                if let subtitles = subtitles {
                    currentItem.subtitles = subtitles
                    if subtitles.isEmpty {
                        self.subtitlesButton.setTitle("No Subtitles Available", forState: .Normal)
                    } else {
                        self.subtitlesButton.setTitle("None ▾", forState: .Normal)
                        self.subtitlesButton.userInteractionEnabled = true
                        if let preferredSubtitle = Defaults[.PreferredSubtitleLanguage] where preferredSubtitle != "None" {
                            let languages = subtitles.map({$0.language})
                            let index = languages.indexOf(languages.filter({$0 == preferredSubtitle}).first!)!
                            let subtitle = currentItem.subtitles![index]
                            currentItem.currentSubtitle = subtitle
                            self.subtitlesButton.setTitle(subtitle.language + " ▾", forState: .Normal)
                        }
                    }
                    self.subtitlesTablePickerView = PCTTablePickerView(superView: self.view, sourceDict: PCTSubtitle.dictValue(subtitles), self)
                    if let link = currentItem.currentSubtitle?.link {
                        self.subtitlesTablePickerView.selectedItems = [link]
                    }
                    self.view.addSubview(self.subtitlesTablePickerView)
                }
            }
            titleLabel.text = currentItem.title
            var season = String(currentItem.season)
            season = season.characters.count == 1 ? "0" + season : season
            var episode = String(currentItem.episode)
            episode = episode.characters.count == 1 ? "0" + episode : episode
            episodeAndSeasonLabel.text = "S\(season)E\(episode)"
            summaryView.text = currentItem.summary
            infoLabel.text = "Aired: " + NSDateFormatter.localizedStringFromDate(currentItem.airedDate, dateStyle: .MediumStyle, timeStyle: .NoStyle)
            currentItem.currentTorrent = currentItem.torrents.filter({$0.quality == Defaults[.PreferredQuality]}).first ?? currentItem.torrents.first!
            qualityBtn?.userInteractionEnabled = currentItem.torrents.count > 1
            qualityBtn?.setTitle("\(currentItem.currentTorrent.quality! + (currentItem.torrents.count > 1 ? " ▾" : ""))", forState: .Normal)
            playNowBtn?.enabled = currentItem.currentTorrent.url != nil
            torrentHealth.backgroundColor = currentItem.currentTorrent.health.color()
        } else {
            let background = R.nib.mainBackgroundView.firstView(owner: nil)!
            background.frame = view.bounds
            background.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
            background.backgroundColor = UIColor(red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
            view.insertSubview(background, aboveSubview: view)
            background.setUpView(image: R.image.airTV()!.imageWithRenderingMode(.AlwaysTemplate), description: "No episode selected")
            background.imageView.tintColor = UIColor.darkGrayColor()
        }
        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()
        preferredContentSize = scrollView.contentSize
    }
    
    @IBAction func changeQualityTapped(sender: UIButton) {
        let quality = UIAlertController(title:"Select Quality", message:nil, preferredStyle:UIAlertControllerStyle.ActionSheet)
        for torrent in currentItem!.torrents {
            quality.addAction(UIAlertAction(title: "\(torrent.quality!) \(torrent.size ?? "")", style: .Default, handler: { action in
                self.currentItem?.currentTorrent = torrent
                self.playNowBtn?.enabled = self.currentItem?.currentTorrent.url != nil
                self.qualityBtn?.setTitle("\(torrent.quality!) ▾", forState: .Normal)
                self.torrentHealth.backgroundColor = torrent.health.color()
            }))
        }
        quality.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        quality.popoverPresentationController?.sourceView = sender
        fixPopOverAnchor(quality)
        presentViewController(quality, animated: true, completion: nil)
    }
    
    @IBAction func changeSubtitlesTapped(sender: UIButton) {
        subtitlesTablePickerView?.toggle()
    }
    
    @IBAction func watchNowTapped(sender: UIButton) {
        let onWifi: Bool = (UIApplication.sharedApplication().delegate! as! AppDelegate).reachability!.isReachableViaWiFi()
        let wifiOnly: Bool = Defaults[.StreamOnCellular]
        if !wifiOnly || onWifi {
            splitViewController?.collapseSecondaryViewController(self, forSplitViewController: splitViewController!)
//            dismissViewControllerAnimated(false, completion: { [unowned self] in
//                self.delegate?.loadMovieTorrent(self.currentItem!, animated: true, onChromecast: GCKCastContext.sharedInstance().castState == .Connected)
//            })
        } else {
            let errorAlert = UIAlertController(title: "Cellular Data is Turned Off for streaming", message: "To enable it please go to settings.", preferredStyle: UIAlertControllerStyle.Alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: { (action: UIAlertAction!) in }))
            errorAlert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action: UIAlertAction!) in
                let settings = self.storyboard!.instantiateViewControllerWithIdentifier("SettingsTableViewController") as! SettingsTableViewController
                self.navigationController?.pushViewController(settings, animated: true)
            }))
            self.presentViewController(errorAlert, animated: true, completion: nil)
        }
    }
    
    func tablePickerView(tablePickerView: PCTTablePickerView, didClose items: [String]) {
        if items.count == 0 {
            currentItem?.currentSubtitle = nil
            subtitlesButton.setTitle("None ▾", forState: .Normal)
        } else {
            let links = currentItem!.subtitles!.map({$0.link})
            let index = links.indexOf(links.filter({$0 == items.first!}).first!)!
            let subtitle = currentItem!.subtitles![index]
            currentItem?.currentSubtitle = subtitle
            subtitlesButton.setTitle(subtitle.language + " ▾", forState: .Normal)
        }
    }
    
    @IBAction func handleGesture(sender: UIPanGestureRecognizer) {
        let percentThreshold: CGFloat = 0.12
        let superview = sender.view!.superview!
        let translation = sender.translationInView(superview)
        let progress = translation.y/superview.bounds.height/3.0
        
        guard let interactor = interactor else { return }
        
        switch sender.state {
        case .Began:
            interactor.hasStarted = true
            dismissViewControllerAnimated(true, completion: nil)
            scrollView.bounces = false
        case .Changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.updateInteractiveTransition(progress)
        case .Cancelled:
            interactor.hasStarted = false
            interactor.cancelInteractiveTransition()
             scrollView.bounces = true
        case .Ended:
            interactor.hasStarted = false
            interactor.shouldFinish ? interactor.finishInteractiveTransition() : interactor.cancelInteractiveTransition()
            scrollView.bounces = true
        default:
            break
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return scrollView.contentOffset.y == 0 ? true : false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension TVShowDetailViewController: EpisodeDetailViewControllerDelegate {
    func didDismissViewController(vc: EpisodeDetailViewController) {
        if let indexPath = self.tableView!.indexPathForSelectedRow where splitViewController!.collapsed {
            self.tableView!.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
}
