

import UIKit
import GoogleCast
import FloatRatingView

class DetailItemOverviewViewController: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, PCTPlayerViewControllerDelegate {
    
    var progressiveness: CGFloat = 0.0
    var lastTranslation: CGFloat = 0.0
    var lastHeaderHeight: CGFloat = 0.0
    var minimumHeight: CGFloat {
        if let navigationBar = navigationController?.navigationBar where navigationBar.hidden == false { return navigationBar.bounds.size.height + statusBarHeight() }
        return statusBarHeight()
    }
    var maximumHeight: CGFloat {
        return view.bounds.height/1.6
    }
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var gradientViews: [GradientView]!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var castButton: CastIconBarButtonItem!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var ratingView: FloatRatingView!
    @IBOutlet var summaryView: PCTTextView!
    @IBOutlet var infoLabel: UILabel!

    enum ScrollDirection {
        case Down
        case Up
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateCastStatus), name: kGCKCastStateDidChangeNotification, object: nil)
        updateCastStatus()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let castView = castButton.customView as? CastIconButton {
            castView.addTarget(self, action: #selector(castButtonTapped), forControlEvents: .TouchUpInside)
        }
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
        if let castView = castButton.customView as? CastIconButton {
            castView.status = GCKCastContext.sharedInstance().castState
        }
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        (controller.presentedViewController as! UINavigationController).topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(dismiss))
        return controller.presentedViewController
        
    }
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

