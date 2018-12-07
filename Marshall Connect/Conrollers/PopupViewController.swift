//
//  PopupViewController.swift
//  Marshall Connect
//
//  Created by Vahagn Mkrtchyan on 12/8/18.
//  Copyright © 2018 Vahagn Mkrtchyan. All rights reserved.
//

import Cocoa

class PopupViewController: NSViewController {
    // MARK: - Interface Items
    @IBOutlet weak var listView: NSView!
    @IBOutlet weak var playerView: NSView!
    @IBOutlet weak var takeoverView: NSVisualEffectView!
    @IBOutlet weak var playerTouchBar: NSTouchBar!
    @IBOutlet weak var playerVolumeTouchBar: NSTouchBar!
    
    // List View Elements
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var noDevicesLabel: NSTextField!
    
    // Takeover View Elements
    @IBOutlet weak var reconnectButton: NSButton!
    
    // Player View Elements
    @IBOutlet weak var backToListButton: NSButton!
    @IBOutlet weak var albumArt: NSImageView!
    @IBOutlet weak var shadowView: NSView!
    @IBOutlet weak var volumeView: NSView!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var songTitle: NSTextField!
    @IBOutlet weak var songArtist: NSTextField!
    @IBOutlet weak var songTracker: NSSlider!
    @IBOutlet weak var elapsedTime: NSTextField!
    @IBOutlet weak var remainingTime: NSTextField!
    @IBOutlet weak var backgroundAlbumArt: NSImageView!
    @IBOutlet weak var repeatButton: NSButton!
    @IBOutlet weak var shuffleButton: NSButton!
    
    // Volume View Elements
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var bassSlider: NSSlider!
    @IBOutlet weak var trebleSlider: NSSlider!
    
    // TouchBar Elements
    @IBOutlet weak var touchBarPlayButton: NSButton!
    @IBOutlet weak var touchBarSongTitle: NSTextField!
    @IBOutlet weak var touchBarSongArtist: NSTextField!
    @IBOutlet weak var touchBarMuteButton: NSButton!
    @IBOutlet weak var touchBarVolumeSlider: NSSlider!
    @IBOutlet weak var touchBarElapsedTime: NSTextField!
    @IBOutlet weak var touchBarRemainingTime: NSTextField!
    
    
    fileprivate var loadedImage: URL?
    
    // State
    private var lastState: PlayerManagerState?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.setupUI()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.setupConstraints()
        self.render(PlayerManager.shared().state)
        
        PlayerManager.shared().setListener { (state: PlayerManagerState) in
            DispatchQueue.main.async {
                self.render(state)
            }
        }
        PlayerManager.shared().onPositionUpdate { (position: Int) in
            if let song = PlayerManager.shared().song {
                DispatchQueue.main.async {
                    self.songTracker.floatValue = (Float(PlayerManager.shared().position) / Float(song.duration)) * 100
                    self.elapsedTime.stringValue = (PlayerManager.shared().position / 1000).asString()
                    self.touchBarElapsedTime.stringValue = (PlayerManager.shared().position / 1000).asString()
                    self.remainingTime.stringValue = "-\(((song.duration - PlayerManager.shared().position) / 1000).asString())"
                    self.touchBarRemainingTime.stringValue = "-\(((song.duration - PlayerManager.shared().position) / 1000).asString())"
                }
            }
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.setupTouchBar()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if (!self.volumeView.isHidden) {
            self.toggleVolumeBar(self)
        }
    }
    
    // MARK: - Actions
    @IBAction func disconnect(_ sender: Any) {
        PlayerManager.shared().disconnect()
    }
    
    @IBAction func reconnect(_ sender: Any) {
        PlayerManager.shared().reconnect { (connected) in
            print("Reconnection \(connected ? "Succeeded" : "Failed")")
        }
    }
    
    @IBAction func playPause(_ sender: Any) {
        PlayerManager.shared().playPause()
    }
    
    @IBAction func next(_ sender: Any) {
        PlayerManager.shared().next()
    }
    
    @IBAction func previous(_ sender: Any) {
        PlayerManager.shared().prev()
    }
    
