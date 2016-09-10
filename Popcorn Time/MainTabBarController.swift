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
    }

    func launchApp() {
        self.viewControllers = [moviesNVC, tvshowsNVC, animesNVC, settingsNVC]
    }

}
