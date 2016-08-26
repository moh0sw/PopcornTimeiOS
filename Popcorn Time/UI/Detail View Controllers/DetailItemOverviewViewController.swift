

import UIKit
import GoogleCast
import FloatRatingView

class DetailItemOverviewViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, PCTPlayerViewControllerDelegate {
    
    var progressiveness: CGFloat = 0.0
    var lastTranslation: CGFloat = 0.0
    var lastHeaderHeight: CGFloat = 0.0
    var minimumHeight: CGFloat {
        return navigationController!.navigationBar.bounds.size.height + statusBarHeight()
    }
    var maximumHeight: CGFloat {
        return view.bounds.height/1.6
    }
    
    @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var scrollView: PCTScrollView!
    @IBOutlet var tableView: PCTTableView!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var gradientViews: [GradientView]!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var castButton: CastIconBarButtonItem!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var ratingView: FloatRatingView!
    @IBOutlet var summaryView: UITextView!
    @IBOutlet var infoLabel: UILabel!

    enum ScrollDirection {
        case Down
        case Up
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateCastStatus), name: kGCKCastStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(layoutNavigationBar), name: UIDeviceOrientationDidChangeNotification, object: nil)
        updateCastStatus()
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics:.Default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(self.progressiveness)]
        if transitionCoordinator()?.viewControllerForKey(UITransitionContextFromViewControllerKey) is PCTPlayerViewController || transitionCoordinator()?.viewControllerForKey(UITransitionContextFromViewControllerKey) is CastPlayerViewController {
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            self.headerHeightConstraint.constant = self.lastHeaderHeight
            self.updateScrolling(false)
            for view in self.gradientViews {
                view.alpha = 1.0
            }
            if let showDetail = self as? TVShowDetailViewController {
                showDetail.segmentedControl.alpha = 1.0
            }
            if let frame = self.tabBarController?.tabBar.frame where frame.origin.y > self.view.bounds.height - frame.height {
                let offsetY = -frame.size.height
                self.tabBarController?.tabBar.frame = CGRectOffset(frame, 0, offsetY)
            }
            
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if transitionCoordinator()?.viewControllerForKey(UITransitionContextToViewControllerKey) == self.navigationController?.topViewController {
            self.navigationController!.navigationBar.setBackgroundImage(nil, forBarMetrics:.Default)
            self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        layoutNavigationBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerHeightConstraint.constant = maximumHeight
        (castButton.customView as! CastIconButton).addTarget(self, action: #selector(castButtonTapped), forControlEvents: .TouchUpInside)
    }
    
    /// On iPhones, status bar hides when view traits become compact so we need to force an update for the header size.
    func layoutNavigationBar() {
        let scrollingView: UIScrollView! = tableView ?? scrollView
        if headerHeightConstraint.constant < minimumHeight || scrollingView.valueForKey("programaticScrollEnabled")!.boolValue
        {
            headerHeightConstraint.constant = minimumHeight
        } else if headerHeightConstraint.constant > maximumHeight {
            headerHeightConstraint.constant = maximumHeight
        } else if scrollingView.frame.size.height > scrollingView.contentSize.height + scrollingView.contentInset.bottom {
            resetToEnd(scrollingView)
        }
        updateScrolling(true)
    }
    
    @IBAction func handleGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translationInView(sender.view!.superview!)
        let offset = translation.y - lastTranslation
        let scrollDirection: ScrollDirection = offset > 0 ? .Up : .Down
        let scrollingView: UIScrollView! = tableView ?? scrollView
    
        if sender.state == .Changed || sender.state == .Began {
            if (headerHeightConstraint.constant + offset) >= minimumHeight && scrollingView.valueForKey("programaticScrollEnabled")!.boolValue == false {
                if ((headerHeightConstraint.constant + offset) - minimumHeight) <= 8.0 // Stops scrolling from sticking just before we transition to scroll view input.
                {
                    headerHeightConstraint.constant = self.minimumHeight
                    updateScrolling(true)
                } else {
                    headerHeightConstraint.constant += offset
                    updateScrolling(false)
                }
            }
            if headerHeightConstraint.constant == minimumHeight && scrollingView.isAtTop
            {
                if scrollDirection == .Up {
                    scrollingView.setValue(false, forKey: "programaticScrollEnabled")
                } else // If header is fully collapsed and we are not at the end of scroll view, hand scrolling to scroll view
                {
                    scrollingView.setValue(true, forKey: "programaticScrollEnabled")
                }
            }
            lastTranslation = translation.y
        } else if sender.state == .Ended {
            if headerHeightConstraint.constant > maximumHeight {
                headerHeightConstraint.constant = maximumHeight
                updateScrolling(true)
            } else if scrollingView.frame.size.height > scrollingView.contentSize.height + scrollingView.contentInset.bottom {
                resetToEnd(scrollingView)
            }
            lastTranslation = 0.0
        }
    }
    
    
    func updateScrolling(animated: Bool) {
        self.progressiveness = 1.0 - (self.headerHeightConstraint.constant - self.minimumHeight)/(self.maximumHeight - self.minimumHeight)
        if animated {
            UIView.animateWithDuration(animationLength, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .AllowUserInteraction, animations: { 
                self.view.layoutIfNeeded()
                self.blurView.alpha = self.progressiveness
                self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(self.progressiveness)]
                }, completion: nil)
        } else {
            self.blurView.alpha = self.progressiveness
            self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor().colorWithAlphaComponent(self.progressiveness)]
        }
    }
    
    func resetToEnd(scrollingView: UIScrollView, animated: Bool = true) {
        headerHeightConstraint.constant += scrollingView.frame.size.height - (scrollingView.contentSize.height + scrollingView.contentInset.bottom)
        if headerHeightConstraint.constant > maximumHeight {
            headerHeightConstraint.constant = maximumHeight
        }
        if headerHeightConstraint.constant >= minimumHeight // User does not go over the "bridge area" so programmatic scrolling has to be explicitly disabled
        {
            scrollingView.setValue(false, forKey: "programaticScrollEnabled")
        }
        updateScrolling(animated)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - PCTPlayerViewControllerDelegate
    
    func playNext(episode: PCTEpisode) {}
    func presentCastPlayer(media: PCTItem, videoFilePath: NSURL, startPosition: NSTimeInterval) {
        dismissViewControllerAnimated(true, completion: nil)
        let castPlayerViewController = self.storyboard?.instantiateViewControllerWithIdentifier("CastPlayerViewController") as! CastPlayerViewController
        castPlayerViewController.backgroundImage = self.backgroundImageView.image
        castPlayerViewController.title = media.title
        castPlayerViewController.media = media
        castPlayerViewController.startPosition = startPosition
        castPlayerViewController.directory = videoFilePath.URLByDeletingLastPathComponent!
        presentViewController(castPlayerViewController, animated: true, completion: nil)
    }
    
    // MARK: - Presentation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        fixIOS9PopOverAnchor(segue)
        if segue.identifier == "showCasts", let vc = (segue.destinationViewController as? UINavigationController)?.viewControllers.first as? StreamToDevicesTableViewController {
            segue.destinationViewController.popoverPresentationController?.delegate = self
            vc.onlyShowCastDevices = true
        }
    }
    
    func castButtonTapped() {
        performSegueWithIdentifier("showCasts", sender: castButton)
    }
    
    func updateCastStatus() {
        (castButton.customView as! CastIconButton).status = GCKCastContext.sharedInstance().castState
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        (controller.presentedViewController as! UINavigationController).topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(dismiss))
        return controller.presentedViewController
        
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

class PCTScrollView: UIScrollView {
    var programaticScrollEnabled = false
    
    override var contentOffset: CGPoint {
        didSet {
            if !programaticScrollEnabled {
                super.contentOffset = CGPointZero
            }
        }
    }
}

class PCTTableView: UITableView {
    var programaticScrollEnabled = false
    
    override var contentOffset: CGPoint {
        didSet {
            if !programaticScrollEnabled {
                super.contentOffset = CGPointZero
            }
        }
    }
}
