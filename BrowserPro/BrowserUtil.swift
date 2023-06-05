//
//  BrowserUtil.swift
//  BrowserPro
//
//  Created by yangjian on 2023/5/30.
//

import Foundation
import UIKit
import WebKit

class BrowserUtil: NSObject {
    static let shared = BrowserUtil()
    var webItems:[WebViewItem] = [.navgationItem]
    
    var webItem: WebViewItem {
        webItems.filter {
            $0.isSelect == true
        }.first ?? .navgationItem
    }
    
    func removeItem(_ item: WebViewItem) {
        if item.isSelect {
            webItems = webItems.filter {
                $0 != item
            }
            webItems.first?.isSelect = true
        } else {
            webItems = webItems.filter {
                $0 != item
            }
        }
    }
    
    func clean(from vc: UIViewController) {
        webItems.filter {
            !$0.isNavigation && $0.isSelect
        }.compactMap {
            $0.webView
        }.forEach {
            $0.removeFromSuperview()
        }
        webItems = [.navgationItem]
    }
    
    func add(_ item: WebViewItem = .navgationItem) {
        webItems.forEach {
            $0.isSelect = false
        }
        webItems.insert(item, at: 0)
    }
    
    func select(_ item: WebViewItem) {
        if !webItems.contains(item) {
            return
        }
        webItems.forEach {
            $0.isSelect = false
        }
        item.isSelect = true
    }
    
    func load(_ url: String, from vc: BrowserViewController) {
        webItem.loadUrl(url, from: vc)
    }
    
    func stopLoad() {
        webItem.stopLoad()
    }
    
    func canGoBack() -> Bool {
        webItem.webView.canGoBack
    }
    
    func canGoForword() -> Bool {
        webItem.webView.canGoForward
    }
    
    func isLoading() -> Bool {
        webItem.webView.estimatedProgress > 0.0 && webItem.webView.estimatedProgress < 1.0
    }
    
    func url() -> String {
        webItem.webView.url?.absoluteString ?? ""
    }
    
    func isNavigation() -> Bool {
        webItem.isNavigation
    }
    
    func progress() -> Float {
        Float(webItem.webView.estimatedProgress)
    }
    
    func goBack() {
        BrowserUtil.shared.webItem.webView.goBack()
    }
    
    func goForword() {
        BrowserUtil.shared.webItem.webView.goForward()
    }
    
}

class WebViewItem: NSObject {
    
    init(webView: WKWebView, isSelect: Bool) {
        self.webView = webView
        self.isSelect = isSelect
    }
    var webView: WKWebView
    
    var isNavigation: Bool {
        webView.url == nil
    }
    var isSelect: Bool
    
    func loadUrl(_ url: String, from vc: BrowserViewController) {
        // 移出 view
        BrowserUtil.shared.webItems.filter({
            !$0.isNavigation
        }).compactMap({
            $0.webView
        }).forEach {
            $0.removeFromSuperview()
        }
        // 添加 view
        vc.contentView.addSubview(webView)
        if AppUtil.isUrlValid(url), let Url = URL(string: url) {
            let request = URLRequest(url: Url)
            webView.load(request)
            if webView.observationInfo != nil {
                webView.removeObserver(vc, forKeyPath: #keyPath(WKWebView.estimatedProgress))
                webView.removeObserver(vc, forKeyPath: #keyPath(WKWebView.url))
            }
            webView.addObserver(vc, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
            webView.addObserver(vc, forKeyPath: #keyPath(WKWebView.url), context: nil)
        } else {
            let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let reqString = "https://www.google.com/search?q=" + urlString
            self.loadUrl(reqString, from: vc)
        }
    }
    
    func stopLoad() {
        webView.stopLoading()
    }
    
    static var navgationItem: WebViewItem {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.isOpaque = false
        webView.clipsToBounds = true
        return WebViewItem(webView: webView, isSelect: true)
    }
}
