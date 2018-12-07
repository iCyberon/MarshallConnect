//
//  DiscoveryService.swift
//  Marshall Connect
//
//  Created by Vahagn Mkrtchyan on 12/10/18.
//  Copyright © 2018 Vahagn Mkrtchyan. All rights reserved.
//

import Cocoa

class DiscoveryManager : NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    // MARK: - Properties
    private static var sharedDiscoveryManager: DiscoveryManager = {
        let discoveryManager = DiscoveryManager()
        discoveryManager.startDiscovery()
        return discoveryManager
    }()

    private var browser = NetServiceBrowser()
    private var services = [NetService]()
    private var delegates = [(DeviceManager?) -> Void]()
    
    // Public
    public private(set) var status: DiscoveryStatus = DiscoveryStatus(running: false, error: false)
    public private(set) var devices : [DeviceManager] = []
    
    // MARK: -
    private override init() {}
    
    // MARK: - Accessors
    static func shared() -> DiscoveryManager {
        return sharedDiscoveryManager
    }
    
    // MARK: - Actions
    private func startDiscovery() {
        self.browser.stop()
        self.browser.delegate = self
        self.browser.searchForServices(ofType: "_zound._tcp", inDomain: "")
    }
    
    public func setDelegate(_ delegate: @escaping (DeviceManager?) -> Void) {
        self.delegates.append(delegate)
    }
    
    // MARK: - Net Service Broswer Delegate
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        self.status.running = true
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        self.status.running = false
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        self.services.append(service)
        service.delegate = self
        service.resolve(withTimeout: 5)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        self.services.removeAll(where: {$0 == service} )
        self.devices.removeAll(where: {$0.service == service} )
        self.delegates.forEach({ (delegate) in
            delegate(nil)
        })
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        status.running = false
        status.error = true
    }

    // MARK: - Net Service Delegate
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let serviceIp = resolveIPv4(addresses: sender.addresses!) else {
            return
        }
        
        let deviceManager = DeviceManager(address: serviceIp, service: sender)
        deviceManager.isValidDevice(callback: { (valid) in
            if (valid) {
                self.devices.append(deviceManager)
                self.delegates.forEach({ (delegate) in
                    delegate(deviceManager)
                })
            }
        })
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print(errorDict)
    }
    
    // MARK: Helpers
    private func resolveIPv4(addresses: [Data]) -> String? {
        var result: String?
        
        for addr in addresses {
            let data = addr as NSData
            var storage = sockaddr_storage()
            data.getBytes(&storage, length: MemoryLayout<sockaddr_storage>.size)
            
            if Int32(storage.ss_family) == AF_INET {
                let addr4 = withUnsafePointer(to: &storage) {
                    $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                        $0.pointee
                    }
                }
                
                if let ip = String(cString: inet_ntoa(addr4.sin_addr), encoding: .ascii) {
                    result = ip
                    break
                }
            }
        }
        
        return result
    }
}

struct DiscoveryStatus {
    var running: Bool
    var error: Bool
}
