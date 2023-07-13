//
//  GADUtil.swift
//  BrowserPro
//
//  Created by yangjian on 2023/7/13.
//

import Foundation
import GoogleMobileAds
import Firebase

class GADUtil: NSObject {
    static let share = GADUtil()
    
    public var appenterbackground: Bool = false
    
    override init() {
        super.init()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.ads.forEach {
                $0.loadedArray = $0.loadedArray.filter({ model in
                    return model.loadedDate?.isExpired == false
                })
            }
        }
    }
    
    // 本地记录 配置
    var adConfig: ADConfig? {
        set{
            UserDefaults.standard.setModel(newValue, forKey: "adConfig")
        }
        get {
            UserDefaults.standard.model(ADConfig.self, forKey: "adConfig")
        }
    }
    
    // 本地记录 限制次数
    var limit: ADLimit? {
        set{
            UserDefaults.standard.setModel(newValue, forKey: "adLimited")
        }
        get {
            UserDefaults.standard.model(ADLimit.self, forKey: "adLimited")
        }
    }
    
    /// 是否超限
    fileprivate var isADLimited: Bool {
        if limit?.date.isToday == true {
            if (limit?.showTimes ?? 0) >= (adConfig?.showTimes ?? 0) || (limit?.clickTimes ?? 0) >= (adConfig?.clickTimes ?? 0) {
                return true
            }
        }
        return false
    }
        
    /// 广告位加载模型
    fileprivate let ads:[ADLoadModel] = ADPosition.allCases.map { p in
        ADLoadModel(position: p)
    }
    
    // native ad impression date
    public var tabNativeAdImpressionDate: Date = Date(timeIntervalSinceNow: -11)
}

extension GADUtil {
    
    public func isLoadedIngerstitalAD() -> Bool {
        return self.ads.filter {
            $0.position == .interstitial
        }.first?.isLoaded == true
    }
    
    public func getConfig() -> ADConfig? {
        return adConfig
    }
    
    public func updateConfig(_ config: ADConfig) {
        DispatchQueue.main.async {
            self.adConfig = config
        }
    }
    
    public func isNeedCleanLimit() -> Bool {
        return limit == nil || limit?.date.isToday != true
    }
    
    public func cleanLimit() {
        limit = ADLimit(showTimes: 0, clickTimes: 0, date: Date())
    }
    
    /// 限制
    fileprivate func add(_ status: ADLimit.Status) {
        if status == .show {
            if isADLimited {
                NSLog("[AD] 用戶超限制。")
                self.clean(.interstitial)
                self.clean(.native)
                return
            }
            let showTime = limit?.showTimes ?? 0
            limit?.showTimes = showTime + 1
            NSLog("[AD] [LIMIT] showTime: \(showTime+1) total: \(adConfig?.showTimes ?? 0)")
        } else  if status == .click {
            let clickTime = limit?.clickTimes ?? 0
            limit?.clickTimes = clickTime + 1
            NSLog("[AD] [LIMIT] clickTime: \(clickTime+1) total: \(adConfig?.clickTimes ?? 0)")
            if isADLimited {
                NSLog("[AD] 用戶超限制。")
                self.clean(.interstitial)
                self.clean(.native)
                return
            }
        }
    }
    
    /// 加载
    public func load(_ position: ADPosition, completion: (()->Void)? = nil) {
        let ads = ads.filter{
            $0.position == position
        }
        if let ad = ads.first {
            ad.beginAddWaterFall { isSuccess in
                completion?()
                if isSuccess {
                    switch position {
                    case .native:
                        self.show(position) { ad in
                            NotificationCenter.default.post(name: .nativeUpdate, object: ad)
                        }
                    default:
                        break
                    }
                }
            }
        } else {
            completion?()
        }
    }
    
