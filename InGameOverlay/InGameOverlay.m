//
//  InGameOverlay.m
//  InGameOverlay
//
//  Created by Florian Bethke on 30.03.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#include <stdio.h>
#include <unistd.h>
#include <dlfcn.h>
#include "mach_override.h"
#include "InGameOverlay.h"
#import "FBWordWrap.h"
#import <objc/objc-runtime.h>
#include <dlfcn.h>
#include <syslog.h>

GLuint texture;

static CGLError hook_CGLFlushDrawable(CGLContextObj ctx)
{	
/*	timediff = CFAbsoluteTimeGetCurrent() - absolutetime;
	absolutetime = CFAbsoluteTimeGetCurrent();
	timerunning += timediff;
	
	Setup();
	DrawOverlay();
	Restore(); */
	
	/* OpenGL setup, adapted from Mumbles OpenGL Overlay */
	GLint program;
	GLint viewport[4];
	int i;
	
	glPushAttrib(GL_ALL_ATTRIB_BITS);
	glPushClientAttrib(GL_ALL_ATTRIB_BITS);
	glGetIntegerv(GL_VIEWPORT, viewport);
	glGetIntegerv(GL_CURRENT_PROGRAM, &program);
	
	GLint currentTextureBinding = 0;	
	glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTextureBinding);
	
	int width = viewport[2];
	int height = viewport[3];
	glViewport(0, 0, width, height);
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	glOrtho(0, width, height, 0, -100.0, 100.0);
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	
	glMatrixMode(GL_TEXTURE);
	glPushMatrix();
	glLoadIdentity();
	
	
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_AUTO_NORMAL);
	// Skip clip planes, there are thousands of them.
	glDisable(GL_COLOR_LOGIC_OP);
	glDisable(GL_COLOR_TABLE);
	glDisable(GL_CONVOLUTION_1D);
	glDisable(GL_CONVOLUTION_2D);
	glDisable(GL_CULL_FACE);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_DITHER);
	glDisable(GL_FOG);
	glDisable(GL_HISTOGRAM);
	glDisable(GL_INDEX_LOGIC_OP);
	glDisable(GL_LIGHTING);
	glDisable(GL_NORMALIZE);
	// Skip line smmooth
	// Skip map
	glDisable(GL_MINMAX);
	// Skip polygon offset
	glDisable(GL_SEPARABLE_2D);
	glDisable(GL_SCISSOR_TEST);
	glDisable(GL_STENCIL_TEST);
	glDisable(GL_TEXTURE_GEN_Q);
	glDisable(GL_TEXTURE_GEN_R);
	glDisable(GL_TEXTURE_GEN_S);
	glDisable(GL_TEXTURE_GEN_T);
	
	glRenderMode(GL_RENDER);
	
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_INDEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_EDGE_FLAG_ARRAY);
	
	glPixelStorei(GL_UNPACK_SWAP_BYTES, 0);
	glPixelStorei(GL_UNPACK_LSB_FIRST, 0);
	glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
	glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
	glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	
	GLint texunits = 1;
	
	glGetIntegerv(GL_MAX_TEXTURE_UNITS, &texunits);
	
	for (i=texunits-1;i>=0;--i) {
		glActiveTexture(GL_TEXTURE0 + i);
		glDisable(GL_TEXTURE_1D);
		glDisable(GL_TEXTURE_2D);
		glDisable(GL_TEXTURE_3D);
	}
	
	glDisable(GL_TEXTURE_CUBE_MAP);
	glDisable(GL_VERTEX_PROGRAM_ARB);
	glDisable(GL_FRAGMENT_PROGRAM_ARB);
	
	glUseProgram(0);
	
	glEnable(GL_COLOR_MATERIAL);
	glEnable(GL_TEXTURE_2D);
	glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	
	glMatrixMode(GL_MODELVIEW);
	
//	GLint uni = glGetUniformLocation(ctx->uiProgram, "tex");
//	glUniform1i(uni, 0);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	int bound = 0;
	glGetIntegerv(GL_PIXEL_UNPACK_BUFFER_BINDING, &bound);
	
	if (bound != 0)
		glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, 0);
	
	// Test code (draws a simple polygon with a texture on it)
