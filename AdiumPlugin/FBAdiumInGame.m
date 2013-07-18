//
//  FBAdiumInGame.m
//  AdiumInGame
//
//  Created by Florian Bethke on 30.03.10.
//  Copyright Florian Bethke 2010 All rights reserved.
//

#import "FBPreferenceWindow.h"
#import "FBKeyboard.h"
#import "FBUpdater.h"
#import "FBAdiumInGame.h"
#import "DKInstaller.h"
#import <Cocoa/Cocoa.h>
#import <objc/objc-runtime.h>
#import "DKInjector.h"
#include <dlfcn.h>

static BOOL PerformSwizzle(Class aClass, SEL orig_sel, SEL alt_sel, BOOL forInstance);

@implementation AdiumInGame

- (void)installPlugin
{
	NSLog(@"Installing AdiumInGame...");

	// Add the preference entry to the main menu
	prefWindow = [[FBPreferenceWindow alloc] init];
	NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
	NSMenuItem *adiumMenuItem = [mainMenu itemAtIndex:0];
	NSMenu *adiumMenu = [adiumMenuItem submenu];
	[adiumMenu insertItemWithTitle:@"InGame Preferences…" action:@selector(open) keyEquivalent:@"" atIndex:7];
	[[adiumMenu itemAtIndex:7] setTarget:prefWindow];

	// Swizzle Adiums "receivedContentObject"-method with my own one
	Class class = NSClassFromString(@"AIContentController");
	PerformSwizzle(class, @selector(receiveContentObject:), @selector(receivedMessage:), YES);
    
    
    // Launch helper application to install framework and daemon
    NSURL *installerURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Ingamium Installer" withExtension:@"app"];
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:installerURL options:NSWorkspaceLaunchDefault configuration:nil error:nil];
    
	// Set receiver for NSWorkspaceDidLaunchApplicationNotification
	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
	[nc addObserver:self 
				selector:@selector(workspaceDidLaunchApplication:)
				name:NSWorkspaceDidLaunchApplicationNotification
				object:nil];
	[nc addObserver:self 
		   selector:@selector(workspaceDidTerminateApplication:)
			   name:NSWorkspaceDidTerminateApplicationNotification
			 object:nil];
	
	// Get updated games
	if([prefWindow autoUpdate])
	   [FBUpdater installNewGames];
	
	// Get the list of supported games
	NSString *gamespath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Games" ofType:@"plist"];
	games = [[NSMutableArray alloc] initWithContentsOfFile:gamespath];
	[prefWindow updateWithGames:games];
	
	// Send a list of running apps to the "appRunning"-method
	NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
	for(int i=0;i<[apps count];i++){
		NSDictionary *app = [apps objectAtIndex:i];
		NSString *name = [[app objectForKey:@"NSApplicationPath"] lastPathComponent];
		NSNumber *pid = [app objectForKey:@"NSApplicationProcessIdentifier"];
		[self appRunning:name withPID:[pid stringValue]];
	}
	
	// Init chat log dictionary
	chatLogs = [[NSMutableDictionary alloc] init];
	
	// Init Keyboard class
	keyboard = [[FBKeyboard alloc] initWithController:self];
	
	// Init chatlog stuff
	lastchatlog = @"";
	chatlog_index = 0;
}

- (void)uninstallPlugin
{
  // Uninstall the Plugin
}	

// Gets called if an application is launched
- (void)workspaceDidLaunchApplication:(NSNotification *)notification 
{
	NSDictionary *app = [notification userInfo];
	NSString *name = [[app objectForKey:@"NSApplicationPath"] lastPathComponent];
	NSNumber *pid = [app objectForKey:@"NSApplicationProcessIdentifier"];
	[self appRunning:name withPID:[pid stringValue]];
}

- (void)workspaceDidTerminateApplication:(NSNotification *)notification
{
	NSDictionary *app = [notification userInfo];
	NSString *name = [[app objectForKey:@"NSApplicationPath"] lastPathComponent];
	
	for(int i=0;i<[games count];i++){
		if([name isEqualToString:[[games objectAtIndex:i] objectForKey:@"Name"]]){
			[keyboard appTerminated];
		}
	}
}

// Checks whether the app is supported by the overlay
- (void)appRunning:(NSString *)app withPID:(NSString *)pid
{
	for(int i=0;i<[games count];i++){
		if([app isEqualToString:[[games objectAtIndex:i] objectForKey:@"Name"]]){
			// Don´t try injecting the code on a Leopard computer if the game is reported to be unstable below 10.6
			if(![prefWindow runningOSX_10_6_orLater] && [[[games objectAtIndex:i] objectForKey:@"Minimum OS"] isEqualToString:@"10.6"])
				return;
			   
			NSNumber *injection_delay = [[games objectAtIndex:i] objectForKey:@"Delay"];
			double delay = [injection_delay doubleValue];
			
			NSTimeInterval timeInterval = delay;
			NSTimer *myTimer = [ [ NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector( launch: ) userInfo:pid repeats:NO ] retain ];
			[ [ NSRunLoop currentRunLoop ] addTimer:myTimer forMode:NSEventTrackingRunLoopMode ];
			[ [ NSRunLoop currentRunLoop ] addTimer:myTimer forMode:NSModalPanelRunLoopMode ];
		}
	}
}

