//
//  FBNotificationReceiver.m
//  InGameOverlay
//
//  Created by Florian Bethke on 30.03.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import "FBNotificationReceiver.h"

void (*callback)(NSDictionary *);

@implementation FBNotificationReceiver

- (id)initWithCallback:(void (*) (NSDictionary*))call
{
	if(self == [super init]){
		[self registerForNotifications];
		callback = call;
	}
	return self;
}

- (void)registerForNotifications
{
	NSDistributedNotificationCenter *dnc;
	dnc = [NSDistributedNotificationCenter defaultCenter];
	
	[dnc addObserver:self 
			selector:@selector(handleDistributedNote:)
				name:@"InGameOverlayMessage" 
			  object:nil];
}

- (void)handleDistributedNote:(NSNotification *)note
{
	callback([note userInfo]);
}

@end