/*	if(!texture)
		texture = LoadTexture(@"/Users/Flo/Desktop/Bild088.jpg");
	glBindTexture( GL_TEXTURE_2D, texture);
	
	GLint vp[4];
	glGetIntegerv(GL_VIEWPORT,vp);
	glColor3f(1.0f,1.0f,1.0f);
	glBegin(GL_QUADS);
	glTexCoord2f(0.0f, 0.0f);
	glVertex2f(0, 0);
	glTexCoord2f(0.0f, 1.0f);
	glVertex2f(0, 100);
	glTexCoord2f(1.0f, 1.0f);
	glVertex2f(100, 100);
	glTexCoord2f(1.0f, 0.0f);
	glVertex2f(100, 0);
	glEnd();*/
	
	DrawOverlay();
	
	if (bound != 0)
		glBindBuffer(GL_PIXEL_UNPACK_BUFFER_ARB, bound);
	
	glMatrixMode(GL_TEXTURE);
	glPopMatrix();
	
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	
	glPopClientAttrib();
	glPopAttrib();
	glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
	glUseProgram(program);
	
	glBindTexture( GL_TEXTURE_2D, currentTextureBinding);
	
	while (glGetError() != GL_NO_ERROR);
	
	return orig_CGLFlushDrawable(ctx);
}

