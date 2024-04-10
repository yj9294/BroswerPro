//
//  PacketTunnelProvider.swift
//  Proxy
//
//  Created by Super on 2024/4/8.
//

import NetworkExtension
import ShadowSocks_libev_iOS
import PacketProcessor_iOS

enum LGConnectError: Error {
    case SSLocalStartError
    case tun2SockesStartError
}

class PacketTunnelProvider: NEPacketTunnelProvider {

    var shadowsocks: Shadowsocks? = nil
    var startCompletionHandler: ((Error?) -> Void)? = nil
    
    var connectedAt: TimeInterval = 0
    var connected: Bool = false {
        didSet {
            if connected {
                connectedAt = Date().timeIntervalSince1970
            }
        }
    }
    var transport: NSDictionary?

    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
        self.startCompletionHandler = completionHandler
        if let optionDic = options {
            var newDic: [String: String] = [:]
            optionDic.forEach { k,v in
                if let value = v as? String {
                    newDic[k] = value
                }
            }
            self.shadowsocks = Shadowsocks.init(newDic)
            self.startConnectToShadowsocks()
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        shadowsocks?.stop()
        TunnelInterface.stop()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            completionHandler()
            exit(0)
        }
    }
}

extension PacketTunnelProvider {
    func startConnectToShadowsocks() {
        shadowsocks?.start({ errorCode in
             if errorCode == .noError {
                 self.startTunnelInterface()
             } else {
                 self.shadowsocks?.stop(nil)
                 self.startCompletionHandler?(LGConnectError.SSLocalStartError)
             }
         })
    }
    
    func startTunnelInterface() {
        setTunnelSettings { (setttingError) in
            if TunnelInterface.setup(with: self.packetFlow) != nil {
                self.shadowsocks?.stop(nil)
                self.startCompletionHandler?(LGConnectError.tun2SockesStartError)
                return
            } else {
                self.connected = true
            }
            
//            TunnelInterface.setIsUdpForwardingEnabled(true)
            TunnelInterface.startTun2Socks(kShadowsocksLocalPort)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                TunnelInterface.processPackets()
                // sendHeartBeat()
                self.startCompletionHandler?(nil)
            }
        }
    }
    
    func setTunnelSettings(completion: ((Error?) -> Void)?) {
        
        let excludes = [NEIPv4Route]()
        let ipv6Excludes = [NEIPv6Route]()
        
        let ipv4 = NEIPv4Settings(addresses: ["192.168.20.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [.default()]
        ipv4.excludedRoutes = excludes
        
        let ipv6 = NEIPv6Settings(addresses: ["fd66:f83a:c650::1"], networkPrefixLengths: [120])
        ipv6.includedRoutes = [.default()]
        ipv6.excludedRoutes = ipv6Excludes
        
        let dns = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1"])
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "192.168.20.1")
        settings.ipv4Settings = ipv4
        settings.ipv6Settings = ipv6
        settings.dnsSettings = dns
        
        setTunnelNetworkSettings(settings) { error in
            completion?(error)
        }
    }
}
