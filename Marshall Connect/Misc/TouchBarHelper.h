//
//  TouchBarHelper.h
//  TouchBarHelper
//
//  Created by ddddxxx on 2018/9/25.
//  Copyright © 2018年 ddddxxx. All rights reserved.
//

#ifndef TouchBarPrivate_h
#define TouchBarPrivate_h

#import <AppKit/AppKit.h>

@interface NSTouchBarItem (PrivateMethods)

+ (void)addSystemTrayItem:(NSTouchBarItem *)item;

+ (void)removeSystemTrayItem:(NSTouchBarItem *)item;

@end

@interface NSTouchBar (PrivateMethods)

// MARK: macOS 10.14 and above

+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar placement:(long long)placement systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_AVAILABLE_MAC(10.14);

+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_AVAILABLE_MAC(10.14);

+ (void)dismissSystemModalTouchBar:(NSTouchBar *)touchBar NS_AVAILABLE_MAC(10.14);

+ (void)minimizeSystemModalTouchBar:(NSTouchBar *)touchBar NS_AVAILABLE_MAC(10.14);

// MARK: macOS 10.13 and below

+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar placement:(long long)placement systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_DEPRECATED_MAC(10.12.2, 10.14);

+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier NS_DEPRECATED_MAC(10.12.2, 10.14);

+ (void)dismissSystemModalFunctionBar:(NSTouchBar *)touchBar NS_DEPRECATED_MAC(10.12.2, 10.14);

+ (void)minimizeSystemModalFunctionBar:(NSTouchBar *)touchBar NS_DEPRECATED_MAC(10.12.2, 10.14);

@end

#endif /* TouchBarPrivate_h */
