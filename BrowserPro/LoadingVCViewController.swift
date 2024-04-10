//
//  LoadingVCViewController.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/29.
//

import UIKit
import GADUtil

class LoadingVCViewController: UIViewController {
    
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    var isPresented = false

    override func viewDidLoad() {
        super.viewDidLoad()
        loading()
    }
    
    func loading() {
        self.progressView.updateConstraints()
        UIView.animate(withDuration: 14.0, delay: 0) {
            self.widthConstraint.constant = self.view.bounds.width
            self.progressView.layoutIfNeeded()
        } completion: { ret in
            if ret, !self.isPresented {
                self.isPresented = true
                self.performSegue(withIdentifier: "toBrowserViewController", sender:  nil)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            self.progressing()
        }
        
        GADUtil.share.load(GADMobPosition.native)
        GADUtil.share.load(GADMobPosition.interstitial)
    }
    
    @objc func progressing() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self = self else {return}
            if GADUtil.share.isLoaded(GADMobPosition.interstitial) {
                timer.invalidate()
                self.widthConstraint.constant = self.view.bounds.width
                GADUtil.share.show(GADMobPosition.interstitial, from: self) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.performSegue(withIdentifier: "toBrowserViewController", sender:  nil)
                    }
                }
            }
        }
    }
}
