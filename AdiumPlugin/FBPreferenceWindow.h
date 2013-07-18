//
//  FBPreferenceWindow.h
//
//  Created by Florian Bethke on 06.04.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FBKeyboard;

@interface FBPreferenceWindow : NSObject {
	IBOutlet NSWindow *prefWindow;
	IBOutlet NSTableView *gameTable;
	IBOutlet NSButton *coloredOverlayBox;
	IBOutlet NSButton *autoUpdateBox;
	IBOutlet NSButton *hideWindowBox;
	IBOutlet NSButton *showAnswersBox;
	IBOutlet NSButton *customKeyButton;
	IBOutlet NSPopUpButton *positionButton;
	
	NSMutableArray *games;

}

- (BOOL)autoUpdate;
- (BOOL)hideWindow;
- (BOOL)showAnswer;
- (BOOL)runningOSX_10_6_orLater;
- (void)updateWithGames:(NSMutableArray *)newGames;
- (BOOL)keyPressed:(unsigned int)keyCode keyboard:(FBKeyboard *)keyboard;
- (IBAction)addGame:(id)sender;
- (IBAction)removeGame:(id)sender;
- (IBAction)savePreferences:(id)sender;
- (IBAction)sendNewGames:(id)sender;
- (IBAction)donate:(id)sender;
- (IBAction)keyComboButton:(id)sender;

@end
