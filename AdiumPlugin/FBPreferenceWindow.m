//
//  FBPreferenceWindow.m
//
//  Created by Florian Bethke on 06.04.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import "FBPreferenceWindow.h"
#import "FBKeyboard.h"

@implementation FBPreferenceWindow

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"PreferenceWindow" owner:self];
		[gameTable setDataSource:self];
		
		// Load prefs
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		if([prefs boolForKey:@"Colored Overlay"])
		   [coloredOverlayBox setState:1];
		else
			[coloredOverlayBox setState:0];
		if([prefs boolForKey:@"AutoUpdate"])
			[autoUpdateBox setState:1];
		else
			[autoUpdateBox setState:0];
		if([prefs boolForKey:@"Hide Window"])
			[hideWindowBox setState:1];
		else
			[hideWindowBox setState:0];
		if([prefs boolForKey:@"Show Answer"])
			[showAnswersBox setState:1];
		else
			[showAnswersBox setState:0];
		[positionButton selectItemAtIndex:[[prefs objectForKey:@"Position"] intValue]];
				
		// Adium InGame launched for the first time
		if(![prefs boolForKey:@"NotFirstLaunch"]){
			[coloredOverlayBox setState:1];
			[autoUpdateBox setState:1];
			[hideWindowBox setState:1];
			[showAnswersBox setState:1];
			[customKeyButton setTitle:@"x"];
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:7] forKey:@"Custom Keycode"];
			[[NSUserDefaults standardUserDefaults] setObject:@"x" forKey:@"Custom Key"];
			[self savePreferences:nil];
		
			if(![self runningOSX_10_6_orLater])
				NSRunInformationalAlertPanel(@"Information for Leopard users", @"Please note that a few games working flawlessly on Snow Leopard with Ingamium run unstable on Leopard. If you have problems with a game (e.g. it just crashes at startup), disable it in the preference window by typing \"10.6\" in the \"Min. OS\" column of the games list.\
											 \nYou can send me a mail with your crash report, maybe I will be to fix that problem.",@"Okay",nil,nil);
		}
		else {
			if([[prefs objectForKey:@"Custom Key"] isEqualToString:@"0"])
				[customKeyButton setTitle:@"x"];
			else
				[customKeyButton setTitle:[prefs objectForKey:@"Custom Key"]];
		}

	}
	return self;
}

- (BOOL)runningOSX_10_6_orLater 
{
	OSStatus err;
	
	SInt32 majorOSVersion = 10, minorOSVersion = 0;
	err = Gestalt(gestaltSystemVersionMajor, &majorOSVersion);
	err = Gestalt(gestaltSystemVersionMinor, &minorOSVersion);
	
	return (majorOSVersion == 10 && minorOSVersion >= 6) || (majorOSVersion > 10);
}

- (BOOL)autoUpdate
{
	return [autoUpdateBox state];
}

- (BOOL)hideWindow
{
	return [hideWindowBox state];
}

- (BOOL)showAnswer
{
	return [showAnswersBox state];
}

- (void)open
{
	[prefWindow makeKeyAndOrderFront:self];
}

- (void)close
{
	[prefWindow close];
}