GLuint LoadTexture(NSString* file)
{
	GLuint mytex=0;
	GLsizei width, height;
    BOOL hasAlpha;
    GLenum format;
    unsigned char* bitmapData;
	NSImage *texture1 = [[NSImage alloc] initWithContentsOfFile:file];
	if (texture1) {
	/*	GLint currentTextureBinding = 0;
		glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentTextureBinding);
		GLint currentTextureUnit = 0;
		glGetIntegerv(GL_ACTIVE_TEXTURE, &currentTextureUnit);
		glActiveTexture(GL_TEXTURE1); */
		
		glPushAttrib(GL_TEXTURE_BIT);
		NSBitmapImageRep *imageRep = (NSBitmapImageRep *)[texture1 bestRepresentationForDevice:nil];
		glGenTextures( 1, &mytex );
		
		glBindTexture( GL_TEXTURE_RECTANGLE_EXT, mytex );
		glTexParameteri( GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
		glTexParameteri( GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
		
		width  = [imageRep pixelsWide];
		height = [imageRep pixelsHigh];
		hasAlpha = [imageRep hasAlpha];
		bitmapData = [imageRep bitmapData];
		if(hasAlpha) {
			format = GL_RGBA;
		} else {
			format = GL_RGB;
		}
		//gluBuild2DMipmaps(GL_TEXTURE_2D, format, width, height, format, GL_UNSIGNED_BYTE, bitmapData);	// DON'T USE THIS!!!
		glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, bitmapData);
	//	glBindTexture( GL_TEXTURE_2D, currentTextureBinding);
		glPopAttrib();
	}
	[texture1 release];
	
	return mytex;
}

void recalculatePositions()
{
	GLint vp[4];
	glGetIntegerv(GL_VIEWPORT,vp);
	GLfloat height = vp[3];
	
	// Position = height of all previous messages + 10.0f offset per message
	for(unsigned int i=0;i<[messages count];i++){
		GLString *glMessage = [[messages objectAtIndex:i] objectForKey:@"Message"];
		NSNumber *position;
		[glMessage genTexture];	// Generate texture because we´ll need the size in the next step...
		if(position_top){	// overlay should be drawn at the top of the screen
			float pos = offset;
			for(unsigned int j=0;j<i; j++){
				NSSize size = [[[messages objectAtIndex:j] objectForKey:@"Message"] texSize];
				pos += size.height;
				pos += offset;
			}
			position = [[NSNumber alloc] initWithFloat:pos];
		}
		else {	// bottom of the screen
			float pos = height - offset - [[[messages objectAtIndex:0] objectForKey:@"Message"] texSize].height;
			for(unsigned int j=1;j<i+1; j++){
				NSSize size = [[[messages objectAtIndex:j] objectForKey:@"Message"] texSize];
				pos -= size.height;
				pos -= offset;
			}
			position = [[NSNumber alloc] initWithFloat:pos];
		}

		[[messages objectAtIndex:i] setObject:position forKey:@"yPosition"];
	}
}

void DrawOverlay(void)
{
	GLint vp[4];
	glGetIntegerv(GL_VIEWPORT,vp);
	GLfloat width = vp[2];
	GLfloat height = vp[3];
	
	double currtime = CFAbsoluteTimeGetCurrent();
	int messagecount = [messages count];
	if(messagecount){
		// Calculate positions if y = 0.0f
		if([[[messages objectAtIndex:messagecount-1] objectForKey:@"yPosition"] floatValue] == 0.0f){
			recalculatePositions();	// Calculates y pos
			if(position_left)	// overlay should be drawn at the left
				[[messages objectAtIndex:messagecount-1] setObject:[[NSNumber alloc] initWithFloat:10.0f] forKey:@"xPosition"];
			else {	// overlay should be drawn at the right
				float xpos = width - 10.0f - [[[messages objectAtIndex:messagecount-1] objectForKey:@"Message"] frameSize].width;
				[[messages objectAtIndex:messagecount-1] setObject:[[NSNumber alloc] initWithFloat:xpos] forKey:@"xPosition"];
			}
		}
		
		// Delete old messages (only one message gets deleted per frame)
		if([[[messages objectAtIndex:0] objectForKey:@"Time"] doubleValue] < (currtime - overlaytime)){
			[messages removeObjectAtIndex:0];
			recalculatePositions();
		}
	}
	glColor3f(1.0f, 1.0f, 1.0f);
	// Draw all messages
	for(unsigned int i=0;i<[messages count]; i++){
		GLString *message = [[messages objectAtIndex:i] objectForKey:@"Message"];
		double xpos = [[[messages objectAtIndex:i] objectForKey:@"xPosition"] doubleValue];
		double ypos = [[[messages objectAtIndex:i] objectForKey:@"yPosition"] doubleValue];
		[message drawAtPoint:NSMakePoint(xpos, ypos)];
	}
	
	// Performance-Fix for COD4
	glBegin(GL_QUADS);
	glEnd();

	// Draw chat GUI
	if(chat_mode){
		if(!tex)
			tex = LoadTexture([[NSBundle bundleForClass:[chat class]] pathForResource:@"chatfenster" ofType:@"png"]);
		
		glEnable (GL_TEXTURE_RECTANGLE_EXT);	
		
		glBindTexture (GL_TEXTURE_RECTANGLE_EXT, tex);
		glColor3f(1.0f,1.0f,1.0f);
		glBegin(GL_QUADS);
/*		glTexCoord2f(0.0f, 0.826f);
		glVertex2f(0, height - 89);
		glTexCoord2f(0.0f, 1.0f);
		glVertex2f(0, height);
		glTexCoord2f(0.9f, 1.0f);
		glVertex2f(461, height);
		glTexCoord2f(0.9f, 0.826f);
		glVertex2f(461, height - 89);*/
		glTexCoord2f(0.0f, 423.0f);
		glVertex2f(0, height - 89);
		glTexCoord2f(0.0f, 512.0f);
		glVertex2f(0, height);
		glTexCoord2f(461.0f, 512.0f);
		glVertex2f(461, height);
		glTexCoord2f(461.0f, 423.0f);
		glVertex2f(461, height - 89);
		glEnd();
		
		[answer drawAtPoint:NSMakePoint(15.0f, height - 31.0f)];
		[chat drawAtPoint:NSMakePoint(14.0f, height - 83.0f)];
	}
	else {
		tex = 0;
	}

}

// Print a new message
void addMessage(NSString *message, NSString *user, BOOL outgoing)
{
	NSString *formattedMessage = [FBWordWrap wordWrap:message attributes:stringAttrib withLineLength:250];
	NSString *str = [NSString stringWithFormat:@"%@: %@", user, formattedMessage];
	NSColor *color = [NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
	if(!outgoing)
		color = colorForUser(user);
	// Init GLString
	GLString *glMessage = [[GLString alloc]	initWithString:str 
											withAttributes:stringAttrib 
											withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] 
										//	withBoxColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.5f] 
											withBoxColor:color
											withBorderColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.8f]];
	// Don´t calc the position yet, OpenGL might not be ready 
	NSNumber *position = [[NSNumber alloc] initWithFloat:0.0f];
	NSNumber *currTime = [[NSNumber alloc] initWithDouble:CFAbsoluteTimeGetCurrent()];
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:glMessage, @"Message", position, @"yPosition", currTime, @"Time", nil];
	[messages addObject:dict];	// Save everything in the array
	[position release];
	[currTime release];
	[dict release];
}

