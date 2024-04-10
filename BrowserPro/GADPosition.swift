//
//  GADPosition.swift
//  BrowserPro
//
//  Created by Super on 2024/4/8.
//

import Foundation
import GADUtil

enum GADMobPosition: String, GADPosition, CaseIterable {
    var isNative: Bool {
        if self == .native {
            return true
        }
        if self == .vpnResult {
            return true
        }
        if self == .vpnHome {
            return true
        }
        return false
    }
    
    var isOpen: Bool {
        return false
    }
    
    var isInterstital: Bool {
        if self == .interstitial {
            return true
        }
        if self == .vpnConnect {
            return true
        }
        if self == .vpnBack {
            return true
        }
        return false
    }
    
    var isPreload: Bool {
        if self == .vpnBack {
            return false
        }
        return true
    }
    
    case native, interstitial, vpnHome, vpnConnect, vpnResult, vpnBack
}


enum GADMobScene: String, GADScene, CaseIterable {
    case native, interstitial, vpnhome, vpnConnect, vpnDisconnect, vpnResultConnect, vpnResultDisconnect, vpnBack
}
