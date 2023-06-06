//
//  CleanViewController.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/31.
//

import UIKit

class CleanViewController: UIViewController {
    
    @IBOutlet weak var animationView: UIImageView!

    var isPresented = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.loading()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 14.0) {
            if !self.isPresented {
                self.isPresented = true
                self.cleaned()
            }
        }
        GADUtil.share.load(.interstitial)
    }
    
    func cleaned() {
        BrowserUtil.shared.clean(from: self)
        FirebaseUtil.log(event: .cleanSuccess)
        FirebaseUtil.log(event: .cleanAlert)
        self.dismiss(animated: true)
    }
    
    func loading() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if GADUtil.share.isLoaded(.interstitial), !self.isPresented {
                timer.invalidate()
                self.isPresented = true
                GADUtil.share.show(.interstitial, from: self) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.cleaned()
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        starAnimation()
    }
    
    func starAnimation() {
        UIView.animate(withDuration: 1.5, delay: 0) {
            self.animationView.transform = CGAffineTransformMakeRotation(.pi * 1)
        } completion: { ret  in
            UIView.animate(withDuration: 1.5, delay: 0) {
                self.animationView.transform = CGAffineTransformMakeRotation(0)
            } completion: { ret  in
                self.starAnimation()
            }
        }
    }
    
    func stopAnimation() {
        animationView.layer.removeAllAnimations()
    }

}
