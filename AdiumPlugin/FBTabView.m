//
//  FBTabView.m
//  AdiumInGame
//
//  Created by Flo on 04.05.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FBTabView.h"


@implementation FBTabView

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
	NSSize size;
	if([[[self selectedTabViewItem] identifier] isEqualToString:@"1"])
		size = NSMakeSize(453.0f, 207);
	else if([[[self selectedTabViewItem] identifier] isEqualToString:@"2"])
		size = NSMakeSize(510.0f, 386.0f);

	[self resizeWindowToSize:size];
}

- (void)resizeWindowToSize:(NSSize)newSize
{
    NSRect aFrame;
    
    float newHeight = newSize.height;
    float newWidth = newSize.width;
	
    aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
									 styleMask:[[self window] styleMask]];
    
    aFrame.origin.y += aFrame.size.height;
    aFrame.origin.y -= newHeight;
    aFrame.size.height = newHeight;
    aFrame.size.width = newWidth;
    
    aFrame = [NSWindow frameRectForContentRect:aFrame 
									 styleMask:[[self window] styleMask]];
    
    [[self window] setFrame:aFrame display:YES animate:YES];
}

@end
