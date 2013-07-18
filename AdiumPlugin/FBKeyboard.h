//
//  FBKeyboard.h
//  AdiumInGame
//
//  Created by Florian Bethke on 18.04.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h>

@class AdiumInGame;

@interface FBKeyboard : NSObject {
	NSDictionary *enable, *disable;
	NSMutableString *input;

	BOOL chat_mode;
	int chat_index;
	
	NSString *lastchatname;
	int lastchatmessage;
	
	CFMachPortRef eventTap;
	
	bool x_key;
	unsigned int customKey;
	
	AdiumInGame *controller;
}

- (id)initWithController:(AdiumInGame *)contrl;
- (void)registerForNotifications;
- (void)updateChatView;
- (void)updateChatIndex:(NSString *)user;
- (void)appTerminated;
- (CGEventRef)processEvent:(CGEventRef)event withType:(CGEventType)type;
- (NSString *)stringForKeyCode:(unsigned short)keyCode withModifierFlags:(NSUInteger)modifierFlags;

@end
