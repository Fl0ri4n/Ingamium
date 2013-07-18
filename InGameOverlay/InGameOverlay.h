//
//  InGameOverlay.h
//  InGameOverlay
//
//  Created by Florian Bethke on 30.03.10.
//  Copyright 2010 Florian Bethke. All rights reserved.
//

#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glext.h>
#include <AGL/AGL.h>
#import "GLString.h"
#import "FBNotificationReceiver.h"

#if defined(__gl_h_)
typedef GLenum GLenum_type;
typedef GLint  GLint_type;
#else
typedef unsigned int GLenum_type;
typedef int GLint_type;
#endif

GLuint tex;
GLint oldtex;
GLuint texture;
CGLContextObj cgl_ctx; // current context at time of texture creation

double timediff		= 0;
double timerunning	= 0;
double absolutetime = 0;

// Settings
const double overlaytime = 10.0f; // Overlay will disappear after 10 secs
const float offset = 10.0f;	// 10.0 between 2 messages
bool colors_enabled = true; // Enable colored messages by default
bool position_left = true;	// true = left, false = right
bool position_top = false;	// true = top, false = bottom

bool chat_mode = false; // We aren´t in chat-mode at startup
bool first_chat = true;

GLString *chat, *answer, *buddylist;
NSMutableArray *messages;
NSMutableDictionary *stringAttrib;	// Dict to save the string attributes
NSMutableDictionary *chatAttrib;
NSMutableDictionary *colors;		// Saves the colors for each user

NSAutoreleasePool *pool;
FBNotificationReceiver *receiver;

typedef CGLError (*CGLFlushDrawableProcPtr)(CGLContextObj ctx);
static CGLFlushDrawableProcPtr orig_CGLFlushDrawable = NULL;
static CGLError hook_CGLFlushDrawable(CGLContextObj ctx);

void ViewOrtho(int x, int y);
void ViewPerspective(void);
void DrawOverlay(void);
GLuint LoadTexture(NSString* file);
void recalculatePositions(void);
void addMessage(NSString *message, NSString *user, BOOL outgoing);
void myCallback(NSDictionary *userInfo);
NSColor* colorForUser(NSString *user);