//
//  Constants.swift
//  PopcornTime
//
//  Created by Alex on 10/09/2016.
//  Copyright © 2016 Popcorn Time. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

func delay(delay: Double, closure: () -> ()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

extension DefaultsKeys {
    static let TOSAccepted = DefaultsKey<Bool>("TOSAccepted")
    static let AuthorizedTrakt = DefaultsKey<Bool>("AuthorizedTrakt")
    static let RemoveCacheOnPlayerExit = DefaultsKey<Bool>("RemoveCacheOnPlayerExit")
    static let StreamOnCellular = DefaultsKey<Bool>("StreamOnCellular")
    static let AuthorizedOpenSubs = DefaultsKey<Bool>("AuthorizedOpenSubs")
    
    static let PreferredSubtitleLanguage = DefaultsKey<String?>("PreferredSubtitleLanguage")
    static let PreferredSubtitleColor = DefaultsKey<String?>("PreferredSubtitleColor")
    static let PreferredSubtitleFont = DefaultsKey<String?>("PreferredSubtitleFont")
    static let PreferredSubtitleFontStyle = DefaultsKey<String?>("PreferredSubtitleFontStyle")
    static let PreferredSubtitleSize = DefaultsKey<String?>("PreferredSubtitleSize")
    static let PreferredQuality = DefaultsKey<String?>("PreferredQuality")
}

struct ScreenSize {
    static let SCREEN_WIDTH = UIScreen.mainScreen().bounds.size.width
    static let SCREEN_HEIGHT = UIScreen.mainScreen().bounds.size.height
    static let SCREEN_MAX_LENGTH = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType {
    static let IS_IPHONE_4_OR_LESS =  UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5 = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6 = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6P = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
}

struct Constants {
    
    struct App {
        static let AppStoreID = ""
        static let AppStoreDeveloperID = ""
    }
    
    struct ThemeApp {
        static let iconFontName = ""
        static let RegularFontName = ""
        static let BoldFontName = ""
    }
}