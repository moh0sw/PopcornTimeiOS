

import UIKit
import Reachability
import AlamofireNetworkActivityIndicator
import GoogleCast
import SwiftyUserDefaults

let safariLoginNotification = "kCloseSafariViewControllerNotification"
let errorNotification = "kErrorNotification"
let traktAuthenticationErrorNotification = "kTraktAuthenticationErrorNotification"
let animationLength = 0.33

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var reachability = Reachability.reachabilityForInternetConnection()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NetworkActivityIndicatorManager.sharedManager.isEnabled = true
        window?.tintColor = UIColor.appColor()
        reachability.startNotifier()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reachabilityChanged(_:)), name: kReachabilityChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(problemAuthenticatingTrakt), name: traktAuthenticationErrorNotification, object: nil)
        
        if Defaults[.TOSAccepted] {
            self.window?.makeKeyAndVisible()
            self.window?.rootViewController?.presentViewController(R.storyboard.terms.initialViewController()!, animated: false, completion: nil)
        }
        
        UIApplication.sharedApplication().windows.first?.rootViewController
        
        GCKCastContext.setSharedInstanceWithOptions(GCKCastOptions(receiverApplicationID: kGCKMediaDefaultReceiverApplicationID))
        mkdir("/var/mobile/Library/Popcorn Time", 0755)
        return true
    }
    
    func problemAuthenticatingTrakt() {
            let errorAlert = UIAlertController(title: "Problem authenticating with trakt", message: nil, preferredStyle: .Alert)
            errorAlert.addAction(UIAlertAction(title: "Sign Out", style: .Destructive, handler: { (action) in
                OAuthCredential.deleteCredentialWithIdentifier("trakt")
                Defaults[.AuthorizedTrakt] = false
            }))
            errorAlert.addAction(UIAlertAction(title: "Settings", style: .Default, handler:{ (action) in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let settings = storyboard.instantiateViewControllerWithIdentifier("SettingsTableViewController") as! SettingsTableViewController
                self.window?.rootViewController?.navigationController?.pushViewController(settings, animated: true)
            }))
            errorAlert.show()
    }
    
    func reachabilityChanged(notification: NSNotification) {
        if !reachability!.isReachableViaWiFi() && !reachability!.isReachableViaWWAN() {
            dispatch_async(dispatch_get_main_queue(), {
                let errorAlert = UIAlertController(title: "Oops..", message: "You are not connected to the internet anymore. Popcorn Time will automatically reconnect once it detects a valid internet connection.", preferredStyle: UIAlertControllerStyle.Alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
                errorAlert.show()
            })
        }
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if let sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String where (sourceApplication == "com.apple.SafariViewService" || sourceApplication == "com.apple.mobilesafari") && url.scheme == "PopcornTime" {
            NSNotificationCenter.defaultCenter().postNotificationName(safariLoginNotification, object: url)
            return true
        } else if url.scheme == "magnet" {
            cleanMagnet(url.absoluteString)
        }
        return false
    }

    func applicationDidBecomeActive(application: UIApplication) {
        UpdateManager.sharedManager.checkVersion(.Daily)
    }

}

