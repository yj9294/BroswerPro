//
//  TabViewController.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/30.
//

import Foundation
import UIKit

class TabViewController: UIViewController {
    
    var dataSource: [WebViewItem] {
        BrowserUtil.shared.webItems
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseUtil.log(event: .tabShow)
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
