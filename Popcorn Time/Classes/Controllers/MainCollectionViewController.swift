

import UIKit
import Reachability

protocol ItemOverviewDelegate: class {
    func search(text: String)
    func didDismissSearchController(searchController: UISearchController)
    func loadNextPage(page: Int, searchTerm: String?, removeCurrentData: Bool)
    func shouldRefreshCollectionView() -> Bool
}

class MainCollectionViewController: UICollectionViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UICollectionViewDelegateFlowLayout {
    
    weak var delegate: ItemOverviewDelegate?
    
    let searchBlockDelay: CGFloat = 0.25
    var searchBlock: dispatch_cancelable_block_t?
    
    var isLoading: Bool = false
    var hasNextPage: Bool = false
    var currentPage: Int = 1
    
    let cache = NSCache()
    private var classContext = 0
    
    var error: NSError?
    
    var filterHeader: FilterCollectionReusableView?
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        collectionView?.removeObserver(self, forKeyPath: "frame")
        searchController.searchBar.hidden = true
        searchController.searchBar.resignFirstResponder()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadWithError), name: errorNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reachabilityChanged(_:)), name: kReachabilityChangedNotification, object: nil)
        collectionView?.addObserver(self, forKeyPath: "frame", options: .New, context: &classContext)
        searchController.searchBar.hidden = false
        searchController.searchBar.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshCollectionView(_:)), forControlEvents: .ValueChanged)
        collectionView?.addSubview(refreshControl)
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        collectionView?.performBatchUpdates(nil, completion: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let keyPath = keyPath where keyPath == "frame" && context == &classContext {
            collectionView?.performBatchUpdates(nil, completion: nil)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func reachabilityChanged(notification: NSNotification) {
        let reachability = notification.object! as! Reachability
        if reachability.isReachableViaWiFi() || reachability.isReachableViaWWAN() {
            if let delegate = delegate where delegate.shouldRefreshCollectionView() {
                delegate.loadNextPage(currentPage, searchTerm: searchController.searchBar.text, removeCurrentData: true)
            }
        }
    }
    
    func refreshCollectionView(sender: UIRefreshControl) {
        delegate?.loadNextPage(currentPage, searchTerm: searchController.searchBar.text, removeCurrentData: true)
        sender.endRefreshing()
    }
    
    func reloadWithError(error: NSNotification) {
        self.error = (error.object as! NSError)
        collectionView?.reloadData()
    }
    
    lazy var searchController: UISearchController = {
        let svc = UISearchController(searchResultsController: nil)
        svc.searchResultsUpdater = self
        svc.delegate = self
        svc.searchBar.delegate = self
        svc.searchBar.barStyle = .Black
        svc.searchBar.translucent = false
        svc.hidesNavigationBarDuringPresentation = false
        svc.dimsBackgroundDuringPresentation = false
        svc.searchBar.keyboardAppearance = .Dark
        return svc
    }()
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView == collectionView {
            let y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom
            let height = scrollView.contentSize.height
            let reloadDistance: CGFloat = 10
            if(y > height + reloadDistance && isLoading == false && hasNextPage == true) {
                collectionView?.contentInset.bottom = 80
                let background = UIView(frame: collectionView!.frame)
                let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
                indicator.startAnimating()
                indicator.translatesAutoresizingMaskIntoConstraints = false
                background.addSubview(indicator)
                background.addConstraint(NSLayoutConstraint(item: indicator, attribute: .CenterX, relatedBy: .Equal, toItem: background, attribute: .CenterX, multiplier: 1, constant: 0))
                background.addConstraint(NSLayoutConstraint(item: indicator, attribute: .Bottom, relatedBy: .Equal, toItem: background, attribute: .Bottom, multiplier: 1, constant: -55))
                collectionView?.backgroundView = background
                currentPage += 1
                delegate?.loadNextPage(currentPage, searchTerm: nil, removeCurrentData: false)
            }
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if !(searchController.searchBar.text?.isEmpty)! {
            if searchBlock != nil {
                cancel_block(searchBlock)
            }
            searchBlock = dispatch_after_delay(searchBlockDelay, {
                self.delegate?.search(searchController.searchBar.text!)
            })
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.itemSize()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.gutterWidth()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let topBottomInset = self.gutterWidth()
        return UIEdgeInsets(top: topBottomInset, left: topBottomInset, bottom: topBottomInset, right: topBottomInset)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return gutterWidth()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return filterHeader?.hidden == true ? CGSizeMake(CGFloat.min, CGFloat.min): CGSizeMake(view.frame.size.width, 50)
    }
    
    // MARK: - Help
    
    func nbColumns() -> CGFloat {
        let targetWidth: CGFloat = 180
        let nbColumns = round(self.collectionView!.bounds.width / targetWidth)
        return max(2, nbColumns)
    }
    
    func itemSize() -> CGSize {
        let calcWidth = (self.collectionView!.bounds.width - (nbColumns() + 1) * gutterWidth()) / nbColumns()
        let calcHeight = calcWidth * (345.0 / 230.0)
        return CGSize(width: calcWidth, height: calcHeight)
    }
    
    func gutterWidth() -> CGFloat {
        return 8
    }

}

extension UISearchController {
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        // Fixes status bar color changing from black to white upon presentation.
        return .LightContent
    }
}
