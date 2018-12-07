//
//  APIManager.swift
//  Marshall Connect
//
//  Created by Vahagn Mkrtchyan on 12/10/18.
//  Copyright © 2018 Vahagn Mkrtchyan. All rights reserved.
//

import Cocoa

class DeviceManager {
    public let service: NetService!
    private let ipAddress: String!
    private let API: APIManager!
    
    //
    private var timer: Timer?
    private var positionTimer: Timer?

    private var sessionToken: String?
    private var currentPosition: Int?
    private var currentVolume: Int?
    private var currentBass: Int?
    private var currentTreble: Int?
    
    // Resolved values
    private var device: Device?
    private var player: Player?
    private var system: System?
    
    // Delegates
    private var positionDelegates: [(Int)->Void] = []
    public var changeListener: ((Bool, Bool) -> Void)?
    
    init(address: String, service: NetService) {
        self.ipAddress = address
        self.service = service
        self.API = APIManager(ipAddress: self.ipAddress)
    }
    
    deinit {
        self.positionTimer?.invalidate()
        self.timer?.invalidate()
        self.positionDelegates.removeAll()
        self.changeListener = nil
    }
    
    // MARK: - Accessors
    public var UDN : String? {
        return device?.UDN
    }
    
    public var name : String {
        return device?.friendlyName ?? "(Unsupported)"
    }
    
    public var image : NSImage {
        return device?.image ?? NSImage(named: "hero_stanmore_cream")!
    }
    
    public var model : String {
        return device?.modelAndColor ?? "-"
    }
    
    // MARK: - State
    public var volume : Float {
        get {
            return (Float(currentVolume ?? 0) * 100.0 / 33.0)
        }
        set(level) {
            let deviceVolume = lroundf(level * 33.0 / 100.0)
            if (deviceVolume != currentVolume) {
                API.setVolume(deviceVolume)
                currentVolume = deviceVolume
            }
        }
    }
    
    public var bass : Float {
        get {
            return (Float(currentBass ?? 0) * 100.0 / 10.0)
        }
        set(level) {
            let deviceBass = lroundf(level * 10.0 / 100.0)
            if (deviceBass != currentBass) {
                API.setBass(deviceBass)
                currentBass = deviceBass
            }
        }
    }
    
    public var treble : Float {
        get {
            return (Float(currentTreble ?? 0) * 100.0 / 10.0)
        }
        set(level) {
            let deviceTreble = lroundf(level * 10.0 / 100.0)
            if (deviceTreble != currentTreble) {
                API.setTreble(deviceTreble)
                currentTreble = deviceTreble
            }
        }
    }
    
    public var position : Int {
        get {
            return currentPosition ?? 0
        }
        set(pos) {
            if (pos != currentPosition) {
                API.setPosition(pos)
                currentPosition = pos
            }
        }
    }
    
    public var status: PlayerStatus? {
        return player?.status
    }
    
    public var muteStatus: Bool? {
        return system?.mute
    }
    
    public var song: Song? {
        guard let player = player else {
            return nil
        }

        return player.song
    }
    
    private func syncDevicePlayerInfo(audioOnly: Bool) {
        self.currentVolume = self.system?.volume
        self.currentBass = self.system?.bass
        self.currentTreble = self.system?.treble
        if (!audioOnly) {
            self.currentPosition = self.player?.position
            
            self.timer?.invalidate()
            self.timer = Timer.init(timeInterval: 1, repeats: true, block: { (timer) in
                guard let position = self.currentPosition, let play = self.player, position < play.song.duration, play.status == .Playing else {
                    return
                }
                
                self.currentPosition = (position + 1000 > play.song.duration) ? play.song.duration : (position + 1000)
                self.positionDelegates.forEach({ (cb) in
                    cb(self.currentPosition ?? 0)
                })
            })
            
            RunLoop.main.add(self.timer!, forMode: .common)
        }
    }
    