// Gets called by the notification handler
// Sends Notification without userInfo now (not allowed in sandboxed apps)
void myCallback(NSDictionary *userInfo)
{
	if([[userInfo objectForKey:@"Type"] isEqualToString:@"Message"])
		addMessage([userInfo objectForKey:@"Message"], [userInfo objectForKey:@"Name"], FALSE);
	else if([[userInfo objectForKey:@"Type"] isEqualToString:@"Outgoing Message"])
		addMessage([userInfo objectForKey:@"Message"], [userInfo objectForKey:@"Name"], TRUE);
	else if([[userInfo	objectForKey:@"Type"] isEqualToString:@"Enable Chat"]){
		chat_mode = TRUE;
	//	NSDictionary *enabled = [NSDictionary dictionaryWithObjectsAndKeys:@"Enabled", @"State", nil];
	//	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayState" object:nil userInfo:enabled deliverImmediately:TRUE];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayStateEnabled" object:nil userInfo:nil deliverImmediately:TRUE];
		if(first_chat){
			first_chat = FALSE;
			addMessage(@"Use left and right arrow to navigate through open chat windows and up/down arrow to switch between received messages", @"Ingamium", FALSE);
		}
		// Reload the texture
		tex = LoadTexture([[NSBundle bundleForClass:[chat class]] pathForResource:@"chatfenster" ofType:@"png"]);
	}
	else if([[userInfo	objectForKey:@"Type"] isEqualToString:@"Disable Chat"]){
		chat_mode = FALSE;
	//	NSDictionary *disabled = [NSDictionary dictionaryWithObjectsAndKeys:@"Disabled", @"State", nil];
	//	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayState" object:nil userInfo:disabled deliverImmediately:TRUE];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"InGameOverlayStateDisabled" object:nil userInfo:nil deliverImmediately:TRUE];
	}
	else if([[userInfo	objectForKey:@"Type"] isEqualToString:@"Input"]){
		NSString *input = [userInfo objectForKey:@"Input"];
		[answer setString:input withAttributes:chatAttrib];
	}
	else if([[userInfo	objectForKey:@"Type"] isEqualToString:@"Chat"]){
		NSString *input = [userInfo objectForKey:@"Chat"];
		[chat setString:input withAttributes:stringAttrib];
	}
}

