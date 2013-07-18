//
//  FBAppDelegate.m
//  HelperApp
//
//  Created by Flo on 17.07.13.
//
//

#import "FBAppDelegate.h"
#import "DKInstaller.h"

@implementation FBAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSError *error;
    
    // Install helper tools
    if ([DKInstaller isInstalled] == NO && [DKInstaller install:&error] == NO) {
//    if ([DKInstaller install:&error] == NO) {
        assert(error != nil);
        
        NSLog(@"Couldn't install Ingamium (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }
    [NSApp terminate:self];
}

@end
