//
//  VPNUtil.swift
//  BrowserPro
//
//  Created by Super on 2024/4/8.
//

import UIKit
import NetworkExtension
import Foundation

public protocol VPNStateChangedObserver: NSObjectProtocol {
    func onStateChangedTo(state: VPNUtil.VPNState)
}

public enum VPNConnectState {
    case idle
    case preparing
    case testing
    case connecting
    case connected
    case disconnecting
    case disconnected
}

func VPNLog(_ message: String) {
    if VPNUtil.shared.isDebug {
        NSLog(message)
    }
}

public class VPNUtil: NSObject {

    public enum VPNState {
        case idle
        case connecting
        case connected
        case disconnecting
        case disconnected
        case error
    }

    enum NEVPNManagerState {
        case loading
        case idle
        case preparing
        case ready
        case error
    }
    
    public static let shared = VPNUtil()

    private var manager: NETunnelProviderManager? = nil {
        didSet {
            if manager != nil {
                updateVPNStatus()
            }
        }
    }

    private var statusOfVPNObserverAdded = false
    private var needConnectAfterLoaded = false
    private var connectedEver = true
    private var name: String = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? ""
    private var bundleID: String = Bundle.main.bundleIdentifier ?? ""
    /// 链接时长
    private var connectingTimer: Timer? = nil

    /// vpn状态监听的观察者
    private var stateObservers = [VPNStateChangedObserver]()

    /// 扩展返回的vpn状态
    public var vpnState: VPNState = .idle {
        didSet {
            if oldValue == vpnState {
                return
            }
        }
    }
    /// manager stage change
    var managerState: NEVPNManagerState = .loading {
        didSet {
            if oldValue == managerState {
                return
            }
        }
    }
    
    // 链接时间
    public var connectedAt: Date? {
        return manager?.connection.connectedDate
    }
    
    // 日志
    public var isDebug: Bool = true
    
    // 进入vpn权限
    public var vpnPermission: Bool = false 

    @objc private func updateVPNStatus(timeout: Bool = false) {
        guard let session = manager?.connection as? NETunnelProviderSession else  {
            VPNLog("[VPN] cannot got session but updateVPNStatus called!")
            return
        }


        if !connectedEver && session.status != .disconnected {
            VPNLog("[VPN] not connected yet, but status is \(session.status.rawValue)")
            return
        }
        
        let arr = ["invalid","disconnected","connecting","connected","reasserting","disconnecting"]
        VPNLog("[VPN] vpn status changed to: \(arr[session.status.rawValue])")

        switch session.status {
        case .connecting:
            vpnState = .connecting
        case .connected:
            vpnState = .connected
        case .disconnecting:
            vpnState = .disconnecting
        case .disconnected:
            vpnState = .disconnected
        case .invalid:
            vpnState = .error
        default:
            vpnState = .idle
        }
        if session.status != .connecting {
            VPNLog("[VPN] status changed: \(arr[session.status.rawValue]), clear timer.")
            connectingTimer?.invalidate()
            connectingTimer = nil
        }

        if timeout && session.status != .connected {
            vpnState = .error
        }
        
        self.makeSureRunInMainThread {
            self.stateObservers.forEach {
                $0.onStateChangedTo(state: self.vpnState)
            }
        }
    }
}

//MARK: - 链接相关的操作
extension VPNUtil {
    
    // 链接vpn操作
    public func connect(options: [String : NSObject]?) {

        guard let manager = manager else {
            VPNLog("[VPN] manager is nil, cannot connect")
            vpnState = .error
            return
        }

        // add timeout timer
        connectingTimer = Timer(timeInterval: 10.0, repeats: false) { [unowned self] timer in
            self.connectTimeout()
        }
        RunLoop.main.add(connectingTimer!, forMode: .default)
        
        if !manager.isEnabled {
            VPNLog("[VPN] manager is not enabled")
            needConnectAfterLoaded = true
            manager.loadFromPreferences { error in
                if let error = error {
                    VPNLog("[VPN] cannot enable mananger: \(error.localizedDescription)")
                    self.managerState = .error
                } else {
                    manager.isEnabled = true
                    manager.saveToPreferences { error in
                        if let error = error {
                            VPNLog("[VPN] cannot save manager into preferences: \(error.localizedDescription)")
                            self.managerState = .error
                        } else {
                            self.startVPNTunnel(options: options)
                        }
                    }
                }
            }
        } else {
            startVPNTunnel(options: options)
        }
    }
    

