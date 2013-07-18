//
//  FBUpdater.h
//  AdiumInGame
//
//  Created by Florian Bethke on 20.04.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FBUpdater : NSObject {

}

+ (void)installNewGames;
+ (NSArray *)getNewGames;
+ (NSArray *)compareArray:(NSArray *)array1 withArray:(NSArray *)array2;
+ (NSString *)getGameString:(NSArray *)newGames;

@end
