//
//  GADNativeBigView.swift
//  BrowserPro
//
//  Created by Super on 2024/4/9.
//

import UIKit
import GoogleMobileAds

class GADNativeBigView: GADNativeView {

    @IBOutlet weak var playView: GADMediaView!

    override var nativeAd: GADNativeAd? {
        didSet {
            super.nativeAd = nativeAd
            if let nativeAd = nativeAd {
                self.playView.mediaContent = nativeAd.mediaContent
            } else {
                self.icon.isHidden = true
                self.title.isHidden = true
                self.subTitle.isHidden = true
                self.install.isHidden = true
                self.adTag.isHidden = true
                self.placeholder.isHidden = false
                self.playView.isHidden  = false
            }
            mediaView = playView
        }
    }
}
