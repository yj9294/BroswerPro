//
//  AppUtil.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/30.
//

import Foundation
import TBAUtil
import UIKit

class AppUtil: NSObject {
    static let shared = AppUtil()
    
    var isShowGuideView: Bool = true
    var isDebug: Bool = Bundle.main.bundleIdentifier !=  "com.searchPro.browsers.fastApp"
    
    // MARK: App信息
    /// 应用名称
    static let name: String = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? "PopularBrowser"
    /// 版本号
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    /// build号
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0.0"
    /// 包名
    static let bundle = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "com.lightforyou.cloud.application.LightVPN"
    
    static let group = "group." + bundle
    
    static let proxy = bundle + ".Proxy"
    
    static let localCountry = Locale.current.regionCode
    
    static let isDebug = (Bundle.main.bundleIdentifier ?? "") != "com.perfectt.bbrowsers"
    
    static var rootVC: UIViewController? {
        let vc = (UIApplication.shared.connectedScenes.filter({$0 is UIWindowScene}).first as? UIWindowScene)?.windows.filter({$0.isKeyWindow}).first?.rootViewController
        if let presentedVC = vc?.presentedViewController {
            if let ppVC = presentedVC.presentedViewController {
                return ppVC
            }
            return presentedVC
        }
        return vc
    }
    
    class func isUrlValid(_ str: String) -> Bool {
        let url = "[a-zA-z]+://.*"
        let predicate = NSPredicate(format: "SELF MATCHES %@", url)
        return predicate.evaluate(with: str)
    }
    
    class func alert(_ message: String) {
        let vc = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        AppUtil.rootVC?.present(vc, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            vc.dismiss(animated: true)
        }
    }
    
    @UserDefault(key: "vpn.country.list")
    var vpnCountryList: VPNCountryList?
    var getVPNCountryList: VPNCountryList {
        vpnCountryList ?? .init(hCountries: [], lCountries: [], hRate: 100, lRate: 0)
    }
    
    @UserDefault(key: "vpn.country")
    var vpnCountry: VPNCountry?
    var getVPNCountry: VPNCountry {
        vpnCountry ?? .smart
    }
    
    @UserDefault(key: "vpn.connect.country")
    var vpnConnectCountry: VPNCountry?
    var getVPNConnectCountry: VPNCountry {
        vpnConnectCountry ?? .smart
    }
    
    
    var isVPNPermission = false
    var enterbackground = false
    
    var vpnHomeImpressionDate = Date().addingTimeInterval(-13)
    var vpnResultImpressionDate = Date().addingTimeInterval(-13)
}
