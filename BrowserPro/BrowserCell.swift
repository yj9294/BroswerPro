//
//  BrowserCell.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/30.
//

import UIKit

class BrowserCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    var item: BrowserViewControllerItem? {
        didSet {
            titleLabel.text = item?.title
            iconView.image = item?.icon
        }
    }
    
}
