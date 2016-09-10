

import UIKit
import AlamofireImage

class AnimeCollectionViewController: MainCollectionViewController, UIPopoverPresentationControllerDelegate, GenresDelegate, ItemOverviewDelegate {
    
    var animes = [PCTShow]()
    
    var currentGenre = AnimeAPI.genres.All {
        didSet {
            animes.removeAll()
            collectionView?.reloadData()
            currentPage = 1
            loadNextPage(currentPage)
        }
    }
    var currentFilter = AnimeAPI.filters.Popularity {
        didSet {
            animes.removeAll()
            collectionView?.reloadData()
            currentPage = 1
            loadNextPage(currentPage)
        }
    }
    
    @IBAction func searchBtnPressed(sender: UIBarButtonItem) {
        presentViewController(searchController, animated: true, completion: nil)
    }
    
    @IBAction func filter(sender: AnyObject) {
        self.collectionView?.performBatchUpdates({
            self.filterHeader!.hidden = !self.filterHeader!.hidden
            }, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        loadNextPage(currentPage)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let collectionView = object as? UICollectionView where collectionView == self.collectionView! && keyPath! == "frame" {
            collectionView.performBatchUpdates(nil, completion: nil)
        }
    }
    
    func segmentedControlDidChangeSegment(segmentedControl: UISegmentedControl) {
        currentFilter = AnimeAPI.filters.arrayValue[segmentedControl.selectedSegmentIndex]
    }
    
    // MARK: - ItemOverviewDelegate
    
    func loadNextPage(pageNumber: Int, searchTerm: String? = nil, removeCurrentData: Bool = false) {
        guard isLoading else {
            isLoading = true
            hasNextPage = false
            AnimeAPI.sharedInstance.load(currentPage, filterBy: .Popularity, searchTerm: searchTerm) { items in
                self.isLoading = false
                if removeCurrentData {
                    self.animes.removeAll()
                }
                self.animes += items
                if items.isEmpty // If the array passed in is empty, there are no more results so the content inset of the collection view is reset.
                {
                    self.collectionView?.contentInset = UIEdgeInsetsMake(69, 0, 0, 0)
                } else {
                    self.hasNextPage = true
                }
                self.collectionView?.reloadData()
            }
            return
        }
    }
    
    func didDismissSearchController(searchController: UISearchController) {
        self.animes.removeAll()
        collectionView?.reloadData()
        self.currentPage = 1
        loadNextPage(self.currentPage)
    }
    
    func search(text: String) {
        self.animes.removeAll()
        collectionView?.reloadData()
        self.currentPage = 1
        self.loadNextPage(self.currentPage, searchTerm: text)
    }
    
    func shouldRefreshCollectionView() -> Bool {
        return animes.isEmpty
    }
    
    // MARK: - Navigation
    
    @IBAction func genresButtonTapped(sender: UIBarButtonItem) {
        let controller = cache.objectForKey(TraktTVAPI.type.Animes.rawValue) as? UINavigationController ?? (storyboard?.instantiateViewControllerWithIdentifier("GenresNavigationController"))! as! UINavigationController
        cache.setObject(controller, forKey: TraktTVAPI.type.Animes.rawValue)
        controller.modalPresentationStyle = .Popover
        controller.popoverPresentationController?.barButtonItem = sender
        controller.popoverPresentationController?.backgroundColor = UIColor(red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
        (controller.viewControllers[0] as! GenresTableViewController).delegate = self
        presentViewController(controller, animated: true, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        fixIOS9PopOverAnchor(segue)
        if segue.identifier == "showDetail" ,
            let selectedPaths = self.collectionView?.indexPathsForSelectedItems(),
            let selectedIndex = selectedPaths.first?.row,
            let destinationController = segue.destinationViewController as? TVShowContainerViewController {
            destinationController.currentItem = animes[selectedIndex]
        }
    }
    
    // MARK: - Collection view data source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        collectionView.backgroundView = nil
        if animes.count == 0 {
            if error != nil {
                let background = R.nib.mainBackgroundView.firstView(owner: nil)!
                background.setUpView(error: error!)
                collectionView.backgroundView = background
            } else if isLoading {
                let indicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
                indicator.center = collectionView.center
                collectionView.backgroundView = indicator
                indicator.sizeToFit()
                indicator.startAnimating()
            } else {
                let background = R.nib.mainBackgroundView.firstView(owner: nil)!
                background.setUpView(image: R.image.search()!, title: "No results found.", description: "No search results found for \(searchController.searchBar.text!). Please check the spelling and try again.")
                collectionView.backgroundView = background
            }
        }
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return animes.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(R.reuseIdentifier.animeCell, forIndexPath: indexPath)! as AnimeCell
        
        let anime = animes[indexPath.row]
        cell.anime = anime
        cell.watched = WatchlistManager.movieManager.isWatched(anime.id)
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        filterHeader = filterHeader ?? {
            let reuseableView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "filter", forIndexPath: indexPath) as! FilterCollectionReusableView
            reuseableView.segmentedControl?.removeAllSegments()
            for (index, filterValue) in AnimeAPI.filters.arrayValue.enumerate() {
                reuseableView.segmentedControl?.insertSegmentWithTitle(filterValue.stringValue(), atIndex: index, animated: false)
            }
            reuseableView.hidden = true
            reuseableView.segmentedControl?.addTarget(self, action: #selector(segmentedControlDidChangeSegment(_:)), forControlEvents: .ValueChanged)
            reuseableView.segmentedControl?.selectedSegmentIndex = 0
            return reuseableView
            }()
        return filterHeader!
    }

    
    // MARK: - GenresDelegate
    
    func finished(genreArrayIndex: Int) {
        navigationItem.title = AnimeAPI.genres.arrayValue[genreArrayIndex].rawValue
        if AnimeAPI.genres.arrayValue[genreArrayIndex] == .All {
            navigationItem.title = "Anime"
        }
        currentGenre = AnimeAPI.genres.arrayValue[genreArrayIndex]
    }
    
    func populateDataSourceArray(inout array: [String]) {
        for genre in AnimeAPI.genres.arrayValue {
            array.append(genre.rawValue)
        }
    }
}