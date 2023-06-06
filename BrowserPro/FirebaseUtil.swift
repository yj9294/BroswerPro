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
    
    static func requestRemoteConfig() {
        // 获取本地配置
        if GADUtil.share.adConfig == nil {
            let path = Bundle.main.path(forResource: "admob", ofType: "json")
            let url = URL(fileURLWithPath: path!)
            do {
                let data = try Data(contentsOf: url)
                GADUtil.share.adConfig = try JSONDecoder().decode(ADConfig.self, from: data)
                NSLog("[Config] Read local ad config success.")
            } catch let error {
                NSLog("[Config] Read local ad config fail.\(error.localizedDescription)")
            }
        }
        
        /// 远程配置
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        remoteConfig.configSettings = settings
        remoteConfig.fetch { [weak remoteConfig] (status, error) -> Void in
            if status == .success {
                NSLog("[Config] Config fetcher! ✅")
                remoteConfig?.activate(completion: { _, _ in
                    let keys = remoteConfig?.allKeys(from: .remote)
                    NSLog("[Config] config params = \(keys ?? [])")
                    if let remoteAd = remoteConfig?.configValue(forKey: "adConfig").stringValue {
                        // base64 的remote 需要解码
                        let data = Data(base64Encoded: remoteAd) ?? Data()
                        if let remoteADConfig = try? JSONDecoder().decode(ADConfig.self, from: data) {
                            // 需要在主线程
                            DispatchQueue.main.async {
                                GADUtil.share.adConfig = remoteADConfig
                            }
                        } else {
                            NSLog("[Config] Config config 'adConfig' is nil or config not json.")
                        }
                    }
                })
            } else {
                NSLog("[Config] config not fetcher, error = \(error?.localizedDescription ?? "")")
            }
        }
        
        /// 广告配置是否是当天的
        if GADUtil.share.limit == nil || GADUtil.share.limit?.date.isToday != true {
            GADUtil.share.limit = ADLimit(showTimes: 0, clickTimes: 0, date: Date())
        }
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
