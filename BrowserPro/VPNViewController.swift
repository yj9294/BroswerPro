//
//  VPNViewController.swift
//  BrowserPro
//
//  Created by Super on 2024/4/8.
//

import TBAUtil
import UIKit
import GADUtil

class VPNViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var flyView: UIImageView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    
    @IBOutlet weak var adView: GADNativeView!
    var willAppear = false
    
    lazy var connectViewLayer: CALayer = {
       let layer = CALayer()
        layer.cornerRadius = 27
        layer.backgroundColor = UIColor(named: "#39EBFF")?.cgColor
        return layer
    }()
    
    lazy var progressView: UICircleProgressView = {
        let view = UICircleProgressView(frame: .zero)
        return view
    }()
    
    var isConnectManual = false
    var isDisconnectManual = false
    var isConnectAuto = false
    var connectDate = Date()
    
    var timer: Timer? = nil
    var isPresentInterestitial = false
    var duration = 4.0
    var isPresentBackAD = false
    var progress: Double = 0.0 {
        didSet {
            progressView.setProgress(Int(progress * 1000))
            if progress == 0.0 || progress >= 1.0 {
                if  state == .connected {
                    progressView.isHidden = false
                    statusLabel.text = "Connected"
                } else {
                    progressView.isHidden = true
                    statusLabel.text = "Tap to Connect"
                }
            } else {
                progressView.isHidden = false
                if state == .disconnecting {
                    statusLabel.text = "Disconnecting...\(Int(progress * 100))%"
                } else {
                    statusLabel.text = "Connecting...\(Int(progress * 100))%"
                }
            }
        }
    }
    
    var state: VPNUtil.VPNState = .disconnected {
        didSet {
            view.isUserInteractionEnabled = true
            switch state {
            case .connecting:
                startAnimation()
                flyView.image = UIImage(named: "vpn_fly")
                view.isUserInteractionEnabled = false
            case .connected:
                stopAnimation()
                progress = 1.0
                flyView.image = UIImage(named: "vpn_fly_connected")
                if isConnectManual {
                    // 进入结果页面
                    connectDate = Date()
                    showConnectAD(true) {
                        self.toResult(.connected)
                    }
                }
                EventRequest.eventRequest(.vpnConnectSuccess, value: ["rot": AppUtil.shared.getVPNConnectCountry.ip])
            case .disconnecting:
                startAnimation()
                flyView.image = UIImage(named: "vpn_fly_connected")
                view.isUserInteractionEnabled = false
            case .error:
                progress = 0.0
                stopAnimation()
                flyView.image = UIImage(named: "vpn_fly")
                AppUtil.alert("Try it agin.")
                EventRequest.eventRequest(.vpnConnectError)
            case .disconnected:
                progress = 1.0
                stopAnimation()
                flyView.image = UIImage(named: "vpn_fly")
                if isDisconnectManual {
                    // 进入结果页面
                    EventRequest.eventRequest(.vpnDisconnectManual, value: ["duration": "\(abs(connectDate.timeIntervalSinceNow))"])
                    showConnectAD(false) {
                        self.toResult(.disconnected)
                    }
                }
                if isConnectAuto {
                    // 自动链接)
                }
            case .idle:
                flyView.image = UIImage(named: "vpn_fly")
                progress = 0.0
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        statusView.layer.insertSublayer(connectViewLayer, below: statusLabel.layer)
        contentView.insertSubview(progressView, aboveSubview: flyView)
        addVPNObserver()
        addADNotification()
    }
    
    deinit {
        VPNUtil.shared.removeStateObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var p = progress
        if progress == 0.0 {
            p = 1.0
        }
        connectViewLayer.frame = CGRect(x: 0, y: 0, width: self.statusView.bounds.width * p, height: self.statusView.bounds.height)
        progressView.center = flyView.center
        progressView.bounds = CGRect(x: 0, y: 0, width: flyView.bounds.width + 6, height: flyView.bounds.width + 6)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        willAppear = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(back))
        countryLabel.text = AppUtil.shared.getVPNCountry.title
        state = VPNUtil.shared.vpnState
        GADUtil.share.disappear(GADMobPosition.vpnHome)
        if isPresentBackAD {
            return
        }
        GADUtil.share.load(GADMobPosition.vpnHome, p: GADMobScene.vpnhome)
        if TBACacheUtil.shared.getUserGo() {
            GADUtil.share.load(GADMobPosition.vpnBack, p: GADMobScene.vpnBack)
        }
        EventRequest.eventRequest(.vpnHome)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        willAppear = false
        GADUtil.share.disappear(GADMobPosition.vpnHome)
    }
    
    @objc func back() {
        if state == .connecting || state == .disconnecting {
            return
        }
        isPresentBackAD = true
        GADUtil.share.show(GADMobPosition.vpnBack,from: self) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.dismiss(animated: true)
            }
        }
        EventRequest.eventRequest(.vpnBack)
    }
    
    func startAnimation() {
        if self.timer != nil {
            stopAnimation()
        }
        self.progress = 0.01
        self.duration = 4.0
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true, block: { timer in
            if !AppUtil.shared.isVPNPermission {
                let progress = 0.005 / self.duration + self.progress
                if progress >= 1.0 {
                    timer.invalidate()
                    self.progress = 1.0
                    if self.state == .connecting {
                        self.state = .error
                    } else if self.state == .disconnecting {
                        self.state = .error
                    }
                } else {
                    self.progress = progress
                }
            }
        })
    }
    
    func stopAnimation() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func showConnectAD(_ isConnect: Bool, completion: (()->Void)? = nil) {
        if isConnect {
            GADUtil.share.load(GADMobPosition.vpnConnect, p: GADMobScene.vpnConnect)
            GADUtil.share.show(GADMobPosition.vpnConnect, p: GADMobScene.vpnConnect, from: self) { _ in
                completion?()
            }
        } else {
            GADUtil.share.load(GADMobPosition.vpnConnect, p: GADMobScene.vpnDisconnect)
            GADUtil.share.show(GADMobPosition.vpnConnect, p: GADMobScene.vpnDisconnect, from: self) { _ in
                completion?()
            }
        }
    }
    
    func toResult(_ status: VPNResultViewController.State) {
        self.isConnectManual = false
        self.isDisconnectManual = false
        let sb = UIStoryboard(name: "Main", bundle: .main)
        if let vc = sb.instantiateViewController(withIdentifier: "VPNResultViewController") as? VPNResultViewController {
            vc.state = status
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func addADNotification() {
        NotificationCenter.default.addObserver(forName: .nativeUpdate, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else {return}
            if let ad = noti.object as? GADNativeModel, ad.position.rawValue == GADMobPosition.vpnHome.rawValue {
                if self.willAppear {
                    if AppUtil.shared.vpnHomeImpressionDate.timeIntervalSinceNow < -12 {
                        self.adView.nativeAd = ad.nativeAd
                        AppUtil.shared.vpnHomeImpressionDate = Date()
                    } else {
                        NSLog("[ad] 12s vpn home 原生广告刷新或数据填充间隔.")
                        self.adView.nativeAd = nil
                    }
                } else {
                    self.adView.nativeAd = nil
                }
            } else if noti.object == nil {
                self.adView.nativeAd = nil
            }
        }
    }
    
}

// MARK: VPN
extension VPNViewController {
    @IBAction func connectDisconnectAction() {
        if state == .connected {
            isDisconnectManual = true
            isConnectManual = false
            stopConnect()
            GADUtil.share.load(GADMobPosition.vpnResult, p: GADMobScene.vpnDisconnect)
            GADUtil.share.load(GADMobPosition.vpnConnect, p: GADMobScene.vpnConnect)
        } else {
            isConnectManual = true
            isDisconnectManual = false
            startConnect()
            GADUtil.share.load(GADMobPosition.vpnResult, p: GADMobScene.vpnResultConnect)
            GADUtil.share.load(GADMobPosition.vpnConnect, p: GADMobScene.vpnDisconnect)
        }
        if TBACacheUtil.shared.getUserGo() {
            GADUtil.share.load(GADMobPosition.vpnBack, p: GADMobScene.vpnBack)
        }
    }
    
    func stopConnect() {
        state = .disconnecting
        VPNUtil.shared.stopVPN()
    }
    
    func startConnect() {
        state = .connecting
        connect()
    }
    
    func connect() {
        if VPNUtil.shared.managerState == .idle || VPNUtil.shared.managerState == .error {
            AppUtil.shared.isVPNPermission = true
            EventRequest.eventRequest(.vpnPermission)
            VPNUtil.shared.create { err in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    AppUtil.shared.isVPNPermission = false
                }
                if let err = err {
                    NSLog("[CONNECT] err:\(err.localizedDescription)")
                    self.state = .disconnected
                    AppUtil.alert(err.localizedDescription)
                    return
                }
                EventRequest.eventRequest(.vpnPermission1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.pingServer()
                }
            }
        } else {
            pingServer()
        }
    }
    
    func pingServer() {
        state = .connecting
        if !ReachabilityUtil.shared.isConnected {
            state = .disconnected
            AppUtil.alert("Local network is not turned on.")
            return
        }
        EventRequest.eventRequest(.vpnConnect)
        if AppUtil.shared.getVPNCountry.isSmart {
            pingAllServers(serverList:AppUtil.shared.getVPNCountryList.allModels()) { serverList in
                guard let serverList = serverList, !serverList.isEmpty else {
                    self.state = .disconnected
                    AppUtil.alert("Try it agin.")
                    return
                }
                if let country = VPNCountryList.smartModel(with: serverList) {
                    AppUtil.shared.vpnConnectCountry = country
                    self.doConnect(country)
                } else {
                    self.state = .disconnected
                    AppUtil.alert("Try it agin.")
                }
            }
        } else {
            pingAllServers(serverList: [AppUtil.shared.getVPNConnectCountry]) { serverList in
                if let country = serverList?.first {
                    self.doConnect(country)
                }
            }
        }
    }
    
    func doConnect(_ country: VPNCountry) {
        if country.isSmart {
            self.state = .disconnected
            AppUtil.alert("Try it agin.")
            return
        }
        if AppUtil.shared.enterbackground {
            self.state = .disconnected
            return
        }
        let host = country.ip
        var port = ""
        var method = ""
        var password: String = ""
        if let config = country.config.first {
            port = "\(config.port)"
            method = config.method
            password = config.psw
        } else {
            NSLog("[connect] this ip no config.")
            return
        }

        let op = ["host": host,"port": port,"method": method,"password": password] as? [String : NSObject]
        VPNUtil.shared.connect(options: op)
        EventRequest.eventRequest(.vpnDidConnect, value: ["rot": country.ip])
    }
    
    
    func pingAllServers(serverList: [VPNCountry], completion: (([VPNCountry]?) -> Void)?) {
        var pingResult = [Int : [Double]]()
        if serverList.count == 0 {
            completion?(nil)
            return
        }
        var pingUtilDict = [Int : VPNPingUtil?]()


        let group = DispatchGroup()
        let queue = DispatchQueue.main
        for (index, server) in serverList.enumerated() {
            if server.ip.count == 0 {
                continue
            }
            group.enter()
            queue.async {
                pingUtilDict[index] = VPNPingUtil.startPing(hostName: server.ip, count: 3, pingCallback: { pingItem in
                    switch pingItem.status! {
                        case .start:
                            pingResult[index] = []
                            break
                        case .failToSendPacket:
                            group.leave()
                            break
                        case .receivePacket:
                            pingResult[index]?.append(pingItem.singleTime!)
                        case .receiveUnpectedPacket:
                            break
                        case .timeout:
                            pingResult[index]?.append(1000.0)
                            group.leave()
                        case .error:
                            group.leave()
                        case .finished:
                            pingUtilDict[index] = nil
                            group.leave()
                    }
                })
            }
        }
        group.notify(queue: DispatchQueue.main) {
            var pingAvgResult = [Int : Double]()
            pingResult.forEach {
                if $0.value.count > 0 {
                    let sum = $0.value.reduce(0, +)
                    let avg = Double(sum) / Double($0.value.count)
                    pingAvgResult[$0.key] = avg
                }
            }

            if pingAvgResult.count == 0 {
                NSLog("[ERROR] ping error")
                completion?(nil)
                return
            }

            var serverList = serverList

            pingAvgResult.forEach {
                serverList[$0.key].delay = $0.value
            }

            serverList = serverList.filter {
                return ($0.delay ?? 0) > 0
            }

            serverList = serverList.sorted(by: { return ($0.delay ?? 0) < ($1.delay ?? 0) })

            serverList.forEach {
                NSLog("[IP] \($0.country)-\($0.city)-\($0.ip)-\(String(format: "%.2f", $0.delay ?? 0 ))ms")
            }

            completion?(serverList)
        }
    }
}

extension VPNViewController: VPNStateChangedObserver {
    func onStateChangedTo(state: VPNUtil.VPNState) {
        self.state = state
    }
    
    func addVPNObserver() {
        VPNUtil.shared.addStateObserver(self)
    }
}
