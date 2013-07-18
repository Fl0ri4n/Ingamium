//
//  FBNotificationReceiver.h
//  InGameOverlay
//
//  Created by Florian Bethke on 30.03.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FBNotificationReceiver : NSObject {
	
}
- (id)initWithCallback:(void (*) (NSDictionary*))call;
- (void)registerForNotifications;

@end