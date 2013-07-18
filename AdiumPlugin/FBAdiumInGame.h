//
//  FBAdiumInGame.h
//  AdiumInGame
//
//  Created by Florian Bethke on 30.03.10.
//  Copyright Florian Bethke 2010 All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Adium/AIPlugin.h>
#import <Adium/AISharedAdium.h>
#import <Adium/AIContentObject.h>
#import <Adium/AICorePluginLoader.h>
#import <Adium/AIListContact.h>

@class FBPreferenceWindow;

@interface AdiumInGame : AIPlugin {
	NSMutableArray *games;
	NSDictionary *stringAttrib;
	NSMutableDictionary *chatLogs;
	FBPreferenceWindow *prefWindow;
	FBKeyboard *keyboard;
	
	int chatlog_index;
	NSString *lastchatlog;
}
- (void)appRunning:(NSString *)app withPID:(NSString *)pid;
- (void)previousMessage;
- (void)nextMessage;
- (void)goToLastMessage;
- (NSString *)messageForUser:(NSString *)userID;
- (NSString *)lastMessageForUser:(NSString *)userID;
- (NSArray *)chatLogForUser:(NSString *)userID;
- (NSDictionary *)stringAttributes;
- (FBPreferenceWindow *)preferenceWindow;

@end

@interface AdiumPatch : NSObject {

}
- (void)receivedMessage:(AIContentObject *)inObject;

@end