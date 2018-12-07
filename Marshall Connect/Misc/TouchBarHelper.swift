//
//  TouchBarHelper.swift
//  TouchBarHelper
//
//  Created by ddddxxx on 2018/9/25.
//  Copyright © 2018年 ddddxxx. All rights reserved.
//

import AppKit

private let DFRFoundationPath = "/System/Library/PrivateFrameworks/DFRFoundation.framework/Versions/A/DFRFoundation"

@available(OSX 10.12.2, *)
private typealias DFRElementSetControlStripPresenceForIdentifierType = @convention(c) (NSTouchBarItem.Identifier, Bool) -> Void

@available(OSX 10.12.2, *)
private typealias DFRSystemModalShowsCloseBoxWhenFrontMostType = @convention(c) (Bool) -> Void

@available(OSX 10.12.2, *)
private let (_DFRElementSetControlStripPresenceForIdentifier, _DFRSystemModalShowsCloseBoxWhenFrontMost):
    (DFRElementSetControlStripPresenceForIdentifierType?, DFRSystemModalShowsCloseBoxWhenFrontMostType?) = {
        guard let handle = dlopen(DFRFoundationPath, RTLD_LAZY) else {
            return (nil, nil)
        }
        defer {
            dlclose(handle)
        }
        let f1 = dlsym(handle, "DFRElementSetControlStripPresenceForIdentifier").map {
            unsafeBitCast($0, to: DFRElementSetControlStripPresenceForIdentifierType.self)
        }
        let f2 = dlsym(handle, "DFRSystemModalShowsCloseBoxWhenFrontMost").map {
            unsafeBitCast($0, to: DFRSystemModalShowsCloseBoxWhenFrontMostType.self)
        }
        return (f1, f2)
}()

@available(OSX 10.12.2, *)
public func DFRElementSetControlStripPresenceForIdentifier(_ identifier: NSTouchBarItem.Identifier, _ presence: Bool) {
    _DFRElementSetControlStripPresenceForIdentifier?(identifier, presence)
}

@available(OSX 10.12.2, *)
public func DFRSystemModalShowsCloseBoxWhenFrontMost(_ show: Bool) {
    _DFRSystemModalShowsCloseBoxWhenFrontMost?(show)
}

@available(OSX 10.12.2, *)
public extension NSTouchBar {
    
    func presentSystemModal(placement: Int, systemTrayItemIdentifier: NSTouchBarItem.Identifier) {
        NSTouchBar.presentSystemModalTouchBar(self, placement: Int64(placement), systemTrayItemIdentifier: systemTrayItemIdentifier)
    }
    
    func presentSystemModal(systemTrayItemIdentifier: NSTouchBarItem.Identifier) {
        NSTouchBar.presentSystemModalTouchBar(self, systemTrayItemIdentifier: systemTrayItemIdentifier)
    }
    
    func dismissSystemModal() {
        NSTouchBar.dismissSystemModalTouchBar(self)
    }
    
    func minimizeSystemModal() {
        NSTouchBar.minimizeSystemModalTouchBar(self)
    }
}

@available(OSX 10.12.2, *)
public extension NSTouchBarItem {
    
    func addSystemTray() {
        NSTouchBarItem.addSystemTrayItem(self)
    }
    
    func removeSystemTray() {
        NSTouchBarItem.removeSystemTrayItem(self)
    }
}
