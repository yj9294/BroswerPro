//
//  TabCell.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/30.
//

import UIKit

class TabCell: UICollectionViewCell {
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    var deleteHandle: ((WebViewItem)->Void)? = nil
    var selectHandle: ((WebViewItem)->Void)? = nil
    var item: WebViewItem? {
        didSet {
            titleLabel.text = item?.webView.url?.absoluteString ?? ""
            deleteButton.isHidden = BrowserUtil.shared.webItems.count == 1
            if item?.isSelect == true {
                layer.borderWidth = 2.5
                layer.borderColor = UIColor.white.cgColor
            } else {
                layer.borderWidth = 1
                layer.borderColor = UIColor.gray.cgColor
            }
        }
    }
    
    @IBAction func deleteAction() {
        deleteHandle?(item ?? .navgationItem)
    }
    
    @IBAction func selectAction() {
        selectHandle?(item ?? .navgationItem)
    }
    
}
