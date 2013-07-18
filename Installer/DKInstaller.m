//
//  DKInstaller.m
//  Dark
//
//  Created by Erwan Barrier on 8/11/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>

#import "DKInstaller.h"
#import "DKFrameworkInstaller.h"

NSString *const DKInjectorExecutablLabel  = @"com.florianbethke.Ingamium.Injector";
NSString *const DKInstallerExecutablLabel = @"com.florianbethke.Ingamium.Installer";
NSString *const DKUserDefaultsInstalledVersionKey = @"InstalledIngamiumVersion";
NSString *const DKErrorDomain = @"com.florianbethke.Ingamium.ErrorDomain";
NSString *const DKErrPermissionDeniedDescription = @"MachInjectSample couldn't complete installation without an administrator's permission.";
NSString *const DKErrInstallDescription = @"An error occurred while installing MachInjectSample. Please report this to the author.";
NSString *const DKErrInjectionDescription = @"An error occurred while injecting Finder. Please report this to the author.";

@interface DKInstaller ()
+ (BOOL)askPermission:(AuthorizationRef *)authRef error:(NSError **)error;
+ (BOOL)installHelperTool:(NSString *)executableLabel authorizationRef:(AuthorizationRef)authRef error:(NSError **)error;
+ (BOOL)installMachInjectBundleFramework:(NSError **)error;
@end

@implementation DKInstaller

+ (BOOL)isInstalled {
    NSURL *parentURL = [[[[[NSBundle mainBundle] bundleURL] URLByDeletingLastPathComponent]
                            URLByDeletingLastPathComponent] URLByDeletingLastPathComponent];
    NSLog(@"%@", [NSBundle bundleWithURL:parentURL]);
    
    
    NSString *versionInstalled = [[NSUserDefaults standardUserDefaults] stringForKey:DKUserDefaultsInstalledVersionKey];
    NSString *currentVersion = [[NSBundle bundleWithURL:parentURL] objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    NSLog(@"%@", currentVersion);

  return ([currentVersion compare:versionInstalled] == NSOrderedSame);
}

+ (BOOL)install:(NSError **)error {
  AuthorizationRef authRef = NULL;
  BOOL result = YES;

  result = [self askPermission:&authRef error:error];

  if (result == YES) {
    result = [self installHelperTool:DKInstallerExecutablLabel authorizationRef:authRef error:error];
  }

  if (result == YES) {
    result = [self installMachInjectBundleFramework:error];
  }

  if (result == YES) {
    result = [self installHelperTool:DKInjectorExecutablLabel authorizationRef:authRef error:error];
  }

  if (result == YES) {
      NSURL *parentURL = [[[[[NSBundle mainBundle] bundleURL] URLByDeletingLastPathComponent]
                            URLByDeletingLastPathComponent] URLByDeletingLastPathComponent];
      
      // Copy Ingamium to system folder to bypass sandboxing
      NSString *bundlePath = [[NSBundle	bundleForClass:[self class]] bundlePath];
      FILE *myCommunicationsPipe = NULL;
      NSString *myPath = @"/bin/cp";
      bundlePath = [NSString stringWithFormat:@"%@/.", [parentURL path]];
      char *myCPArguments[] = { "-R", (char *)[bundlePath UTF8String], "/System/Library/Ingamium", NULL };
      AuthorizationExecuteWithPrivileges(authRef, [myPath UTF8String],
                                        kAuthorizationFlagDefaults, myCPArguments,
                                        &myCommunicationsPipe);
      
      // "Enable access for assistive devices"
      myPath = @"/usr/bin/touch";
      char *myTouchArguments[] = { "/private/var/db/.AccessibilityAPIEnabled", NULL};
      AuthorizationExecuteWithPrivileges(authRef, [myPath UTF8String],
                                        kAuthorizationFlagDefaults, myTouchArguments,
                                        &myCommunicationsPipe);
      
      // Get installed version
      NSString *currentVersion = [[NSBundle bundleWithURL:parentURL] objectForInfoDictionaryKey:@"CFBundleVersion"];
      [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:DKUserDefaultsInstalledVersionKey];

    NSLog(@"Installed v%@", currentVersion);
  }
  
  return result;
}

+ (BOOL)askPermission:(AuthorizationRef *)authRef error:(NSError **)error {
  // Creating auth item to bless helper tool and install framework
  AuthorizationItem authItem = {kSMRightBlessPrivilegedHelper, 0, NULL, 0};

  // Creating a set of authorization rights
	AuthorizationRights authRights = {1, &authItem};

  // Specifying authorization options for authorization
	AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;

  // Open dialog and prompt user for password
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, authRef);

  if (status == errAuthorizationSuccess) {
    return YES;
  } else {
    NSLog(@"%@ (error code: %@)", DKErrPermissionDeniedDescription, [NSNumber numberWithInt:status]);

    *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                        code:DKErrPermissionDenied
                                    userInfo:@{NSLocalizedDescriptionKey: DKErrPermissionDeniedDescription}];

    return NO;
  }
}

+ (BOOL)installHelperTool:(NSString *)executableLabel authorizationRef:(AuthorizationRef)authRef error:(NSError **)error {
  CFErrorRef blessError = NULL;
  BOOL result;

  result = SMJobBless(kSMDomainSystemLaunchd, ( CFStringRef)executableLabel, authRef, &blessError);

  if (result == NO) {
    CFIndex errorCode = CFErrorGetCode(blessError);
    CFStringRef errorDomain = CFErrorGetDomain(blessError);

    NSLog(@"an error occurred while installing %@ (domain: %@ (%@))", executableLabel, errorDomain, [NSNumber numberWithLong:errorCode]);

    *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                        code:DKErrInstallHelperTool
                                    userInfo:@{NSLocalizedDescriptionKey: DKErrInstallDescription}];
  } else {
    NSLog(@"Installed %@ successfully", executableLabel);
  }

  return result;
}


+ (BOOL)installMachInjectBundleFramework:(NSError **)error {
  NSString *frameworkPath = [[NSBundle mainBundle] pathForResource:@"mach_inject_bundle" ofType:@"framework"];
//  NSString *frameworkPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"mach_inject_bundle" ofType:@"framework"];
    NSLog(@"Framework Path: %@", frameworkPath);

  BOOL result = YES;

  NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.florianbethke.Ingamium.Installer.mach" host:nil];
  assert(c != nil);

  DKFrameworkInstaller *installer = (DKFrameworkInstaller *)[c rootProxy];
  assert(installer != nil);

  result = [installer installFramework:frameworkPath];

  if (result == YES) {
    NSLog(@"Installed mach_inject_bundle.framework successfully");
  } else {
    NSLog(@"an error occurred while installing mach_inject_bundle.framework (domain: %@ code: %@)", installer.error.domain, [NSNumber numberWithInteger:installer.error.code]);

    *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                        code:DKErrInstallFramework
                                    userInfo:@{NSLocalizedDescriptionKey: DKErrInstallDescription}];
  }

  return result;
}

@end
