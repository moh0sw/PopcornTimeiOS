//
//  TVShowContainerViewController
//  PopcornTime
//

import UIKit

class TVShowContainerViewController: UIViewController {

    var currentItem: PCTShow!
    var currentType: TraktTVAPI.type = .Shows

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail",
            let splitController = segue.destinationViewController as? UISplitViewController,
            let destinationController = splitController.viewControllers.first as? TVShowDetailViewController{
            destinationController.currentItem = currentItem
            destinationController.currentType = currentType
            destinationController.parentTabBarController = tabBarController
            destinationController.parentNavigationController = navigationController
            navigationItem.rightBarButtonItems = destinationController.navigationItem.rightBarButtonItems
            destinationController.parentNavigationItem = navigationItem
        }
    }
}