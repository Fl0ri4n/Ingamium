//
//  InjectionHelper.m
//  InGameOverlay
//
//  Created by Florian Bethke on 30.03.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#include <mach_inject_bundle/mach_inject_bundle.h>
#include <mach/mach_error.h>
#include <dlfcn.h>

void inject(pid_t pid);

int main(int argc, char **argv) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if(argc == 2)
	{
		BOOL valid = NO;
		NSString *PIDNum = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
		pid_t pid = [PIDNum intValue];
		NSLog(@"pid: %ld\n path: %s\n", pid, [[[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:@"mach_inject_bundle.framework"] fileSystemRepresentation]);

		void *result = dlopen([[[[[NSBundle mainBundle] privateFrameworksPath] stringByAppendingPathComponent:@"mach_inject_bundle.framework"] stringByAppendingPathComponent:@"mach_inject_bundle"] fileSystemRepresentation], RTLD_LAZY);
		NSLog(@"framework load result: %p\n", result);
			
		inject(pid);
	}
	[pool drain];
	return 0;
}

void inject(pid_t pid)
{
	NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"InGameOverlay" ofType:@"bundle"];
	if (bundlePath) {
	mach_error_t err = mach_inject_bundle_pid([bundlePath fileSystemRepresentation], pid);
	if (err != ERR_SUCCESS)
		NSLog(@"Error while injecting into process %i: %s (system 0x%x, subsystem 0x%x, code 0x%x)", pid, mach_error_string(err), err_get_system(err), err_get_sub(err), err_get_code(err));
	}
}