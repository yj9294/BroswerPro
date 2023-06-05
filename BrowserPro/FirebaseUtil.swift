//
//  FirebaseUtil.swift
//  BrowserPro
//
//  Created by yangjian on 2023/6/1.
//

import Foundation
import Firebase

class FirebaseUtil: NSObject {
    static func log(event: FirebaseEvent, params: [String: Any]? = nil) {
        
        if event.first {
            if UserDefaults.standard.bool(forKey: event.rawValue) == true {
                return
            } else {
                UserDefaults.standard.set(true, forKey: event.rawValue)
            }
        }
        
        #if DEBUG
        #else
        Analytics.logEvent(event.rawValue, parameters: params)
        #endif
        
        NSLog("[Event] \(event.rawValue) \(params ?? [:])")
    }
    
    static func log(property: FirebaseProPerty, value: String? = nil) {
        
        var value = value
        
        if property.first {
            if UserDefaults.standard.string(forKey: property.rawValue) != nil {
                value = UserDefaults.standard.string(forKey: property.rawValue)!
            } else {
                UserDefaults.standard.set(Locale.current.regionCode ?? "us", forKey: property.rawValue)
            }
        }
#if DEBUG
#else
        Analytics.setUserProperty(value, forName: property.rawValue)
#endif
        NSLog("[Property] \(property.rawValue) \(value ?? "")")
    }
}

enum FirebaseProPerty: String {
    /// 設備
    case local = "pro_borth"
    
    var first: Bool {
        switch self {
        case .local:
            return true
        }
    }
}

enum FirebaseEvent: String {
    
    var first: Bool {
        switch self {
        case .open:
            return true
        default:
            return false
        }
    }
    
    case open = "pro_lun"
    case openCold = "pro_clod"
    case openHot = "pro_hot"
    case homeShow = "pro_impress"
    case navigaClick = "pro_nav"
    case navigaSearch = "pro_search"
    case cleanClick = "pro_clean"
    case cleanSuccess = "pro_cleanDone"
    case cleanAlert = "pro_cleanToast"
    case tabShow = "pro_showTab"
    case tabNew = "pro_clickTab"
    case shareClick = "pro_share"
    case copyClick = "pro_copy"
    case webStart = "pro_requist"
    case webSuccess = "pro_load"
}
