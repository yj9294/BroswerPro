//
//  Shadowsockets.swift
//  Proxy
//
//  Created by Super on 2024/4/8.
//

import Foundation
import Darwin
import ShadowSocks_libev_iOS

let kShadowsocksLocalPort = Int32(9999);
let kShadowsocksTimeoutSecs = INT_MAX;
let kShadowsocksTcpAndUdpMode = Int32(1);  // See https://github.com/shadowsocks/shadowsocks-libev/blob/4ea517/src/jconf.h#L44
let kShadowsocksLocalAddress = "127.0.0.1";

enum ErrorCode: Int {
    case noError = 0
    case undefinedError = 1
    case vpnPermissionNotGranted = 2
    case invalidServerCredentials = 3
    case udpRelayNotEnabled = 4
    case serverUnreachable = 5
    case vpnStartFailure = 6
    case illegalServerConfiguration = 7
    case shadowsocksStartFailure = 8
    case configureSystemProxyFailure = 9
    case noAdminPermissions = 10
    case unsupportedRoutingTable = 11
    case systemMisconfigured = 12

}

class Shadowsocks: NSObject {
    private var ssLocalThreadId: pthread_t? = nil
    private var config: [String: String] = [:]
    private var startCompletion: ((ErrorCode)->Void)? = nil
    private var stopCompletion: ((ErrorCode)->Void)? = nil
    public init(_ config: [String: String]) {
        super.init()
        self.config = config
    }
    
    public func start(_ completion: @escaping (ErrorCode)->Void) {
        if ssLocalThreadId != nil {
            NSLog("Shadowsocks already running")
            completion(.shadowsocksStartFailure);
            return
        }
        DispatchQueue.main.async {
            self.startCompletion = completion
            self.startShadowsocketsThread { pointer in
                // 在闭包中，你可以将接收到的指针转换为 Shadowsocks 类型，并返回它
                let unmanaged = Unmanaged<Shadowsocks>.fromOpaque(pointer)
                let shadowsocks = unmanaged.takeUnretainedValue()
                shadowsocks.setupShadowsockets{ socks_fd, udp_fd, p in
                    if socks_fd <= 0 || udp_fd <= 0 {
                      return;
                    }
                    if let p = p {
                        let unmanaged = Unmanaged<Shadowsocks>.fromOpaque(p)
                        let shadowsocks = unmanaged.takeUnretainedValue()
                        shadowsocks.startCompletion?(.noError);
                    }
                    return
                }
                return  Unmanaged.passUnretained(shadowsocks).toOpaque()
            }
        }
    }
    
    public func stop(_ completion: ((ErrorCode)->Void)? = nil) {
        if ssLocalThreadId == nil {
            return;
        }
        DispatchQueue.main.async {
            debugPrint("[ss] Stopping Shadowsocks")
            self.stopCompletion = completion
            if let ssLocalThreadId = self.ssLocalThreadId {
                pthread_kill(ssLocalThreadId, SIGUSR1)
                self.ssLocalThreadId = nil
            }
        }
    }
}

extension Shadowsocks {
    private func startShadowsocketsThread(_ completion: @escaping (@convention(c) (UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?)) {
        var attr = pthread_attr_t()
        var err = pthread_attr_init(&attr)
        if err != 0 {
            debugPrint("[ss] pthread_attr_init failed with error:\(err)")
            startCompletion?(.shadowsocksStartFailure)
            return
        }
        err = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED)
        if err != 0 {
            debugPrint("[ss] pthread_attr_setdetachstate failed with error:\(err)")
            startCompletion?(.shadowsocksStartFailure)
            return
        }
        err = pthread_create(&ssLocalThreadId, &attr, completion, Unmanaged.passUnretained(self).toOpaque())
        if err != 0 {
            debugPrint("[ss] pthread_create failed with error \(err)");
            startCompletion?(.shadowsocksStartFailure);
            return
        }
        err = pthread_attr_destroy(&attr);
        if err != 0 {
            debugPrint("[ss] pthread_attr_destroy failed with error \(err)");
            startCompletion?(.shadowsocksStartFailure);
            return;
        }
    }
    
    private func setupShadowsockets(completion: @escaping (@convention(c) (Int32, Int32, UnsafeMutableRawPointer?)->Void)) {
        if config.isEmpty {
            startCompletion?(.illegalServerConfiguration)
            debugPrint("[ss] Failed to start ss-local, missing configuration.")
            return
        }
        if let port = Int32(config["port"] ?? "0"), let host = config["host"], let password = config["password"], let method = config["method"] {
            let chost = strdup(host)
            let cpsw = strdup(password)
            let cmethod = strdup(method)
            let clocal = strdup(kShadowsocksLocalAddress)
            let profile = profile_t(remote_host: chost, local_addr: clocal, method: cmethod, password: cpsw, remote_port: port, local_port: kShadowsocksLocalPort, timeout: kShadowsocksTimeoutSecs, acl: nil, log: nil, fast_open: 0, mode: kShadowsocksTcpAndUdpMode, mtu: 0, mptcp: 0, verbose: 0)
            let success = start_ss_local_server_with_callback(profile, completion, Unmanaged.passUnretained(self).toOpaque())
            if success < 0 {
                debugPrint("[ss] Failed to start ss-local")
                startCompletion?(.shadowsocksStartFailure)
                return
            }
            if stopCompletion != nil {
                stopCompletion?(.noError)
                stopCompletion = nil
            }
            free(chost)
            free(cpsw)
            free(cmethod)
            free(clocal)
        }
    }
}