// Function to give every user his own color
NSColor* colorForUser(NSString *user)
{
	if(!colors_enabled) // black if colors are disabled
		return [NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
	
	if([user isEqualToString:@"Ingamium"])	// Messages from the plugin will always be black
		return [NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
	
	NSColor *color = [colors objectForKey:user];
	if(color)
		return color;
	
	switch ([colors count]) {
		case 0:	// First user gets red
			color = [NSColor colorWithDeviceRed:1.0f green:0.0f blue:0.0f alpha:0.5f];
			break;
		case 1: // Second gets green
			color = [NSColor colorWithDeviceRed:0.0f green:1.0f blue:0.0f alpha:0.5f];
			break;
		case 2: // Thrid blue
			color = [NSColor colorWithDeviceRed:0.0f green:0.0f blue:1.0f alpha:0.5f];
			break;
		case 3: // yellow
			color = [NSColor colorWithDeviceRed:1.0f green:1.0f blue:0.0f alpha:0.5f];
			break;
		case 4: // purple
			color = [NSColor colorWithDeviceRed:0.5f green:0.0f blue:0.5f alpha:0.5f];
			break;
		case 5: // orange
			color = [NSColor colorWithDeviceRed:1.0f green:0.5f blue:0.0f alpha:0.5f];
			break;
		case 6: // magenta
			color = [NSColor colorWithDeviceRed:1.0f green:0.0f blue:1.0f alpha:0.5f];
			break;
		case 7: // brown
			color = [NSColor colorWithDeviceRed:0.6f green:0.4f blue:0.2f alpha:0.5f];
			break;
		case 8: // cyan
			color = [NSColor colorWithDeviceRed:0.0f green:1.0f blue:1.0f alpha:0.5f];
			break;
		default: // default color is black
			return [NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
	}
	// Add the color to the array to save it for the next message
	[colors setObject:color forKey:user];

	return color;
}

__attribute__((constructor))
static void constr() {
	pool = [[NSAutoreleasePool alloc] init];
	
	// Override CGLFlushDrawable (gets called after every frame, in every OpenGL app)
	void *cgl = dlsym(RTLD_DEFAULT, "CGLFlushDrawable");
	if (cgl) {
		if (mach_override("_CGLFlushDrawable",NULL, hook_CGLFlushDrawable, (void **) &orig_CGLFlushDrawable) != 0) {
			syslog(LOG_NOTICE, "CGLFlushDrawable override failed.");
            return;
		}
	} else {
		syslog(LOG_NOTICE, "Unable to hook CGL");
		return;
	}
	syslog(LOG_NOTICE, "CGLFlushDrawable hooked!\n");

	
/*	//
	Class class = NSClassFromString(@"NSApplication");
	PerformSwizzle(class, @selector(sendEvent:), @selector(mySendEvent:), YES);*/
	
	// Init message array & the attribute dicitonary
	messages = [[NSMutableArray alloc] init];
	stringAttrib = [[NSMutableDictionary dictionary] retain];
	chatAttrib = [[NSMutableDictionary dictionary] retain];
	NSFont * font =[NSFont fontWithName:@"Helvetica" size:12.0];
	[stringAttrib setObject:font forKey:NSFontAttributeName];
	[stringAttrib setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	[chatAttrib setObject:font forKey:NSFontAttributeName];
	[chatAttrib setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[font release];
	
	// Init GLStrings for the GUI
	answer = [[GLString alloc] initWithString:@"" withAttributes:chatAttrib 
							  withTextColor:[NSColor blackColor] withBoxColor:[NSColor clearColor] withBorderColor:[NSColor clearColor]];
	[answer scrollsWithWidth:397];
	chat = [[GLString alloc] initWithString:@"<No open chat windows in Adium>" withAttributes:stringAttrib 
							  withTextColor:[NSColor whiteColor] withBoxColor:[NSColor clearColor] withBorderColor:[NSColor clearColor]];
	
	// Init array to safe the colors
	colors = [[NSMutableDictionary alloc] init];
	
	// Init notification receiver
	receiver = [[FBNotificationReceiver alloc] initWithCallback:myCallback];
	
	// Load preferences
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs addSuiteNamed:@"com.adiumX.adiumX"];
	if([prefs boolForKey:@"Colored Overlay"])
		colors_enabled = TRUE;
	else
		colors_enabled = FALSE;
	
	NSString *position = [prefs objectForKey:@"Position"];
	if([position intValue] == 0){
		position_top = TRUE;
		position_left = TRUE;
	}
	else if([position intValue] == 1){
		position_top = TRUE;
		position_left = FALSE;
	}
	else if([position intValue] == 2){
		position_top = FALSE;
		position_left = TRUE;
	}
	else if([position intValue] == 3){
		position_top = FALSE;
		position_left = FALSE;
	}
	
	addMessage(@"Code injected, Overlay working!\n\nPress Alt+Cmd+X to enable chat mode.", @"Ingamium", FALSE);
}

__attribute__((destructor))
static void destr() 
{
	[receiver release]; 
	[pool drain];
}

@implementation NSObject (NSApplicationPatch)

- (void)mySendEvent:(NSEvent *)anEvent
{
	if([anEvent type] == NSKeyDown)
		NSLog(@"%@", anEvent);
//	[self mySendEvent:anEvent];
}

@end