    /// 展示
    public func show(_ position: ADPosition, from vc: UIViewController? = nil , completion: @escaping (ADBaseModel?)->Void) {
        // 超限需要清空广告
        if isADLimited {
            clean(.native)
            clean(.interstitial)
        }
        let loadAD = ads.filter {
            $0.position == position
        }.first
        switch position {
        case .interstitial:
            /// 有廣告
            if let ad = loadAD?.loadedArray.first as? InterstitialADModel, !appenterbackground, !isADLimited {
                ad.impressionHandler = { [weak self, loadAD] in
                    loadAD?.impressionDate = Date()
                    self?.add(.show)
                    self?.display(position)
                    self?.load(position)
                }
                ad.clickHandler = { [weak self] in
                    self?.add(.click)
                }
                ad.closeHandler = { [weak self] in
                    self?.disappear(position)
                    if self?.appenterbackground != true {
                        completion(nil)
                    }
                }
                if !appenterbackground {
                    ad.present(from: vc)
                }
            } else {
                completion(nil)
            }
            
        case .native:
            if let ad = loadAD?.loadedArray.first as? NativeADModel, !appenterbackground, !isADLimited {
                /// 预加载回来数据 当时已经有显示数据了
                if loadAD?.isDisplay == true {
                    return
                }
                ad.nativeAd?.unregisterAdView()
                ad.nativeAd?.delegate = ad
                ad.impressionHandler = {
                    loadAD?.impressionDate = Date()
                    self.add(.show)
                    self.display(position)
                    self.load(position)
                }
                ad.clickHandler = {
                    self.add(.click)
                }
                completion(ad)
            } else {
                /// 预加载回来数据 当时已经有显示数据了 并且没超过限制
                if loadAD?.isDisplay == true, !isADLimited {
                    return
                }
                completion(nil)
            }
        }
    }
    
    /// 清除缓存 针对loadedArray数组
    fileprivate func clean(_ position: ADPosition) {
        let loadAD = ads.filter{
            $0.position == position
        }.first
        loadAD?.clean()
        
        if position == .native {
            NotificationCenter.default.post(name: .nativeUpdate, object: nil)
        }
    }
    
    /// 关闭正在显示的广告（原生，插屏）针对displayArray
    public func disappear(_ position: ADPosition) {
        
        // 处理 切入后台时候 正好 show 差屏
        let display = ads.filter{
            $0.position == position
        }.first?.displayArray
        
        if display?.count == 0, position == .interstitial {
            ads.filter{
                $0.position == position
            }.first?.clean()
        }
        
        ads.filter{
            $0.position == position
        }.first?.closeDisplay()
        
        if position == .native {
            NotificationCenter.default.post(name: .nativeUpdate, object: nil)
        }
    }
    
    /// 展示
    fileprivate func display(_ position: ADPosition) {
        ads.filter {
            $0.position == position
        }.first?.display()
    }
}

struct ADConfig: Codable {
    var showTimes: Int?
    var clickTimes: Int?
    var ads: [ADModels?]?
    
    func arrayWith(_ postion: ADPosition) -> [ADModel] {
        guard let ads = ads else {
            return []
        }
        
        guard let models = ads.filter({$0?.key == postion.rawValue}).first as? ADModels, let array = models.value   else {
            return []
        }
        
        return array.sorted(by: {$0.theAdPriority > $1.theAdPriority})
    }
    struct ADModels: Codable {
        var key: String
        var value: [ADModel]?
    }
}

class ADBaseModel: NSObject, Identifiable {
    let id = UUID().uuidString
    /// 廣告加載完成時間
    var loadedDate: Date?
    
    /// 點擊回調
    var clickHandler: (() -> Void)?
    /// 展示回調
    var impressionHandler: (() -> Void)?
    /// 加載完成回調
    var loadedHandler: ((_ result: Bool, _ error: String) -> Void)?
    
    /// 當前廣告model
    var model: ADModel?
    /// 廣告位置
    var position: ADPosition = .interstitial
    
    init(model: ADModel?) {
        super.init()
        self.model = model
    }
}

extension ADBaseModel {
    @objc public func loadAd( completion: @escaping ((_ result: Bool, _ error: String) -> Void)) {
        
    }
    
    @objc public func present(from vc: UIViewController? = nil) {
        
    }
}

struct ADModel: Codable {
    var theAdPriority: Int
    var theAdID: String
}

struct ADLimit: Codable {
    var showTimes: Int
    var clickTimes: Int
    var date: Date
    
    enum Status {
        case show, click
    }
}

enum ADPosition: String, CaseIterable {
    case native, interstitial
}

class ADLoadModel: NSObject {
    /// 當前廣告位置類型
    var position: ADPosition = .interstitial
    /// 當前正在加載第幾個 ADModel
    var preloadIndex: Int = 0
    /// 是否正在加載中
    var isPreloadingAd = false
    /// 正在加載術組
    var loadingArray: [ADBaseModel] = []
    /// 加載完成
    var loadedArray: [ADBaseModel] = []
    /// 展示
    var displayArray: [ADBaseModel] = []
    
