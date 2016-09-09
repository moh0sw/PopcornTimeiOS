//
//  MainTabBarController.swift
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    // MARK: - General

    let moviesNVC = R.storyboard.movies.initialViewController()!
    var tvshowsNVC = R.storyboard.tVShows.initialViewController()!
    var animesNVC = R.storyboard.animes.initialViewController()!
    var settingsNVC = R.storyboard.settings.initialViewController()!


    override func viewDidLoad() {
        super.viewDidLoad()
        self.launchApp()
        self.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    func launchApp() {

        self.viewControllers = [moviesNVC, tvshowsNVC, animesNVC, settingsNVC]

        // Further Styling

    }

    func tabBarController(tabBarController: UITabBarController, animationControllerForTransitionFromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TransitioningObject()
    }

}

class TransitioningObject: NSObject, UIViewControllerAnimatedTransitioning {

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        let fromView: UIView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView: UIView = transitionContext.viewForKey(UITransitionContextToViewKey)!

        transitionContext.containerView()!.addSubview(fromView)
        transitionContext.containerView()!.addSubview(toView)

        toView.alpha = 0

        UIView.animateWithDuration(transitionDuration(transitionContext), delay:0, options:.CurveEaseOut, animations: { () -> Void in
            toView.alpha = 1
            fromView.alpha = 0
        }) { (Bool) -> Void in
            transitionContext.completeTransition(true)
        }
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.15
    }
}
