//
//  VPNResultViewController.swift
//  BrowserPro
//
//  Created by Super on 2024/4/9.
//

import UIKit
import GADUtil

class VPNResultViewController: UIViewController {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    
    @IBOutlet weak var adView: GADNativeView!
    var willAppear = false
    
    var isPresentBackAD = false
    
    enum State {
        case connected, disconnected
        var title: String {
            if self == .connected {
                return "Connected Now"
            } else {
                return "Disconnected Now"
            }
        }
        var icon: String {
            if self == .connected {
                return "vpn_result_connected"
            } else {
                return "vpn_result_disconnected"
            }
        }
    }
    
    var state: State = .connected
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iconView.image = UIImage(named: state.icon)
        statusLabel.text = state.title
        addADNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        willAppear = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(back))
        countryLabel.text = AppUtil.shared.getVPNConnectCountry.title
        GADUtil.share.disappear(GADMobPosition.vpnResult)
        if isPresentBackAD {
            return
        }
        if state == .connected {
            GADUtil.share.load(GADMobPosition.vpnResult, p: GADMobScene.vpnConnect)
        } else {
            GADUtil.share.load(GADMobPosition.vpnResult, p: GADMobScene.vpnDisconnect)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        willAppear = false
        GADUtil.share.disappear(GADMobPosition.vpnResult)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func back() {
        isPresentBackAD = true
        GADUtil.share.show(GADMobPosition.vpnBack) { _ in
            self.navigationController?.popViewController(animated: true)
        }
    }

    func addADNotification() {
        NotificationCenter.default.addObserver(forName: .nativeUpdate, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else {return}
            if let ad = noti.object as? GADNativeModel, ad.position.rawValue == GADMobPosition.vpnResult.rawValue {
                if self.willAppear {
                    if AppUtil.shared.vpnResultImpressionDate.timeIntervalSinceNow < -12 {
                        self.adView.nativeAd = ad.nativeAd
                        AppUtil.shared.vpnResultImpressionDate = Date()
                    } else {
                        NSLog("[ad] 12s vpn home 原生广告刷新或数据填充间隔.")
                        self.adView.nativeAd = nil
                    }
                } else {
                    self.adView.nativeAd = nil
                }
            } else if noti.object == nil {
                self.adView.nativeAd = nil
            }
        }
    }

}
