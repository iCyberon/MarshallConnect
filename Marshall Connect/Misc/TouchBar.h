//
//  TouchBar.h
//  Marshall Connect
//
//  Created by Vahagn Mkrtchyan on 12/12/18.
//  Copyright © 2018 Vahagn Mkrtchyan. All rights reserved.
//

#import <AppKit/AppKit.h>

extern void DFRElementSetControlStripPresenceForIdentifier(NSString *, BOOL);
extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);

@interface NSTouchBarItem ()

+ (void)addSystemTrayItem:(NSTouchBarItem *)item;

@end

@interface NSTouchBar ()

+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSString *)identifier;

@end