    @IBAction func toggleVolumeBar(_ sender: Any) {
        self.volumeView.isHidden = !self.volumeView.isHidden
        self.albumArt.isHidden = !self.volumeView.isHidden
        self.shadowView.isHidden = !self.volumeView.isHidden
        self.backToListButton.isHidden = !self.volumeView.isHidden
    }
    
    @IBAction func positionUpdated(_ sender: NSSlider) {
        if let song = PlayerManager.shared().song {
            let position = lround(sender.doubleValue / sender.maxValue * Double(song.duration))
            PlayerManager.shared().setPosition(position)
        }
    }

    @IBAction func volumeUpdated(_ sender: NSSlider) {
        switch sender {
        case self.volumeSlider, self.touchBarVolumeSlider:
            PlayerManager.shared().volume = sender.floatValue
        case self.bassSlider:
            PlayerManager.shared().bass = sender.floatValue
        case self.trebleSlider:
            PlayerManager.shared().treble = sender.floatValue
        default:
            return
        }
    }
    
    @IBAction func toggleMute(_ sender: Any) {
        PlayerManager.shared().mute()
        
        self.touchBarMuteButton.bezelColor = (PlayerManager.shared().muteStatus) ? NSColor.systemRed : nil
    }
    
    // MARK: - UI
    private func render(_ state: PlayerManagerState) {
        if (state == .Takeover) {
            self.takeoverView.bounds = self.view.bounds
            self.view.addSubview(self.takeoverView)
            return
        } else {
            self.takeoverView.removeFromSuperview()
        }

        if (PlayerManager.shared().hasActiveDevice()) {
            // We have an active device already
            // Get information and update UI
            self.playerView.isHidden = false
            self.listView.removeFromSuperview()
            self.touchBarVolumeSlider.floatValue = PlayerManager.shared().volume
            self.volumeSlider.floatValue = PlayerManager.shared().volume
            self.bassSlider.floatValue = PlayerManager.shared().bass
            self.trebleSlider.floatValue = PlayerManager.shared().treble
            
            if (PlayerManager.shared().status == .Playing || PlayerManager.shared().status == .Loading) {
                self.playButton.state = .on
                self.touchBarPlayButton.state = .on
            } else if (PlayerManager.shared().status == .Paused) {
                self.playButton.state = .off
                self.touchBarPlayButton.state = .off
            }
            
            self.touchBarMuteButton.state = (PlayerManager.shared().muteStatus) ? .off : .on
            self.touchBarMuteButton.bezelColor = (PlayerManager.shared().muteStatus) ? NSColor.systemRed : nil
            
            if let song = PlayerManager.shared().song {
                self.songTitle.stringValue = song.name
                self.touchBarSongTitle.stringValue = song.name
                self.songArtist.stringValue = song.artist
                self.touchBarSongArtist.stringValue = song.artist
                self.songTracker.floatValue = (Float(PlayerManager.shared().position) / Float(song.duration)) * 100
                self.elapsedTime.stringValue = (PlayerManager.shared().position / 1000).asString()
                self.touchBarElapsedTime.stringValue = (PlayerManager.shared().position / 1000).asString()
                self.remainingTime.stringValue = "-\(((song.duration - PlayerManager.shared().position) / 1000).asString())"
                self.touchBarRemainingTime.stringValue = "-\(((song.duration - PlayerManager.shared().position) / 1000).asString())"

                if let albumArt = song.albumArt, self.loadedImage != song.albumArt {
                    URLSession.shared.dataTask(with: albumArt) { data, response, error in
                        guard
                            let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                            let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                            let data = data, error == nil,
                            let image = NSImage(data: data)
                            else {
                                return
                        }
                        DispatchQueue.main.async() {
                            self.loadedImage = song.albumArt
                            self.albumArt.image = image
                            self.backgroundAlbumArt.image = image
                        }
                    }.resume()
                }
            }
        } else {
            // No active device, get list of available devices
            // Display device chooser
            self.playerView.isHidden = true
            self.listView.bounds = self.view.bounds
            self.view.addSubview(self.listView)

            if (PlayerManager.shared().devices().count == 0) {
                self.noDevicesLabel.isHidden = false
            } else {
                self.noDevicesLabel.isHidden = true
            }
            self.tableView.reloadData()
        }
    }
    
