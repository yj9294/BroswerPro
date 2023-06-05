//
//  SettingViewController.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/30.
//

import UIKit
import MobileCoreServices

class SettingViewController: UIViewController {
    
    var privacyHandle:(()->Void)? = nil
    var termsHandle:(()->Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func dismiss() {
        dismiss(animated: true)
    }
    
    @IBAction func newAction() {
        BrowserUtil.shared.add()
        dismiss()
        
        FirebaseUtil.log(event: .tabNew, params: ["bro": "setting"])
    }
    
    @IBAction func share() {
        dismiss()
        var url = "https://itunes.apple.com/cn/app/id"
        if !BrowserUtil.shared.webItem.isNavigation {
            url = BrowserUtil.shared.webItem.webView.url?.absoluteString ?? "https://itunes.apple.com/cn/app/id"
        }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(vc, animated: true)
        
        FirebaseUtil.log(event: .shareClick)
    }
    
    @IBAction func copyAction() {
        dismiss()
        if !BrowserUtil.shared.webItem.isNavigation {
            UIPasteboard.general.setValue(BrowserUtil.shared.webItem.webView.url?.absoluteString ?? "", forPasteboardType: kUTTypePlainText as String)
            AppUtil.alert("Copy successfully.")
        } else {
            UIPasteboard.general.setValue("", forPasteboardType: kUTTypePlainText as String)
            AppUtil.alert("Copy successfully.")
        }
        
        FirebaseUtil.log(event: .copyClick)
    }
    
    @IBAction func rate() {
        dismiss()
        let url = URL(string: "https://itunes.apple.com/cn/app/id")
        if let url = url {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func privacy() {
        dismiss()
        privacyHandle?()
    }
    
    @IBAction func terms() {
        dismiss()
        termsHandle?()
    }
    

}