    var isLoaded: Bool = false
    
    var isDisplay: Bool {
        return displayArray.count > 0
    }
    
    /// 该广告位显示广告時間 每次显示更新时间
    var impressionDate = Date(timeIntervalSinceNow: -100)
    
    /// 显示的时间间隔小于 11.2秒
    var isNeedShow: Bool {
        if Date().timeIntervalSince1970 - impressionDate.timeIntervalSince1970 < 10 {
            NSLog("[AD] (\(position)) 10s 刷新间隔不代表展示，有可能是请求返回")
            return false
        }
        return true
    }
        
    init(position: ADPosition) {
        super.init()
        self.position = position
    }
}

extension ADLoadModel {
    func beginAddWaterFall(callback: ((_ isSuccess: Bool) -> Void)? = nil) {
        isLoaded = false
        if isPreloadingAd == false, loadedArray.count == 0 {
            NSLog("[AD] (\(position.rawValue) start to prepareLoad.--------------------")
            if let array: [ADModel] = GADUtil.share.adConfig?.arrayWith(position), array.count > 0 {
                preloadIndex = 0
                NSLog("[AD] (\(position.rawValue)) start to load array = \(array.count)")
                prepareLoadAd(array: array) { [weak self] isSuccess in
                    self?.isLoaded = true
                    callback?(isSuccess)
                }
            } else {
                isPreloadingAd = false
                NSLog("[AD] (\(position.rawValue)) no configer.")
            }
        } else if loadedArray.count > 0 {
            isLoaded = true
            callback?(true)
            NSLog("[AD] (\(position.rawValue)) loaded ad.")
        } else if isPreloadingAd == true {
            NSLog("[AD] (\(position.rawValue)) loading ad.")
        }
    }
    
    func prepareLoadAd(array: [ADModel], callback: ((_ isSuccess: Bool) -> Void)?) {
        if array.count == 0 || preloadIndex >= array.count {
            NSLog("[AD] (\(position.rawValue)) prepare Load Ad Failed, no more avaliable config.")
            isPreloadingAd = false
            return
        }
        NSLog("[AD] (\(position)) prepareLoaded.")
        if GADUtil.share.isADLimited {
            NSLog("[AD] (\(position.rawValue)) 用戶超限制。")
            callback?(false)
            return
        }
        if loadedArray.count > 0 {
            NSLog("[AD] (\(position.rawValue)) 已經加載完成。")
            callback?(false)
            return
        }
        if isPreloadingAd, preloadIndex == 0 {
            NSLog("[AD] (\(position.rawValue)) 正在加載中.")
            callback?(false)
            return
        }
        
        isPreloadingAd = true
        var ad: ADBaseModel? = nil
        if position == .native {
            ad = NativeADModel(model: array[preloadIndex])
        } else if position == .interstitial {
            ad = InterstitialADModel(model: array[preloadIndex])
        }
        ad?.position = position
        ad?.loadAd { [weak ad] result, error in
            guard let ad = ad else { return }
            /// 刪除loading 中的ad
            self.loadingArray = self.loadingArray.filter({ loadingAd in
                return ad.id != loadingAd.id
            })
            
            /// 成功
            if result {
                self.isPreloadingAd = false
                self.loadedArray.append(ad)
                callback?(true)
                return
            }
            
            if self.loadingArray.count == 0 {
                let next = self.preloadIndex + 1
                if next < array.count {
                    NSLog("[AD] (\(self.position.rawValue)) Load Ad Failed: try reload at index: \(next).")
                    self.preloadIndex = next
                    self.prepareLoadAd(array: array, callback: callback)
                } else {
                    NSLog("[AD] (\(self.position.rawValue)) prepare Load Ad Failed: no more avaliable config.")
                    self.isPreloadingAd = false
                    callback?(false)
                }
            }
            
        }
        if let ad = ad {
            loadingArray.append(ad)
        }
    }
    
    fileprivate func display() {
        self.displayArray = self.loadedArray
        self.loadedArray = []
    }
    
    fileprivate func closeDisplay() {
        self.displayArray = []
    }
    
    fileprivate func clean() {
        self.displayArray = []
        self.loadedArray = []
        self.loadingArray = []
    }
}

extension Date {
    var isExpired: Bool {
        Date().timeIntervalSince1970 - self.timeIntervalSince1970 > 3000
    }
    
