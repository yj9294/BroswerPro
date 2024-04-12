//
//  SceneDelegate.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/29.
//

import UIKit
import GADUtil
import TBAUtil
import Firebase
import FBSDKCoreKit
import GoogleMobileAds

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var appenterbackground = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        if let url = connectionOptions.urlContexts.first?.url {
            ApplicationDelegate.shared.application(
                    UIApplication.shared,
                    open: url,
                    sourceApplication: nil,
                    annotation: [UIApplication.OpenURLOptionsKey.annotation]
                )
        }
        
        networkInit()
        
        gadInit()
        
        tbaInit()
        
        firebaseInit()
        
        vpnInit()
        
        NSLog("[tba] \(TBACacheUtil.shared.getUUID())")
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        if appenterbackground {
            FirebaseUtil.log(event: .openHot)
        }
        
        appenterbackground = false
        
        if !AppUtil.shared.isVPNPermission {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoadingVC")
            window?.rootViewController = vc
        }
        
        EventRequest.sessionRequest()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        appenterbackground = true
    }
}

extension SceneDelegate {
    func networkInit() {
        ReachabilityUtil.shared.startMonitoring()
        NotificationCenter.default.addObserver(self, selector: #selector(networkUpdated), name: .reachabilityChanged, object: nil)
    }
    
    func firebaseInit() {
        FirebaseApp.configure()
        FirebaseUtil.log(property: .local)
        FirebaseUtil.log(event: .open)
        FirebaseUtil.log(event: .openCold)

    }
    
    @objc func networkUpdated() {
        GADUtil.share.load(GADMobPosition.interstitial)
        GADUtil.share.load(GADMobPosition.native)
    }
    
    func gadInit() {
        GADUtil.initializePositions(GADMobPosition.allCases)
        GADUtil.share.requestConfig()
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [uuid]
        NotificationCenter.default.addObserver(self, selector: #selector(adImpression), name: .adImpression, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adPaid), name: .adPaid, object: nil)
    }
    
    @objc func adImpression(noti: Notification) {
        if let ad = noti.object as? GADBaseModel {
            let result = TBACacheUtil.shared.needUploadFBPrice()
            if result.0 {
                AppEvents.shared.logPurchase(amount: result.1.price, currency: result.1.currency)
            } else {
                TBACacheUtil.shared.addFBPrice(price: ad.price, currency: ad.currency)
            }
        }
    }
    
    @objc func adPaid(noti: Notification) {
        if let ad = noti.object as? GADBaseModel {
            EventRequest.tbaADRequest(ad: ad)
        }
    }
    
    func tbaInit() {
        EventRequest.preloadPool()
        
        EventRequest.installRequest()
        
        EventRequest.firstOpenRequest()
        
        EventRequest.cloakRequest()
    }
    
    func vpnInit() {
        VPNUtil.shared.load()
        VPNUtil.shared.prepareForLoading {
            debugPrint("[VPN MANAGER] prepareForLoading manager state: \(VPNUtil.shared.managerState), VPN state: \(VPNUtil.shared.vpnState)")
        }
        VPNCountryList.requestConfig()
        VPNCountryList.requestRemoteConfig()
    }
}

