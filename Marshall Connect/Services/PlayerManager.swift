//
//  PlayerManager.swift
//  Marshall Connect
//
//  Created by Vahagn Mkrtchyan on 12/10/18.
//  Copyright © 2018 Vahagn Mkrtchyan. All rights reserved.
//

import Cocoa

enum PlayerManagerState {
    case Idle
    case Connecting
    case Connected
    case Takeover
}
class PlayerManager : NSObject {
    // MARK: -
    private static let sharedPlayerManager: PlayerManager = PlayerManager()
    private var device : DeviceManager?
    private var listener: ((PlayerManagerState) -> Void)?
    public private (set) var state: PlayerManagerState = .Idle

    private override init() {
        super.init()
        self.discoverAndConnec()
    }

    static func shared() -> PlayerManager {
        return sharedPlayerManager
    }
    
    // MARK: -
    func devices() -> [DeviceManager] {
        return DiscoveryManager.shared().devices
    }
    
    func currentDevice() -> DeviceManager? {
        return device
    }
    
    func hasActiveDevice() -> Bool {
        return device != nil
    }
    
    // MARK: - Setters
    public var volume : Float {
        get {
            return device?.volume ?? 0
        }
        set (newVolume) {
            device?.volume = newVolume
        }
    }
    
    public var bass : Float {
        get {
            return device?.bass ?? 0
        }
        set (newBass) {
            device?.bass = newBass
        }
    }
    
    public var treble : Float {
        get {
            return device?.treble ?? 0
        }
        set (newTreble) {
            device?.treble = newTreble
        }
    }
    
    // MARK: - Getters
    public var song: Song? {
        return device?.song
    }
    
    public var position: Int {
        return device?.position ?? 0
    }
    
    public var status: PlayerStatus {
        return device?.status ?? .Paused
    }
    
    public var muteStatus: Bool {
        return device?.muteStatus ?? false
    }
    
    // MARK: - Actions
    func selectDevice(device: DeviceManager, callback: @escaping (Bool) -> Void) {
        guard self.state == .Idle || self.state == .Takeover else {
            return callback(false)
        }
        self.state = .Connecting
        device.connect { (connected) in
            if (connected) {
                self.state = .Connected
                self.device = device
                self.listener?(self.state)
                self.device!.changeListener = {(disconnected: Bool, takeover: Bool) in
                    if (disconnected) {
                        // Device disconnected
                        self.state = .Idle
                        self.device = nil
                    }
                    
                    if (takeover) {
                        // User Takeover
                        self.state = .Takeover
                    }
                    
                    guard let listener = self.listener else {
                        return;
                    }
                    listener(self.state)
                }
                UserDefaults.standard.set(device.UDN, forKey: "lastConnectedDeviceUDN")
            }
            callback(connected)
        }
    }
    
    func reconnect(callback: @escaping (Bool) -> Void) {
        guard let device = self.device, self.state == .Takeover else {
            return callback(false)
        }
        
        self.selectDevice(device: device) { (connected) in
            return callback(connected)
        }
    }
    
    func disconnect() {
        device?.changeListener = nil
        device?.disconnect()
        device = nil
        state = .Idle
        guard let listener = listener else {
            return;
        }
        listener(self.state)
    }
    
    func setListener(_ del: @escaping (PlayerManagerState) -> Void) {
        self.listener = del;
    }
    
    func onPositionUpdate(_ callback: @escaping (Int) -> Void) {
        device?.onPositionUpdate(callback)
    }

    func playPause() {
        device?.pause()
    }
    
    func mute() {
        device?.mute()
    }
    
    func next() {
        device?.forward()
    }
    
    func prev() {
        device?.rewind()
    }
    
    func setPosition(_ position: Int) {
        device?.position = position
    }
    
    // MARK: - Private
    private func discoverAndConnec() {
        DiscoveryManager.shared().setDelegate { (device) in
            guard let device = device else {
                // Device list changed
                return
            }

            if let udn =  UserDefaults.standard.value(forKey: "lastConnectedDeviceUDN") as? String, udn == device.UDN {
                self.device = device
                self.selectDevice(device: device, callback: { (connected) in
                    print("Connected")
                })
            }
        }
    }
}
