//
//  FBKeyboard.m
//  AdiumInGame
//
//  Created by Florian Bethke on 18.04.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import "FBKeyboard.h"
#import "FBPreferenceWindow.h"
#import "FBAdiumInGame.h"
#import "FBWordWrap.h"
#import <Adium/AIPlugin.h>
#import <Adium/AISharedAdium.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIChat.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>

FBKeyboard *keyboard;

@implementation FBKeyboard

CGEventRef myCGEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
	return [keyboard processEvent:event withType:type];
}

- (id)initWithController:(AdiumInGame *)contrl; {
	if (self = [super init]) {
		controller = contrl;
		keyboard = self;
		chat_mode = FALSE;
		chat_index = 0;
		disable = [[NSDictionary alloc] initWithObjectsAndKeys:@"Disable Chat", @"Type", nil];
		enable = [[NSDictionary alloc] initWithObjectsAndKeys:@"Enable Chat", @"Type", nil];
		input = [[NSMutableString alloc] init];
		x_key = FALSE;
		customKey = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Custom Keycode"] intValue];
		[self registerForNotifications];
		
		// Register callback for keyboard events
		CGEventMask        eventMask;
		CFRunLoopSourceRef runLoopSource;
		
		// Create an event tap. We are interested in key presses.
		eventMask = ((1 << kCGEventKeyDown) | (1 << kCGEventKeyUp));
		eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0,
									eventMask, myCGEventCallback, NULL);
		if (!eventTap) {
			fprintf(stderr, "failed to create event tap\n");
			return self;
		}
		
		// Create a run loop source.
		runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
		
		// Add to the current run loop.
		CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource,
						   kCFRunLoopCommonModes);
		
		// Enable the event tap.
		CGEventTapEnable(eventTap, true);
	}
	return self;
}

- (NSString *)stringForKeyCode:(unsigned short)keyCode withModifierFlags:(NSUInteger)modifierFlags
{
	TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
	CFDataRef uchr = (CFDataRef)TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
	const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout*)CFDataGetBytePtr(uchr);
	
	if(keyboardLayout) {
		UInt32 deadKeyState = 0;
		UniCharCount maxStringLength = 255;
		UniCharCount actualStringLength = 0;
		UniChar unicodeString[maxStringLength];
		
		OSStatus status = UCKeyTranslate(keyboardLayout,
										 keyCode, kUCKeyActionDown, modifierFlags,
										 LMGetKbdType(), 0,
										 &deadKeyState,
										 maxStringLength,
										 &actualStringLength, unicodeString);
		
		if(status != noErr)
			NSLog(@"There was an %s error translating from the '%ld' key code to a human readable string: %s",
				  GetMacOSStatusErrorString(status), status, GetMacOSStatusCommentString(status));
		else if(actualStringLength > 0) {
			return [NSString stringWithCharacters:unicodeString length:(NSInteger)actualStringLength];
		} else
			NSLog(@"Couldn't find a translation for the '%d' key code", keyCode);
	} else
		NSLog(@"Couldn't find a suitable keyboard layout from which to translate");
	
	return nil;
}


- (CGEventRef)processEvent:(CGEventRef)event withType:(CGEventType)type
{		
	if (kCGEventTapDisabledByTimeout == type) {
	//	NSLog(@"kCGEventTapDisabledByTimeout");
		CGEventTapEnable(eventTap, true);
	}
	
	if (kCGEventTapDisabledByUserInput == type) {
		NSLog(@"kCGEventTapDisabledByUserInput");
	}
	
	if (kCGEventNull == type) {
		NSLog(@"kCGEventNull");
	}
	
	// Is it a keyboard event?
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp))
        return event;
	
    // Get the keycode
    CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
	CGEventFlags flags = CGEventGetFlags ( event );
	if(flags == 0x20104)	// Shift-Bug
		flags = 0x20102;
	if([[controller preferenceWindow] keyPressed:keyCode keyboard:self])
		customKey = keyCode;
	if(keyCode == customKey && type == kCGEventKeyDown)
		x_key = TRUE;
	else if(keyCode == customKey && type == kCGEventKeyUp)
		x_key = FALSE;

	// Has "Cmd + Alt + X" (or a custom combo) been pressed? If so, toggle chat mode
	if(x_key && (GetCurrentKeyModifiers() & cmdKey) && (GetCurrentKeyModifiers() & optionKey)){
		if(chat_mode){
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:disable deliverImmediately:TRUE];
			return 0;
		}
		else {
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:enable deliverImmediately:TRUE];
			return 0;
		//	return event;
		}
	}
		
	// Process keyboard events
	if(chat_mode && type == kCGEventKeyDown){
		if(keyCode == 36){	// Return
			//Send the message
			if(!([input isEqualToString:@""])){
				NSArray *chats = [[[adium chatController] openChats] allObjects];
				AIChat *chat = [chats objectAtIndex:chat_index];
				NSAttributedString *message = [[NSAttributedString alloc] initWithString:input];
			//	NSString *receiver = [[chats objectAtIndex:chat_index] displayName];
	 
				AIContentMessage *msg = [AIContentMessage messageInChat:chat 
															 withSource:[chat account] 
															destination:[chat listObject] 
																   date:[NSDate date] 
																message:message 
															  autoreply:NO];
			//	if([adium.contentController processAndSendContentObject:msg])	// Shouldn´t be used directly according to adium documentation
				if([adium.contentController sendContentObject:msg])
					NSLog(@"Message sent!");
				else
					NSLog(@"Sending failed...!");
	 
				NSLog(@"Chat %@, Message %@, Account %@", chat, msg, [chat account]);
				
				// Show the answer as overlay
				if([[controller preferenceWindow] showAnswer]){
					NSString *recvString = [NSString stringWithFormat:@"To %@", [[chats objectAtIndex:chat_index] displayName]];
					NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:input, @"Message", recvString, @"Name", @"Outgoing Message", @"Type", nil];
					[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:dict deliverImmediately:TRUE];
				}
	 
				// Delete the string & disable chat mode
				[input setString:@""];
				if([[controller preferenceWindow] hideWindow])
					[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:disable deliverImmediately:TRUE];
				[message release];
			}
		}
		else if(keyCode == 51){	// Backspace
			if([input length])
				[input replaceCharactersInRange:NSMakeRange([input length]-1, 1) withString:@""];
		}
		else if(keyCode == 53){	// Escape
			[input setString:@""];
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:disable deliverImmediately:TRUE];
		}
		else if(keyCode == 123){  // Left arrow
			[input setString:@""];
			if(chat_index-1 < 0)
				chat_index = [[[[adium chatController] openChats] allObjects] count] -1;
			else
				chat_index -= 1;
			[self updateChatView];
		}
		else if(keyCode == 124){  // Right arrow
			[input setString:@""];
			if(chat_index+1 < [[[[adium chatController] openChats] allObjects] count])
				chat_index += 1;
			else
				chat_index = 0;
			[self updateChatView];
		}
		else if(keyCode == 125){  // Down arrow
			[controller nextMessage];
			[self updateChatView];
		}
		else if(keyCode == 126){  // Up arrow
			[controller previousMessage];
			[self updateChatView];
		}

		else {
			NSString *key = [self stringForKeyCode:keyCode withModifierFlags:flags];

			[input appendString:key];
		}
		NSDictionary *inputDict = [NSDictionary dictionaryWithObjectsAndKeys:input, @"Input", @"Input", @"Type", nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:inputDict deliverImmediately:TRUE];
	}
	
    // Only return the event if we aren´t in chat mode
	// No other application will receive it otherwise
	if(!chat_mode)
		return event;
	return 0;
}

