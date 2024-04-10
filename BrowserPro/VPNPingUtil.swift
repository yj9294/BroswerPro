//
//  VPNPingUtil.swift
//  PopularBrowser
//
//  Created by hero on 1/3/2024.
//

import Foundation
import UIKit

/// ping status
enum VPNPingStatus {
    case start
    case failToSendPacket
    case receivePacket
    case receiveUnpectedPacket
    case timeout
    case error
    case finished
}

class VPNPingItem: NSObject {
    /// host name
    var hostName: String?
    /// millisecond
    var singleTime: Double?
    /// ping status
    var status: VPNPingStatus?
}

class VPNPingUtil: NSObject {
    var hostName: String?
    var pinger: SimplePing?
    var sendTimer: Timer?
    var startDate: Date?
    var runloop: RunLoop?
    var pingCallback: ((_ pingItem: VPNPingItem) -> Void)?
    var count: Int = 0
    
    init(hostName: String, count: Int, pingCallback: @escaping ((_ pingItem: VPNPingItem) -> Void)) {
        super.init()
        self.hostName = hostName
        self.count = count
        self.pingCallback = pingCallback
        let pinger = SimplePing(hostName: hostName)
        self.pinger = pinger
        pinger.addressStyle = .any
        pinger.delegate = self
        pinger.start()
    }
    
    static func startPing(hostName: String, count: Int, pingCallback: @escaping ((_ pingItem: VPNPingItem) -> Void)) -> VPNPingUtil {
        let manager = VPNPingUtil(hostName: hostName, count: count, pingCallback: pingCallback)
        return manager
    }
    
    func stopPing() {
        NSLog("[IP] ping" + (hostName ?? "nil") + "stop")
        clean(status: .finished)
    }
    
    @objc func pingTimeout() {
        NSLog("[IP] ping" + (hostName ?? "nil") + "timeout")
        clean(status: .timeout)
    }
    
    func pingFail() {
        NSLog("[IP] ping" + (hostName ?? "nil") + "fail")
        clean(status: .error)
    }
    
    func clean(status: VPNPingStatus) {
        let item = VPNPingItem()
        item.hostName = hostName
        item.status = status
        pingCallback?(item)
        
        pinger?.stop()
        pinger = nil
        sendTimer?.invalidate()
        sendTimer = nil
        runloop?.cancelPerform(#selector(pingTimeout), target: self, argument: nil)
        runloop = nil
        hostName = nil
        startDate = nil
        pingCallback = nil
    }
    
    @objc func sendPing() {
        if count < 1 {
            stopPing()
            return
        }
        count -= 1
        startDate = Date()
        pinger?.send(with: nil)
        // timeout in two second
        runloop?.perform(#selector(pingTimeout), with: nil, afterDelay: 3.0)
    }
}

extension VPNPingUtil: SimplePingDelegate {
    func simplePing(_ pinger: SimplePing, didStartWithAddress address: Data) {
        NSLog("[IP] start ping \(hostName ?? "null")")
        sendPing()
        sendTimer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(sendPing), userInfo: nil, repeats: true)
        
        let pingItem = VPNPingItem()
        pingItem.hostName = hostName
        pingItem.status = .start
        pingCallback?(pingItem)
    }
    
    func simplePing(_ pinger: SimplePing, didFailWithError error: Error) {
        NSLog("[IP] \(hostName ?? "null") \(error.localizedDescription)")
//        pingFail()
    }
    
    func simplePing(_ pinger: SimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        runloop?.cancelPerform(#selector(pingTimeout), target: self, argument: nil)
        NSLog("[IP] \(hostName ?? "null") #\(sequenceNumber) send packet success")
    }
    
    func simplePing(_ pinger: SimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        runloop?.cancelPerform(#selector(pingTimeout), target: self, argument: nil)
        NSLog("[IP] \(hostName ?? "") send packet failed: \(error.localizedDescription)")
        clean(status: .failToSendPacket)
    }
    
    func simplePing(_ pinger: SimplePing, didReceivePingResponsePacket packet: Data, sequenceNumber: UInt16) {
        runloop?.cancelPerform(#selector(pingTimeout), target: self, argument: nil)
        let time = Date().timeIntervalSince(startDate ?? Date()) * 1000
        NSLog("[IP] \(hostName ?? "null") #\(sequenceNumber) received, size=\(packet.count), time=\(String(format: "%.2f", time)) ms")
        let pingItem = VPNPingItem()
        pingItem.hostName = hostName
        pingItem.status = .receivePacket
        pingItem.singleTime = time
        pingCallback?(pingItem)
    }
    
    func simplePing(_ pinger: SimplePing, didReceiveUnexpectedPacket packet: Data) {
        runloop?.cancelPerform(#selector(pingTimeout), target: self, argument: nil)
    }
}
