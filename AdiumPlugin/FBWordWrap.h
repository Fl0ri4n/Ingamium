//
//  FBWordWrap.h
//  InGameOverlay
//
//  Created by Florian Bethke on 08.04.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FBWordWrap : NSObject {

}

+ (NSString *)wordWrap:(NSString *)inString attributes:(NSDictionary *)stringAttrib withLineLength:(float)maxLength;

@end