- (void)registerForNotifications
{
	NSDistributedNotificationCenter *dnc;
	dnc = [NSDistributedNotificationCenter defaultCenter];
	
	[dnc addObserver:self 
			selector:@selector(handleDistributedNote:)
				name:@"InGameOverlayStateEnabled" 
			  object:nil];
	[dnc addObserver:self 
			selector:@selector(handleDistributedNote:)
				name:@"InGameOverlayStateDisabled" 
			  object:nil];
}

- (void)handleDistributedNote:(NSNotification *)note
{
	if([[note name] isEqualToString:@"InGameOverlayStateEnabled"]){
//	if([[[note userInfo] objectForKey:@"State"] isEqualToString:@"Enabled"]){
		chat_mode = TRUE;
		[controller goToLastMessage];
		[self updateChatView];
	}
//	else if([[[note userInfo] objectForKey:@"State"] isEqualToString:@"Disabled"]){
	else if([[note name] isEqualToString:@"InGameOverlayStateDisabled"]){
		chat_mode = FALSE;
	}
}

- (void)appTerminated
{
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:disable deliverImmediately:TRUE];
	[input setString:@""];
	chat_mode = FALSE;
}

-(void)updateChatView
{
	NSArray *openChats = [[[adium chatController] openChats] allObjects];
	if([openChats count] == 0){
		//chat_index == 0;
		NSDictionary *inputDict = [NSDictionary dictionaryWithObjectsAndKeys:@"<No open chat windows in Adium>", @"Chat", @"Chat", @"Type", nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:inputDict deliverImmediately:TRUE];
		return;
	}
	
/*	for(int i=0;i<[openChats count];i++)
		NSLog(@"Open Chat: %@ (%@)", [[[openChats objectAtIndex:i] listObject] displayName], [[openChats objectAtIndex:i] uniqueChatID]);*/
	if([openChats count] > chat_index){
		NSString *chat_name = [[openChats objectAtIndex:chat_index] displayName];
	//	NSString *lastMessage = [controller lastMessageForUser:[[[openChats objectAtIndex:chat_index] listObject] internalUniqueObjectID]];
		NSString *lastMessage = [controller messageForUser:[[[openChats objectAtIndex:chat_index] listObject] internalUniqueObjectID]];
		NSString *string = [NSString stringWithFormat:@"%@: %@", chat_name, lastMessage];
		string = [FBWordWrap wordWrap:string attributes:[controller stringAttributes] withLineLength:420.0f];
		
		NSDictionary *inputDict = [NSDictionary dictionaryWithObjectsAndKeys:string, @"Chat", @"Chat", @"Type", nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:inputDict deliverImmediately:TRUE];
	}
}

- (void)updateChatIndex:(NSString *)user
{
	if(chat_mode)
		return;
	NSArray *openChats = [[[adium chatController] openChats] allObjects];
	for(int i=0;i<[openChats count];i++){
		if([[[[openChats objectAtIndex:i] listObject] displayName] isEqualToString:user])
			chat_index = i;
	}
}

- (void)dealloc {
	[disable release];
	[enable release];
	[input release];
	[super dealloc];
}

@end