    var isToday: Bool {
        let diff = Calendar.current.dateComponents([.day], from: self, to: Date())
        if diff.day == 0 {
            return true
        } else {
            return false
        }
    }
}


class InterstitialADModel: ADBaseModel {
    /// 關閉回調
    var closeHandler: (() -> Void)?
    var autoCloseHandler: (()->Void)?
    /// 異常回調 點擊了兩次
    var clickTwiceHandler: (() -> Void)?
    
    /// 是否點擊過，用於拉黑用戶
    var isClicked: Bool = false
    
    /// 插屏廣告
    var interstitialAd: GADInterstitialAd?
    
    deinit {
        NSLog("[Memory] (\(position.rawValue)) \(self) 💧💧💧.")
    }
}

extension InterstitialADModel {
    public override func loadAd(completion: ((_ result: Bool, _ error: String) -> Void)?) {
        loadedHandler = completion
        loadedDate = nil
        GADInterstitialAd.load(withAdUnitID: model?.theAdID ?? "", request: GADRequest()) { [weak self] ad, error in
            guard let self = self else { return }
            if let error = error {
                NSLog("[AD] (\(self.position.rawValue)) load ad FAILED for id \(self.model?.theAdID ?? "invalid id")")
                self.loadedHandler?(false, error.localizedDescription)
                return
            }
            NSLog("[AD] (\(self.position.rawValue)) load ad SUCCESSFUL for id \(self.model?.theAdID ?? "invalid id") ✅✅✅✅")
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.loadedDate = Date()
            self.loadedHandler?(true, "")
        }
    }
    
    override func present(from vc: UIViewController? = nil) {
        if let vc = vc {
            interstitialAd?.present(fromRootViewController: vc)
        } else if let v = UIApplication.shared.keyWindow?.rootViewController {
            interstitialAd?.present(fromRootViewController: v)
            return
        }
    }
    
}

extension InterstitialADModel : GADFullScreenContentDelegate {
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        loadedDate = Date()
        impressionHandler?()
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        NSLog("[AD] (\(self.position.rawValue)) didFailToPresentFullScreenContentWithError ad FAILED for id \(self.model?.theAdID ?? "invalid id")")
        if  GADUtil.share.appenterbackground == true {
            closeHandler?()
        }
    }
    
    func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        closeHandler?()
    }
    
    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        clickHandler?()
    }
}

class NativeADModel: ADBaseModel {
    /// 廣告加載器
    var loader: GADAdLoader?
    /// 原生廣告
    var nativeAd: GADNativeAd?
    
    deinit {
        NSLog("[Memory] (\(position.rawValue)) \(self) 💧💧💧.")
    }
}

extension NativeADModel {
    public override func loadAd(completion: ((_ result: Bool, _ error: String) -> Void)?) {
        loadedDate = nil
        loadedHandler = completion
        loader = GADAdLoader(adUnitID: model?.theAdID ?? "", rootViewController: nil, adTypes: [.native], options: nil)
        loader?.delegate = self
        loader?.load(GADRequest())
    }
    
    public func unregisterAdView() {
        nativeAd?.unregisterAdView()
    }
}

extension NativeADModel: GADAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        NSLog("[AD] (\(position.rawValue)) load ad FAILED for id \(model?.theAdID ?? "invalid id")")
        loadedHandler?(false, error.localizedDescription)
    }
}

extension NativeADModel: GADNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        NSLog("[AD] (\(position.rawValue)) load ad SUCCESSFUL for id \(model?.theAdID ?? "invalid id") ✅✅✅✅")
        self.nativeAd = nativeAd
        loadedDate = Date()
        loadedHandler?(true, "")
    }
}

extension NativeADModel: GADNativeAdDelegate {
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        clickHandler?()
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        impressionHandler?()
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
    }
}

extension UserDefaults {
    func setModel<T: Encodable> (_ object: T?, forKey key: String) {
        let encoder =  JSONEncoder()
        guard let object = object else {
            self.removeObject(forKey: key)
            return
        }
        guard let encoded = try? encoder.encode(object) else {
            return
        }
        
        self.setValue(encoded, forKey: key)
    }
    
    func model<T: Decodable> (_ type: T.Type, forKey key: String) -> T? {
        guard let data = self.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let object = try? decoder.decode(type, from: data) else {
            print("Could'n find key")
            return nil
        }
        
        return object
    }
}

extension Notification.Name {
    static let nativeUpdate = Notification.Name(rawValue: "homeNativeUpdate")
}
