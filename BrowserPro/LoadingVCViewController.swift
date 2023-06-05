//
//  LoadingVCViewController.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/29.
//

import UIKit

class LoadingVCViewController: UIViewController {
    
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        loading()
    }
    
    func loading() {
        self.progressView.updateConstraints()
        UIView.animate(withDuration: 3, delay: 0) {
            self.widthConstraint.constant = self.view.bounds.width
            self.progressView.layoutIfNeeded()
        } completion: { ret in
            if ret {
                self.performSegue(withIdentifier: "toBrowserViewController", sender:  nil)
            }
        }
    }
    
}