    private func setupTouchBar() {
        DFRSystemModalShowsCloseBoxWhenFrontMost(true)
        let item = NSCustomTouchBarItem(identifier: .systemTrayItem)
        item.view = NSButton(image: #imageLiteral(resourceName: "StatusBarIconSmall"), target: self, action: #selector(presentTouchBar))
        item.addSystemTray()
        DFRElementSetControlStripPresenceForIdentifier(.systemTrayItem, true)
    }
    
    @objc private func presentTouchBar() {
        self.playerTouchBar.presentSystemModal(systemTrayItemIdentifier: .systemTrayItem)
    }
    
    @IBAction func presentVolumeBar(_ sender: Any) {
        self.playerVolumeTouchBar.presentSystemModal(systemTrayItemIdentifier: .systemTrayVolumeItem)
    }
    
    private func setupUI() {
        self.view.wantsLayer = true
        
        self.albumArt.wantsLayer = true
        self.albumArt.layer?.cornerRadius = 10
        self.albumArt.layer?.masksToBounds = true
        
        self.shadowView.wantsLayer = true
        self.shadowView.layer?.masksToBounds = false
        self.shadowView.layer?.shadowColor = NSColor.black.cgColor
        self.shadowView.layer?.shadowOpacity = 0.7
        self.shadowView.layer?.shadowOffset = CGSize.zero
        self.shadowView.layer?.shadowRadius = 14
        self.shadowView.layer?.shadowPath = NSBezierPath(roundedRect: self.shadowView.bounds, xRadius: 10, yRadius: 10).cgPath
    }
    
    private func setupConstraints() {
        if let frameView = self.view.superview {
            if let constraint = (frameView.constraints.filter{
                $0.firstAttribute == .height && $0.identifier == nil
                }.first) {
                constraint.constant = 0
            }
        }
    }
    
}

// MARK: - Speakers Lists View
extension PopupViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return PlayerManager.shared().devices().count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let result:KSTableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "defaultRow"), owner: self) as! KSTableCellView
        
        let device = PlayerManager.shared().devices()[row]

        result.imgView.image = device.image
        result.titleTextField.stringValue = device.name
        result.detailsTextField.stringValue = device.model
        return result;
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let device = PlayerManager.shared().devices()[tableView.selectedRow]
        
        PlayerManager.shared().selectDevice(device: device, callback: { (connected) in
            DispatchQueue.main.async {
                if (!connected) {
                    print("Unable to connect")
                }
                self.render(PlayerManager.shared().state)
            }
        })
    }
}

class KSTableCellView: NSTableCellView {
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var detailsTextField: NSTextField!
}

extension NSTouchBarItem.Identifier {
    static let systemTrayItem = NSTouchBarItem.Identifier("com.iCyberon.MarshallConnect")
    static let systemTrayVolumeItem = NSTouchBarItem.Identifier("com.iCyberon.MarshallConnect.VolumeBar")
}

extension Int {
    func asString() -> String {
        let hours = self / 3600
        let minutes = (self / 60) % 60
        let seconds = self % 60
        
        let OneDigitFormatter = NumberFormatter()
        OneDigitFormatter.numberStyle = .none
        OneDigitFormatter.percentSymbol = ""
        OneDigitFormatter.minimumIntegerDigits = 1
        OneDigitFormatter.maximumFractionDigits = 0
        
        let TwoDigitFormatter = NumberFormatter()
        TwoDigitFormatter.numberStyle = .none
        TwoDigitFormatter.percentSymbol = ""
        TwoDigitFormatter.minimumIntegerDigits = 2
        TwoDigitFormatter.maximumFractionDigits = 0
        
        if (hours > 0) {
            let hoursString = OneDigitFormatter.string(from: NSNumber.init(value: hours))!
            let minutesString = TwoDigitFormatter.string(from: NSNumber.init(value: minutes))!
            let secondsString = TwoDigitFormatter.string(from: NSNumber.init(value: seconds))!
            return "\(hoursString):\(minutesString):\(secondsString)"
        } else {
            let minutesString = OneDigitFormatter.string(from: NSNumber.init(value: minutes))!
            let secondsString = TwoDigitFormatter.string(from: NSNumber.init(value: seconds))!
            return "\(minutesString):\(secondsString)"
        }
    }
}

