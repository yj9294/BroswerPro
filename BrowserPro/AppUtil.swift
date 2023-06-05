//
//  AppUtil.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/30.
//

import Foundation
import UIKit

class AppUtil: NSObject {
    static let shared = AppUtil()
    
    var rootVC: UIViewController? {
        if let keyWindow = UIApplication.shared.windows.filter({$0.isKeyWindow}).first, let rootVC = keyWindow.rootViewController {
            if let vc = rootVC.presentedViewController {
                if let presentedVC = vc.presentedViewController {
                    return presentedVC
                }
                return vc
            }
            return rootVC
        }
        return nil
    }
    
    class func isUrlValid(_ str: String) -> Bool {
        let url = "[a-zA-z]+://.*"
        let predicate = NSPredicate(format: "SELF MATCHES %@", url)
        return predicate.evaluate(with: str)
    }
    
    class func alert(_ message: String) {
        let vc = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        AppUtil.shared.rootVC?.present(vc, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            vc.dismiss(animated: true)
        }
    }
}
