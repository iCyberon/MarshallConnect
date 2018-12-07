//
//  AppDelegate.swift
//  Marshall Connect
//
//  Created by Vahagn Mkrtchyan on 12/8/18.
//  Copyright © 2018 Vahagn Mkrtchyan. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        startServices()
        setupPopover()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    // MARK: - Setup
    func startServices() {
        _ = PlayerManager.shared()
    }
    
    func setupPopover() {
        if let button = statusItem.button {
            let image = NSImage(named: "StatusBarIconSmall")
            image?.isTemplate = true
            
            button.image = image
            button.image?.isTemplate = true
            button.action = #selector(AppDelegate.togglePopover(_:))
        }
        
        let mainViewController = PopupViewController.init(nibName: "PopupViewController", bundle: nil)
        popover.contentViewController = mainViewController
        popover.appearance = NSAppearance(named: .darkAqua)
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if self.popover.isShown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
    }
    
    // MARK: - Actions
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        eventMonitor?.start()
    }
    
    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }

}

