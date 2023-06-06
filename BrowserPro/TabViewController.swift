//
//  TabViewController.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/30.
//

import Foundation
import UIKit

class TabViewController: UIViewController {
    
    @IBOutlet weak var adView: GADNativeView!
    
    var tabNativeAdImpressionDate = Date(timeIntervalSinceNow: -11)
    var willAppear = false
    
    var dataSource: [WebViewItem] {
        BrowserUtil.shared.webItems
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addADNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        willAppear = true
        FirebaseUtil.log(event: .tabShow)
        GADUtil.share.load(.native)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        willAppear = false
        GADUtil.share.close(.native)
    }
    
    func addADNotification() {
        NotificationCenter.default.addObserver(forName: .nativeUpdate, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else {return}
            if let ad = noti.object as? NativeADModel, self.willAppear == true {
                if self.tabNativeAdImpressionDate.timeIntervalSinceNow < -10 {
                    self.adView.nativeAd = ad.nativeAd
                    self.tabNativeAdImpressionDate = Date()
                } else {
                    NSLog("[ad] 10s tab 原生广告刷新或数据填充间隔.")
                }
            } else {
                self.adView.nativeAd = nil
            }
        }
    }
}

extension TabViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCell", for: indexPath)
        if let cell = cell as? TabCell {
            let item = dataSource[indexPath.row]
            cell.deleteHandle = { [weak collectionView] item in
                BrowserUtil.shared.removeItem(item)
                collectionView?.reloadData()
            }
            cell.selectHandle = { [weak self] item in
                BrowserUtil.shared.select(item)
                self?.dismiss()
            }
            cell.item = item
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.bounds.width - 32 - 12) / 2.0 - 4
        let height = width / 169.0 * 216.0
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        12.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        12.0
    }
    
}

extension TabViewController {
    
    @IBAction func dismiss() {
        dismiss(animated: true)
    }
    
    @IBAction func new() {
        BrowserUtil.shared.add()
        dismiss()
        
        FirebaseUtil.log(event: .tabNew, params: ["bro": "tab"])
    }
    
}