- (void)updateWithGames:(NSMutableArray *)newGames
{
	games = newGames;
	[gameTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if(games)
		return [games count];
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	if(games) {
		if([[column identifier] isEqualToString:@"Game"])
			return [[games objectAtIndex:row] objectForKey:@"Name"];
		else if([[column identifier] isEqualToString:@"Delay"])
			return [[games objectAtIndex:row] objectForKey:@"Delay"];
		else if([[column identifier] isEqualToString:@"Min. OS"])
			return [[games objectAtIndex:row] objectForKey:@"Minimum OS"];
	}
	return @"";
}

- (void)tableView:(NSTableView *)aTable setObjectValue:(id)data forTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	NSDictionary *game = [games objectAtIndex:row];
	NSString *oldName = [game objectForKey:@"Name"];
	NSNumber *oldDelay = [game objectForKey:@"Delay"];
	NSString *oldOS = [game objectForKey:@"Minimum OS"];
	NSDictionary *newGame;
	if([[column identifier] isEqualToString:@"Game"])
		newGame = [[NSDictionary alloc] initWithObjectsAndKeys:data, @"Name", oldDelay, @"Delay", oldOS, @"Minimum OS", nil];
	else if([[column identifier] isEqualToString:@"Delay"])
		newGame = [[NSDictionary alloc] initWithObjectsAndKeys:oldName, @"Name", data, @"Delay", oldOS, @"Minimum OS", nil];
	else if([[column identifier] isEqualToString:@"Min. OS"])
		newGame = [[NSDictionary alloc] initWithObjectsAndKeys:oldName, @"Name", oldDelay, @"Delay", data, @"Minimum OS", nil];
	[games replaceObjectAtIndex:row withObject:newGame];
	
	// Sort the array
	NSString *selectedGame = [[games objectAtIndex:row] objectForKey:@"Name"];
	NSSortDescriptor *descriptor =	[[[NSSortDescriptor alloc] initWithKey:@"Name"
									ascending:YES
									selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
	[games sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
//	[descriptor release];
	[gameTable reloadData];
	
	// Select the row which was edited
	for(int i=0;i<[games count];i++){
		if([selectedGame isEqualToString:[[games objectAtIndex:i] objectForKey:@"Name"]])
			[gameTable selectRow:i byExtendingSelection:NO];	
	}
	
	// Save the new games list:
	NSString *gamespath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Games" ofType:@"plist"];
	[games writeToFile:gamespath atomically:YES];
}

- (BOOL)keyPressed:(unsigned int)keyCode keyboard:(FBKeyboard *)keyboard
{
	if([customKeyButton state]){
		NSString *key = [keyboard stringForKeyCode:keyCode withModifierFlags:nil];
		[customKeyButton setTitle:key];
		[customKeyButton setState:0];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:keyCode] forKey:@"Custom Keycode"];
		[[NSUserDefaults standardUserDefaults] setObject:key forKey:@"Custom Key"];
		[[NSUserDefaults standardUserDefaults] registerDefaults:NULL];
		return TRUE;
	}
	return FALSE;
}

- (IBAction)addGame:(id)sender
{
	int row = [gameTable selectedRow];
	NSDictionary *newGame = [[NSDictionary alloc] initWithObjectsAndKeys:@"<Insert game here>", @"Name", nil, @"Delay", nil];
	if(row == -1){
		[games addObject:newGame];
		[gameTable selectRow:[games count]-1 byExtendingSelection:NO];
	}
	else {
		[games insertObject:newGame atIndex:row+1];
		[gameTable selectRow:row+1 byExtendingSelection:NO];
	}
	[gameTable reloadData];
}

- (IBAction)removeGame:(id)sender
{
	NSString *gamespath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Games" ofType:@"plist"];
	NSString *deletedgamespath = [[NSBundle bundleForClass:[self class]] pathForResource:@"DeletedGames" ofType:@"plist"];
	int row = [gameTable selectedRow];
	if(row == -1)
		NSBeep();
	else{
		NSMutableArray *deletedGames = [[NSMutableArray alloc] initWithContentsOfFile:deletedgamespath];
		[deletedGames addObject:[games objectAtIndex:row]];
		[deletedGames writeToFile:deletedgamespath atomically:YES];
		[deletedGames release];
		[games removeObjectAtIndex:row];
	}
	[gameTable reloadData];
	[games writeToFile:gamespath atomically:YES];
}

// Save the preferences (will be stored in com.adiumX.adiumX.plist)
- (IBAction)savePreferences:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"NotFirstLaunch"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[positionButton indexOfSelectedItem]] forKey:@"Position"];
	[[NSUserDefaults standardUserDefaults] setBool:[coloredOverlayBox state] forKey:@"Colored Overlay"];
	[[NSUserDefaults standardUserDefaults] setBool:[autoUpdateBox state] forKey:@"AutoUpdate"];
	[[NSUserDefaults standardUserDefaults] setBool:[showAnswersBox state] forKey:@"Show Answer"];
	[[NSUserDefaults standardUserDefaults] setBool:[hideWindowBox state] forKey:@"Hide Window"];
	[[NSUserDefaults standardUserDefaults] registerDefaults:NULL];
}

- (IBAction)sendNewGames:(id)sender
{
	NSDictionary* errorDict;
	NSAppleEventDescriptor* returnDescriptor = NULL;
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"SendMail" ofType:@"txt"];
	NSString *source = [[NSString alloc] initWithContentsOfFile:path];
	NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:source];
	returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
	[source release];
}

- (IBAction)donate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=986556SZT2BQ6"]];
}

- (IBAction)keyComboButton:(id)sender
{
	NSLog(@"%@", [sender title]);
}

@end
