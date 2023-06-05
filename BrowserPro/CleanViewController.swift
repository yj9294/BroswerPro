//
//  CleanViewController.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/31.
//

import UIKit

class CleanViewController: UIViewController {
    
    @IBOutlet weak var animationView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            BrowserUtil.shared.clean(from: self)
            FirebaseUtil.log(event: .cleanSuccess)
            FirebaseUtil.log(event: .cleanAlert)
            self.dismiss(animated: true)
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