    private func syncPosition() {
        self.positionTimer?.invalidate()
        self.positionTimer = Timer.init(timeInterval: 3, repeats: true, block: { (timer) in
            guard let play = self.player, play.status == .Playing || play.status == .Paused else {
                return
            }
            
            self.API.fetchPosition(callback: { (position: Int?) in
                guard let position = position else {return}
                self.currentPosition = position
            })
        })
        
        RunLoop.main.add(self.positionTimer!, forMode: .common)
    }
    
    // MARK: - Connection and Info
    func connect(callback: @escaping (Bool) -> Void) {
        API.connect(callback: {(error: Error?, sessionToken: String?) in
            if (error == nil && sessionToken != nil) {
                self.sessionToken = sessionToken
                let fetchGroup = DispatchGroup()

                fetchGroup.enter()
                self.API.fetchPlayState(callback: {(error: Error?, player: Player?) in
                    self.player = player
                    fetchGroup.leave()
                })
                
                fetchGroup.enter()
                self.API.fetchSystemState(callback: {(error: Error?, system: System?) in
                    self.system = system
                    fetchGroup.leave()
                })
                
                fetchGroup.notify(queue: DispatchQueue.global(), execute: {
                    self.syncDevicePlayerInfo(audioOnly: false)
                    self.syncPosition()
                    self.listener()
                    callback(true)
                })
            } else {
                callback(false)
            }
        })
    }

    func isValidDevice(callback: @escaping (Bool) -> Void) {
        API.fetchDeviceInfo(callback: {(error: Error?, device: Device?) in
            if (error == nil && device != nil) {
                self.device = device
                return callback(true)
            }
            
            callback(false)
        })
    }
    
    func onPositionUpdate(_ callback: @escaping (Int) -> Void) {
        positionDelegates.append(callback)
    }
    
    // MARK: - Actions
    func pause() {
        API.pause()
    }
    
    func mute() {
        if (system?.mute ?? true) {
            API.unmute()
            system?.mute = false
        } else {
            API.mute()
            system?.mute = true
        }
    }
    
    func forward() {
        API.forward()
    }
    
    func rewind() {
        API.rewind()
    }
    
    func disconnect() {
        API.disconnect { (error) in}
    }
    
    // MARK: - Listener
    func listener(retry: Int = 0) {
        guard let sessionToken = self.sessionToken else {return}

        API.listen(sid: sessionToken, callback: {(error: Error?, timeout: Bool, notify: Notify?) in
            guard timeout == false else {
                return self.listener()
            }

            guard error == nil, let notify = notify  else {
                let retryCount = retry + 1;
                // Do something when we hit 5 retries
                if (retryCount > 3) {
                    self.isValidDevice(callback: { (valid) in
                        guard let changelistener = self.changeListener else {return}
                        if (valid) {
                            print("User Takeover")
                            changelistener(false, true)
                        } else {
                            print("Not reachable")
                            changelistener(true, false)
                        }
                        return
                    })
                } else {
                    self.listener(retry: retryCount)
                }
                return
            }
            
            print("\(notify.param) has been changed to \(notify.value)")
            
            let fetchGroup = DispatchGroup()
            
            if (notify.param != "netremote.multiroom.group.mastervolume") {
                fetchGroup.enter()
                self.API.fetchPlayState(callback: {(error: Error?, player: Player?) in
                    self.player = player
                    fetchGroup.leave()
                })
            }
            
            fetchGroup.enter()
            self.API.fetchSystemState(callback: {(error: Error?, system: System?) in
                self.system = system
                fetchGroup.leave()
            })
            
            fetchGroup.notify(queue: DispatchQueue.global(), execute: {
                self.syncDevicePlayerInfo(audioOnly: (notify.param == "netremote.multiroom.group.mastervolume"))
                if (self.changeListener != nil) {
                    self.changeListener!(false, false)
                }
                self.listener()
            })
        })
    }
}