// Launch the helper app and inject our code
- (void)launch:(NSTimer *)timer
{	
	NSString *pid_str = [timer userInfo];
    NSInteger pid = [pid_str integerValue];
    
    // Establish connection to daemon
    NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.florianbethke.Ingamium.Injector.mach" host:nil];
    assert(c != nil);
    DKInjector *injector = (DKInjector *)[c rootProxy];
    
    //NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"InGameOverlay" ofType:@"bundle"];
    NSString *bundlePath = @"/System/Library/Ingamium/Contents/Resources/InGameOverlay.bundle";
    
    NSLog(@"Injecting process %@ with bundle: %@", pid_str, bundlePath);
    
    // Inject!
    [injector inject:pid withBundle:[bundlePath fileSystemRepresentation]];
}


- (void)receivedMessage:(AIContentObject *)inObject
{
	if(!inObject || ![inObject source])
		return;
	if(![[inObject source] respondsToSelector:@selector(internalUniqueObjectID)])
		 return;
	NSString *name = [(AIListContact *)[inObject source] internalUniqueObjectID];
	if(![chatLogs objectForKey:name])
		[chatLogs setObject:[[NSMutableArray alloc] init] forKey:name];
	
	NSMutableArray *chatlog = [chatLogs objectForKey:name];
	[chatlog addObject:[[inObject message] string]];
	
	
	[keyboard updateChatIndex:[[inObject source] displayName]];
	[keyboard updateChatView];
}

- (NSString *)lastMessageForUser:(NSString *)userID
{
	NSArray *chatlog = [chatLogs objectForKey:userID];
	if(chatlog)
		return [chatlog lastObject];
	return @"";
}

- (NSString *)messageForUser:(NSString *)userID
{
	if([userID isEqualToString:lastchatlog])
	{
		NSArray *chatlog = [chatLogs objectForKey:userID];
		if(chatlog && [chatlog count] > chatlog_index)
			return [chatlog objectAtIndex:chatlog_index];
		else if(chatlog && [chatlog count] <= chatlog_index){
			chatlog_index = [chatlog count] - 1;
			return [chatlog lastObject];
		}
	}
	else {
		lastchatlog = userID;
		NSArray *chatlog = [chatLogs objectForKey:userID];
		if(chatlog){
			chatlog_index = [chatlog count] - 1;
			return [chatlog lastObject];
		}
	}

	return @"";
}

- (void)previousMessage
{
	chatlog_index -= 1;
	if(chatlog_index < 0)
		chatlog_index = 0;
}

- (void)nextMessage
{
	chatlog_index += 1;
	if(chatlog_index > ([[chatLogs objectForKey:lastchatlog] count] - 1))
		chatlog_index = [[chatLogs objectForKey:lastchatlog] count] - 1;
}

- (void)goToLastMessage
{
	chatlog_index = [[chatLogs objectForKey:lastchatlog] count] - 1;
}

- (NSArray *)chatLogForUser:(NSString *)userID
{
	return [chatLogs objectForKey:userID];
}

- (NSDictionary *)stringAttributes
{
	return stringAttrib;
}

- (FBPreferenceWindow *)preferenceWindow
{
	return prefWindow;
}

- (void)dealloc
{
	[prefWindow release];
	[keyboard release];
	[chatLogs release];
	[games release];
	[super dealloc];
}
	
@end

@implementation NSObject (AdiumPatch)

// We´ve received a message, forward it to running games
- (void)receivedMessage:(AIContentObject *)inObject
{
	NSString *message = [[inObject message] string];
	NSString *name = [[inObject source] displayName];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"Message", name, @"Name", @"Message", @"Type", nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayMessage" object:nil userInfo:dict deliverImmediately:TRUE];
	[self receivedMessage:inObject];
	
	AdiumInGame *ingame = [[adium pluginLoader] pluginWithClassName:@"AdiumInGame"];
	[ingame	receivedMessage:inObject];
}

@end

// Function for method swizzling from GrowlSafari sourecde:

// Using method swizzling as outlined here:
// http://www.cocoadev.com/index.pl?MethodSwizzling
// A couple of modifications made to support swizzling class methods

static BOOL PerformSwizzle(Class aClass, SEL orig_sel, SEL alt_sel, BOOL forInstance) 
{
    // First, make sure the class isn't nil
	if (aClass) {
		Method orig_method = nil, alt_method = nil;
		
		// Next, look for the methods
		if (forInstance) {
			orig_method = class_getInstanceMethod(aClass, orig_sel);
			alt_method = class_getInstanceMethod(aClass, alt_sel);
		} else {
			orig_method = class_getClassMethod(aClass, orig_sel);
			alt_method = class_getClassMethod(aClass, alt_sel);
		}
		
		// If both are found, swizzle them
		if (orig_method && alt_method) {
			method_exchangeImplementations(orig_method, alt_method);
			
			return YES;
		} else {
			// This bit stolen from SubEthaFari's source
			NSLog(@"Error: Original (selector %s) %@, Alternate (selector %s) %@",
				  sel_getName(orig_sel),
				  orig_method ? @"was found" : @"not found",
				  sel_getName(alt_sel),
				  alt_method ? @"was found" : @"not found");
		}
	} else {
		NSLog(@"%@", @"Error: No class to swizzle methods in");
	}
	
	return NO;
}