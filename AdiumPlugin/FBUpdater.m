//
//  FBUpdater.m
//  AdiumInGame
//
//  Created by Florian Bethke on 20.04.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import "FBUpdater.h"


@implementation FBUpdater

+ (void)installNewGames
{
	NSArray *games = [self getNewGames];
	NSString *gamespath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Games" ofType:@"plist"];
	NSMutableArray *oldGames = [[NSMutableArray alloc] initWithContentsOfFile:gamespath];
	if(!games)
		return;
	
	for(int j=0;j<[games count];j++){
		NSString *name = [[games objectAtIndex:j] objectForKey:@"Name"];
		for(int i=0;i<[oldGames count];i++){
			if([name isEqualToString:[[oldGames objectAtIndex:i] objectForKey:@"Name"]]){
				[oldGames removeObjectAtIndex:i];
			}
		}
	}
	
	[oldGames addObjectsFromArray:games];
	
	// Sort the array
	NSSortDescriptor *descriptor =	[[[NSSortDescriptor alloc] initWithKey:@"Name"
																ascending:YES
																 selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
	[oldGames sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	
	[oldGames writeToFile:gamespath atomically:YES];
	
	[oldGames release];
}

// Returns all new games
+ (NSArray *)getNewGames
{
	NSString *gamespath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Games" ofType:@"plist"];
	NSArray *oldGames = [NSArray arrayWithContentsOfFile:gamespath];
	
	NSURL *url = [NSURL URLWithString:@"http://ingamium.games4mac.de/Updates/Games.plist"];
	NSArray *newGames = [NSArray arrayWithContentsOfURL:url];
	
	NSArray *updatedGames = [self compareArray:oldGames withArray:newGames];
	NSString *games = [self getGameString:updatedGames];
	
	if([updatedGames count]){
		NSInteger buttonPressed = NSRunInformationalAlertPanel(@"New Games found!",games,@"Okay",@"Cancel",nil);
		
		if(buttonPressed ==NSAlertDefaultReturn)
			return [self compareArray:oldGames withArray:newGames];
	}
	return nil;
}

+ (NSArray *)compareArray:(NSArray *)oldArray withArray:(NSArray *)newArray
{
	NSString *deletedgamespath = [[NSBundle bundleForClass:[self class]] pathForResource:@"DeletedGames" ofType:@"plist"];
	NSMutableArray *array = [[NSMutableArray alloc] init];
	NSArray *deletedGames = [NSArray arrayWithContentsOfFile:deletedgamespath];
	
	for(int i=0;i<[newArray count];i++){
		BOOL newItem = TRUE;
		for(int j=0;j<[oldArray count];j++){
			if([[newArray objectAtIndex:i] isEqual:[oldArray objectAtIndex:j]])
				newItem = FALSE;
		}
		for(int j=0;j<[deletedGames count];j++){
			if([[newArray objectAtIndex:i] isEqual:[deletedGames objectAtIndex:j]])
				newItem = FALSE;
		}
		if(newItem)
			[array addObject:[newArray objectAtIndex:i]];
	}
	
	NSArray *returnarray = [NSArray arrayWithArray:array];
	[array release];
	
	return returnarray;
}

+ (NSString *)getGameString:(NSArray *)newGames
{
	NSMutableString *mutableString = [[NSMutableString alloc] init];
	[mutableString appendString:@"Do you want to add/update the following games?\n\n"];
	
	for(int i=0;i<[newGames count];i++){
		[mutableString appendString:@"- "];
		[mutableString appendString:[[newGames objectAtIndex:i] objectForKey:@"Name"]];
		[mutableString appendString:@"\n"];
	}
	
	NSString *string = [NSString stringWithString:mutableString];
	[mutableString release];
	
	return string;
}

@end