    // 关闭VPN操作
    public func stopVPN() {
        guard let connection = manager?.connection, connection.status != .disconnected else {
            self.makeSureRunInMainThread {
                self.stateObservers.forEach {
                    $0.onStateChangedTo(state: .disconnected)
                }
            }
            return
        }
        connection.stopVPNTunnel()
    }

    private func startVPNTunnel(options: [String : NSObject]?) {
        guard let manager = manager else {
            VPNLog("[VPN] manager is nil, cannot connect")
            return
        }
        do {
            try manager.connection.startVPNTunnel(options: options)
            connectedEver = true
            addVPNStatusDidChangeObserver()
        } catch {
            VPNLog("[VPN] Start VPN failed \(error.localizedDescription)")
        }
    }
    
}
//MARK: - 观察VPN和Manager状态的变化
extension VPNUtil {
    
    public func addStateObserver(_ observer: VPNStateChangedObserver) {
        self.makeSureRunInMainThread {
            if self.stateObservers.contains(where: {$0 === observer}) {
                VPNLog("[VPN] already added this observer")
                return
            }
            self.stateObservers.append(observer)
        }
    }

    public func removeStateObserver(_ observer: VPNStateChangedObserver) {
        self.makeSureRunInMainThread {
            self.stateObservers.removeAll(where: { $0 === observer })
        }
    }
    
    private func addVPNStatusDidChangeObserver() {
        if statusOfVPNObserverAdded {return}
        guard manager != nil else {return}
        statusOfVPNObserverAdded = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateVPNStatus), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }

    private func removeVPNStatusDidChangeObserver() {
        if statusOfVPNObserverAdded {
            statusOfVPNObserverAdded = false
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
        }
    }
    
    private func connectTimeout() {
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
//            if self.manager?.connection.status != NEVPNStatus.connected {
//                VPNLog("[VPN] connect timeout,stopVPNTunnel.")
//                self.manager?.connection.stopVPNTunnel()
//            }
//            self.updateVPNStatus(timeout: true)
//        }
    }
}
//MARK: - VPN配置相关的方法
extension VPNUtil {
    public func create(completionHandler: ((Error?) -> Void)? = nil) {
        let manager = NETunnelProviderManager()
        manager.isEnabled = true
        let p = NETunnelProviderProtocol()
        p.serverAddress = name
        p.providerBundleIdentifier = bundleID + ".Proxy"
        p.providerConfiguration = ["manager_version": "manager_v1"]
        manager.protocolConfiguration = p
        connectedEver = false
        manager.loadFromPreferences { (error) in
            if let error = error {
                VPNLog("[VPN] create failed: \(error.localizedDescription)")
                self.managerState = .error
                completionHandler?(error)
                return
            }
            manager.saveToPreferences(completionHandler: { (error: Error?) in
                if let error = error {
                    VPNLog("[VPN] code: \(NEVPNError.Code.configurationReadWriteFailed.rawValue)")
                    VPNLog("[VPN] code: \(NEVPNError.Code.configurationStale.rawValue)")
                    VPNLog("[VPN] create failed: \(error.localizedDescription)")
                    self.managerState = .error
                    completionHandler?(error)
                } else {
                    completionHandler?(nil)
                    self.load()
                }
            })
        }
    }

    public func load() {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                VPNLog("[VPN] cannot load manangers from preferences: \(error.localizedDescription)")
                self.managerState = .error
                self.connectedEver = false
                return
            }

            guard let managers = managers, let manager = managers.first else {
                VPNLog("[VPN] have no manager")
                self.managerState = .idle
                self.connectedEver = false
                return
            }

            manager.loadFromPreferences { error in
                if let error = error {
                    VPNLog("[VPN] cannot load manager from preferences: \(error.localizedDescription))")
                    self.managerState = .error
                }

                VPNLog("[VPN] manager loaded from preferences")
                self.manager = manager
                self.managerState = .ready
                self.removeVPNStatusDidChangeObserver()
                self.addVPNStatusDidChangeObserver()
            }
        }
    }

    public func prepareForLoading(completionHandler: @escaping (() -> Void)) {
        DispatchQueue.global().async {
            var times = 20
            while times > 0 {
                times -= 1
                if self.managerState != .loading {
                    self.makeSureRunInMainThread {
                        completionHandler()
                    }
                    return
                }

                Thread.sleep(forTimeInterval: 0.2)
            }
            self.makeSureRunInMainThread {
                completionHandler()
            }
        }
    }
}

extension VPNUtil {
    func makeSureRunInMainThread(job: @escaping () -> Void) {
        if Thread.current.isMainThread {
            job()
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                job()
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
}
