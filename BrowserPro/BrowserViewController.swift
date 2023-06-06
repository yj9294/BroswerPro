//
//  BrowserViewController.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/30.
//

import UIKit
import WebKit
import IQKeyboardManagerSwift
import AppTrackingTransparency

class BrowserViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var lastButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var tabButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var cleanAlertView: UIView!
    
    @IBOutlet weak var adView: GADNativeView!
    var willAppear = false
    
    var homeNativeAdImpressionDate = Date(timeIntervalSinceNow: -11)

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        willAppear = true
        IQKeyboardManager.shared.enable = true
        refreshStatus()
        addObserver()
        addADNotification()
        FirebaseUtil.log(event: .homeShow)
        
        ATTrackingManager.requestTrackingAuthorization { _ in
        }
        
        GADUtil.share.load(.native)
        GADUtil.share.load(.interstitial)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        willAppear = false
        GADUtil.share.close(.native)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        BrowserUtil.shared.webItem.webView.frame = contentView.bounds
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SettingViewController {
            vc.termsHandle = {
                self.performSegue(withIdentifier: "toTermsViewController", sender: nil)
            }
            vc.privacyHandle = {
                self.performSegue(withIdentifier: "toPrivacyViewController", sender: nil)
            }
        }
    }
    
    func addADNotification() {
        NotificationCenter.default.addObserver(forName: .nativeUpdate, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else {return}
            if let ad = noti.object as? NativeADModel, self.willAppear == true {
                if self.homeNativeAdImpressionDate.timeIntervalSinceNow < -10 {
                    self.adView.nativeAd = ad.nativeAd
                    self.homeNativeAdImpressionDate = Date()
                } else {
                    NSLog("[ad] 10s home 原生广告刷新或数据填充间隔.")
                }
            } else {
                self.adView.nativeAd = nil
            }
        }
    }

}

extension BrowserViewController {
    
    @IBAction func searchViewAction(btn: UIButton) {
        btn.isSelected ? stopSearch() : search(btn: btn)
        btn.isSelected = !btn.isSelected
    }
    
    @IBAction func goBack() {
        BrowserUtil.shared.goBack()
    }
    
    @IBAction func goForword() {
        BrowserUtil.shared.goForword()
    }
    
    @IBAction func cleanAlert() {
        cleanAlertView.isHidden = false
        
        FirebaseUtil.log(event: .cleanClick)
    }
        
    @IBAction func hiddenCleanAlert() {
        cleanAlertView.isHidden = true
    }
    
    @IBAction func clean() {
        hiddenCleanAlert()
        performSegue(withIdentifier: "toCleanViewController", sender: nil)
    }
    
    func search(btn: UIButton) {
        if let text = textField.text, text.count > 0 {
            BrowserUtil.shared.load(text, from: self)
            FirebaseUtil.log(event: .navigaSearch, params: ["bro": text])
        } else {
            btn.isSelected = false
            AppUtil.alert("Please enter your search content.")
        }
    }
    
    func stopSearch() {
        BrowserUtil.shared.stopLoad()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        refreshStatus()
    }
    
    func refreshStatus() {
        lastButton.isEnabled = BrowserUtil.shared.canGoBack()
        nextButton.isEnabled = BrowserUtil.shared.canGoForword()
        
        progressView.progress = BrowserUtil.shared.progress()
        progressView.isHidden = !BrowserUtil.shared.isLoading()
        textField.text = BrowserUtil.shared.url()
        searchButton.isSelected = BrowserUtil.shared.isLoading()
        
        tabButton.setTitle("\(BrowserUtil.shared.webItems.count)", for: .normal)
        tabButton.setTitleColor(.white, for: .normal)
        tabButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        tabButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        
        var date = Date()
        if BrowserUtil.shared.progress() == 0.1 {
            FirebaseUtil.log(event: .webStart)
            date = Date()
        }
        
        if BrowserUtil.shared.progress() == 1.0 {
            let time = abs(date.timeIntervalSinceNow)
            FirebaseUtil.log(event: .webSuccess, params: ["bro": "\(ceil(time))"])
        }
    }
    
    func addObserver() {
        if !BrowserUtil.shared.isNavigation(), BrowserUtil.shared.url().count != 0 {
            removeWebView()
            contentView.addSubview(BrowserUtil.shared.webItem.webView)
            BrowserUtil.shared.webItem.webView.navigationDelegate = self
            BrowserUtil.shared.webItem.webView.uiDelegate = self
//            BrowserUtil.shared.webItem.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
//            BrowserUtil.shared.webItem.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), context: nil)
        }
        
        if BrowserUtil.shared.isNavigation() {
            removeWebView()
        }
    }
    
    func removeWebView() {
        contentView.subviews.forEach {
            if $0 is WKWebView {
                $0.removeFromSuperview()
            }
        }
    }
}

extension BrowserViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        BrowserViewControllerItem.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BrowserCell", for: indexPath)
        if let cell = cell as? BrowserCell {
            let item = BrowserViewControllerItem.allCases[indexPath.row]
            cell.item = item
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.bounds.width - 32 - 40*3 ) / 4.0 - 5
        let heigth = 80.0
        return CGSize(width: width, height: heigth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 40.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = BrowserViewControllerItem.allCases[indexPath.row]
        textField.text = item.url
        BrowserUtil.shared.load(item.url, from: self)
        
        FirebaseUtil.log(event: .navigaClick, params: ["bro": item.rawValue])
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        search(btn: searchButton)
        return true
    }
    
}

extension BrowserViewController: WKUIDelegate, WKNavigationDelegate {
    /// 跳转链接前是否允许请求url
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        lastButton.isEnabled = webView.canGoBack
        nextButton.isEnabled = webView.canGoForward
        return .allow
    }
    
    /// 响应后是否跳转
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        lastButton.isEnabled = webView.canGoBack
        nextButton.isEnabled = webView.canGoForward
        return .allow
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        /// 打开新的窗口
        lastButton.isEnabled = webView.canGoBack
        nextButton.isEnabled = webView.canGoForward
        webView.load(navigationAction.request)
        return nil
    }
}


enum BrowserViewControllerItem: String, CaseIterable {
    case facebook, google, youtube, twitter, instagram, amazon, gmail, yahoo
    var title: String {
        self.rawValue.capitalized
    }
    var icon: UIImage {
        UIImage(named: self.rawValue) ?? UIImage()
    }
    var url: String {
        "https://www.\(self.rawValue).com"
    }
}
