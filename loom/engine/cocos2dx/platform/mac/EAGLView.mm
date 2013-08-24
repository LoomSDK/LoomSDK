/****************************************************************************
Copyright (c) 2010 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/

/*
 * Idea of subclassing NSOpenGLView was taken from  "TextureUpload" Apple's sample
 */

#include "GL/glew.h"
#import <Availability.h>
#import <Carbon/Carbon.h>

#import "EAGLView.h"
#import "CCEGLView.h"
#import "CCDirector.h"
#import "ccConfig.h"
#import "CCSet.h"
#import "CCWindow.h"
#import "CCEventDispatcher.h"
#import "touch_dispatcher/CCTouch.h"
#import "keypad_dispatcher/CCKeypadDispatcher.h"
#import "text_input_node/CCIMEDispatcher.h"
#import "scrollwheel_dispatcher/CCScrollWheelDispatcher.h"
#import "loom/common/platform/platformKeyCodes.h"

#include "loom/graphics/gfxGraphics.h"

//USING_NS_CC;
static EAGLView *view;

@implementation EAGLView

@synthesize eventDelegate = eventDelegate_, isFullScreen = isFullScreen_;

+(id) sharedEGLView
{
	return view;
}

- (id) initWithFrame:(NSRect)frameRect
{
	self = [self initWithFrame:frameRect shareContext:nil];
	return self;
}

- (id) initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext*)context
{    
    NSOpenGLPixelFormatAttribute attribs[] =
    {
//		NSOpenGLPFAAccelerated,
//		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		
		0
    };
	
	NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	
	if (!pixelFormat)
		NSLog(@"No OpenGL pixel format");
	

	if( (self = [super initWithFrame:frameRect pixelFormat:[pixelFormat autorelease]]) )
    {
		if( context )
        {
			[self setOpenGLContext:context];
        }


		// event delegate
		eventDelegate_ = [CCEventDispatcher sharedDispatcher];
	}
	
	view = self;
	return self;
}

- (void) update
{
	// XXX: Should I do something here ?
	[super update];
}

- (void) prepareOpenGL
{
	// XXX: Initialize OpenGL context

	[super prepareOpenGL];
	
	// Make this openGL context current to the thread
	// (i.e. all openGL on this thread calls will go to this context)
	[[self openGLContext] makeCurrentContext];
	
    glewInit();

	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];	

    GFX::Graphics::setPlatformData(NULL, (void*) self, (void*) [self openGLContext]);

    GFX::Graphics::initialize();

//	GLint order = -1;
//	[[self openGLContext] setValues:&order forParameter:NSOpenGLCPSurfaceOrder];
}

- (NSUInteger) depthFormat
{
	return 24;
}

- (void) reshape
{
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously when resizing

	[self lockOpenGLContext];
	
	NSRect rect = [self bounds];
	
	cocos2d::CCDirector *director = cocos2d::CCDirector::sharedDirector();
	CGSize size = NSSizeToCGSize(rect.size);
	cocos2d::CCSize ccsize = cocos2d::CCSizeMake(size.width, size.height);
	director->reshapeProjection(ccsize);
	
	// avoid flicker
	director->drawScene();
//	[self setNeedsDisplay:YES];
	
	[self unlockOpenGLContext];
}

-(void) lockOpenGLContext
{
	NSOpenGLContext *glContext = [self openGLContext];
	NSAssert( glContext, @"FATAL: could not get openGL context");

	[glContext makeCurrentContext];
	CGLLockContext((CGLContextObj)[glContext CGLContextObj]);
}

-(void) unlockOpenGLContext
{
	NSOpenGLContext *glContext = [self openGLContext];
	NSAssert( glContext, @"FATAL: could not get openGL context");

	CGLUnlockContext((CGLContextObj)[glContext CGLContextObj]);
}

- (void) dealloc
{
	CCLOGINFO(@"cocos2d: deallocing %@", self);

	[super dealloc];
}
	
-(int) getWidth
{
	NSSize bound = [self bounds].size;
	return bound.width;
}

-(int) getHeight
{
	NSSize bound = [self bounds].size;
	return bound.height;
}

-(void) swapBuffers
{
}

//
// setFullScreen code taken from GLFullScreen example by Apple
//
- (void) setFullScreen:(BOOL)fullscreen
{
	// Mac OS X 10.6 and later offer a simplified mechanism to create full-screen contexts
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5

    if (isFullScreen_ == fullscreen)
		return;

	EAGLView *openGLview = [[self class] sharedEGLView];

    if( fullscreen ) {
        originalWinRect_ = [openGLview frame];

        // Cache normal window and superview of openGLView
        if(!windowGLView_)
            windowGLView_ = [[openGLview window] retain];

        [superViewGLView_ release];
        superViewGLView_ = [[openGLview superview] retain];


        // Get screen size
        NSRect displayRect = [[NSScreen mainScreen] frame];

        // Create a screen-sized window on the display you want to take over
        fullScreenWindow_ = [[CCWindow alloc] initWithFrame:displayRect fullscreen:YES];

        // Remove glView from window
        [openGLview removeFromSuperview];

        // Set new frame
        [openGLview setFrame:displayRect];

        // Attach glView to fullscreen window
        [fullScreenWindow_ setContentView:openGLview];

        // Show the fullscreen window
        [fullScreenWindow_ makeKeyAndOrderFront:self];
		[fullScreenWindow_ makeMainWindow];
		//[fullScreenWindow_ setNextResponder:superViewGLView_];

    } else {

        // Remove glView from fullscreen window
        [openGLview removeFromSuperview];

        // Release fullscreen window
        [fullScreenWindow_ release];
        fullScreenWindow_ = nil;

        // Attach glView to superview
        [superViewGLView_ addSubview:openGLview];

        // Set new frame
        [openGLview setFrame:originalWinRect_];

        // Show the window
        [windowGLView_ makeKeyAndOrderFront:self];
		[windowGLView_ makeMainWindow];
    }
	
	// issue #1189
	[windowGLView_ makeFirstResponder:openGLview];

    isFullScreen_ = fullscreen;

    //[openGLview retain]; // Retain +1

	// is this necessary?
    // re-configure glView
	//cocos2d::CCDirector *director = cocos2d::CCDirector::sharedDirector();
	//director->setOpenGLView(openGLview); //[self setView:openGLview];

    //[openGLview release]; // Retain -1

    [openGLview setNeedsDisplay:YES];
#else
#error Full screen is not supported for Mac OS 10.5 or older yet
#error If you don't want FullScreen support, you can safely remove these 2 lines
#endif
}

#if CC_DIRECTOR_MAC_USE_DISPLAY_LINK_THREAD
#define DISPATCH_EVENT(__event__, __selector__) [eventDelegate_ queueEvent:__event__ selector:__selector__];
#else
#define DISPATCH_EVENT(__event__, __selector__)												\
	id obj = eventDelegate_;																\
	[obj performSelector:__selector__														\
			onThread:[(cocos2d::CCDirector*)[CCDirector sharedDirector] runningThread]			\
		  withObject:__event__																\
	   waitUntilDone:NO];
#endif

#pragma mark EAGLView - Mouse events

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint event_location = [theEvent locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	float x = local_point.x;
	float y = [self getHeight] - local_point.y;
	
    int ids[1] = {0};
    float xs[1] = {0.0f};
    float ys[1] = {0.0f};
    
	ids[0] = [theEvent eventNumber];
	xs[0] = x;
	ys[0] = y;

	cocos2d::CCDirector::sharedDirector()->getOpenGLView()->handleTouchesBegin(1, ids, xs, ys);
}

- (void)mouseMoved:(NSEvent *)theEvent
{
	DISPATCH_EVENT(theEvent, _cmd);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint event_location = [theEvent locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	float x = local_point.x;
	float y = [self getHeight] - local_point.y;

    int ids[1] = {0};
    float xs[1] = {0.0f};
    float ys[1] = {0.0f};
    
	ids[0] = [theEvent eventNumber];
	xs[0] = x;
	ys[0] = y;

	cocos2d::CCDirector::sharedDirector()->getOpenGLView()->handleTouchesMove(1, ids, xs, ys);
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint event_location = [theEvent locationInWindow];
	NSPoint local_point = [self convertPoint:event_location fromView:nil];
	
	float x = local_point.x;
	float y = [self getHeight] - local_point.y;

    int ids[1] = {0};
    float xs[1] = {0.0f};
    float ys[1] = {0.0f};
    
	ids[0] = [theEvent eventNumber];
	xs[0] = x;
	ys[0] = y;

	cocos2d::CCDirector::sharedDirector()->getOpenGLView()->handleTouchesEnd(1, ids, xs, ys);
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	DISPATCH_EVENT(theEvent, _cmd);

	// pass the event along to the next responder (like your NSWindow subclass)
	[super rightMouseDown:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent {
	DISPATCH_EVENT(theEvent, _cmd);
	[super rightMouseDragged:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent {
	DISPATCH_EVENT(theEvent, _cmd);
	[super rightMouseUp:theEvent];
}

- (void)otherMouseDown:(NSEvent *)theEvent {
	DISPATCH_EVENT(theEvent, _cmd);
	[super otherMouseDown:theEvent];
}

- (void)otherMouseDragged:(NSEvent *)theEvent {
	DISPATCH_EVENT(theEvent, _cmd);
	[super otherMouseDragged:theEvent];
}

- (void)otherMouseUp:(NSEvent *)theEvent {
	DISPATCH_EVENT(theEvent, _cmd);
	[super otherMouseUp:theEvent];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	DISPATCH_EVENT(theEvent, _cmd);
	[super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent {
	DISPATCH_EVENT(theEvent, _cmd);
	[super mouseExited:theEvent];
}

-(void) scrollWheel:(NSEvent *)theEvent {
    float dy = [theEvent scrollingDeltaY];
    
    // Normalize to -1, 1
    if (dy < 0)
        dy = -1;
    else if (dy > 0)
        dy = 1;

    cocos2d::CCDirector::sharedDirector()->getScrollWheelDispatcher()->dispatchScrollWheelDeltaY(dy);
}

#pragma mark EAGLView - Key events

-(BOOL) becomeFirstResponder
{
	return YES;
}

-(BOOL) acceptsFirstResponder
{
	return YES;
}

-(BOOL) resignFirstResponder
{
	return YES;
}


static const unsigned int MAC_TO_LOOM_KEYCODE[128] = {
    /* 00 */ LOOM_KEY_A,
    /* 01 */ LOOM_KEY_S,
    /* 02 */ LOOM_KEY_D,
    /* 03 */ LOOM_KEY_F,
    /* 04 */ LOOM_KEY_H,
    /* 05 */ LOOM_KEY_G,
    /* 06 */ LOOM_KEY_Z,
    /* 07 */ LOOM_KEY_X,
    /* 08 */ LOOM_KEY_C,
    /* 09 */ LOOM_KEY_V,
    /* 0a */ -1,
    /* 0b */ LOOM_KEY_B,
    /* 0c */ LOOM_KEY_Q,
    /* 0d */ LOOM_KEY_W,
    /* 0e */ LOOM_KEY_E,
    /* 0f */ LOOM_KEY_R,
    /* 10 */ LOOM_KEY_Y,
    /* 11 */ LOOM_KEY_T,
    /* 12 */ LOOM_KEY_1,
    /* 13 */ LOOM_KEY_2,
    /* 14 */ LOOM_KEY_3,
    /* 15 */ LOOM_KEY_4,
    /* 16 */ LOOM_KEY_6,
    /* 17 */ LOOM_KEY_5,
    /* 18 */ LOOM_KEY_PADEQUAL_SIGN,
    /* 19 */ LOOM_KEY_9,
    /* 1a */ LOOM_KEY_7,
    /* 1b */ LOOM_KEY_HYPHEN,
    /* 1c */ LOOM_KEY_8,
    /* 1d */ LOOM_KEY_0,
    /* 1e */ LOOM_KEY_CLOSE_BRACKET,
    /* 1f */ LOOM_KEY_O,
    /* 20 */ LOOM_KEY_U,
    /* 21 */ LOOM_KEY_OPEN_BRACKET,
    /* 22 */ LOOM_KEY_I,
    /* 23 */ LOOM_KEY_P,
    /* 24 */ LOOM_KEY_RETURN_OR_ENTER,
    /* 25 */ LOOM_KEY_L,
    /* 26 */ LOOM_KEY_J,
    /* 27 */ LOOM_KEY_QUOTE,
    /* 28 */ LOOM_KEY_K,
    /* 29 */ LOOM_KEY_SEMICOLON,
    /* 2a */ LOOM_KEY_BACKSLASH,
    /* 2b */ LOOM_KEY_COMMA,
    /* 2c */ LOOM_KEY_SLASH,
    /* 2d */ LOOM_KEY_N,
    /* 2e */ LOOM_KEY_M,
    /* 2f */ LOOM_KEY_PERIOD,
    /* 30 */ LOOM_KEY_TAB,
    /* 31 */ LOOM_KEY_SPACEBAR,
    /* 32 */ LOOM_KEY_GRAVE_ACCENT_AND_TILDE,
    /* 33 */ LOOM_KEY_DELETE_OR_BACKSPACE,
    /* 34 */ -1,
    /* 35 */ LOOM_KEY_ESCAPE,
    /* 36 */ LOOM_KEY_RIGHT_GUI,
    /* 37 */ LOOM_KEY_LEFT_GUI,
    /* 38 */ LOOM_KEY_LEFT_SHIFT,
    /* 39 */ -1,
    /* 3a */ LOOM_KEY_LEFT_ALT,
    /* 3b */ LOOM_KEY_LEFT_CONTROL,
    /* 3c */ LOOM_KEY_RIGHT_SHIFT,
    /* 3d */ LOOM_KEY_RIGHT_ALT,
    /* 3e */ LOOM_KEY_RIGHT_CONTROL,
    /* 3f */ -1,
    /* 40 */ -1,
    /* 41 */ LOOM_KEY_PADPERIOD,
    /* 42 */ -1,
    /* 43 */ LOOM_KEY_PADASTERISK,
    /* 44 */ -1,
    /* 45 */ LOOM_KEY_PADPLUS,
    /* 46 */ -1,
    /* 47 */ -1,
    /* 48 */ -1,
    /* 49 */ -1,
    /* 4a */ -1,
    /* 4b */ LOOM_KEY_PADSLASH,
    /* 4c */ LOOM_KEY_PADENTER,
    /* 4d */ -1,
    /* 4e */ LOOM_KEY_PADHYPHEN,
    /* 4f */ -1,
    /* 50 */ -1,
    /* 51 */ -1,
    /* 52 */ LOOM_KEY_PAD0,
    /* 53 */ LOOM_KEY_PAD1,
    /* 54 */ LOOM_KEY_PAD2,
    /* 55 */ LOOM_KEY_PAD3,
    /* 56 */ LOOM_KEY_PAD4,
    /* 57 */ LOOM_KEY_PAD5,
    /* 58 */ LOOM_KEY_PAD6,
    /* 59 */ LOOM_KEY_PAD7,
    /* 5a */ -1,
    /* 5b */ LOOM_KEY_PAD8,
    /* 5c */ LOOM_KEY_PAD9,
    /* 5d */ -1,
    /* 5e */ -1,
    /* 5f */ -1,
    /* 60 */ LOOM_KEY_F5,
    /* 61 */ LOOM_KEY_F6,
    /* 62 */ LOOM_KEY_F7,
    /* 63 */ LOOM_KEY_F3,
    /* 64 */ LOOM_KEY_F8,
    /* 65 */ -1,
    /* 66 */ -1,
    /* 67 */ -1,
    /* 68 */ -1,
    /* 69 */ LOOM_KEY_F13,
    /* 6a */ LOOM_KEY_F16,
    /* 6b */ -1,
    /* 6c */ -1,
    /* 6d */ -1,
    /* 6e */ -1,
    /* 6f */ -1,
    /* 70 */ -1,
    /* 71 */ -1,
    /* 72 */ LOOM_KEY_HELP,
    /* 73 */ LOOM_KEY_HOME,
    /* 74 */ LOOM_KEY_PAGE_UP,
    /* 75 */ LOOM_KEY_DELETE_FORWARD,
    /* 76 */ LOOM_KEY_F4,
    /* 77 */ LOOM_KEY_END,
    /* 78 */ LOOM_KEY_F2,
    /* 79 */ LOOM_KEY_PAGE_DOWN,
    /* 7a */ LOOM_KEY_F1,
    /* 7b */ LOOM_KEY_LEFT_ARROW,
    /* 7c */ LOOM_KEY_RIGHT_ARROW,
    /* 7d */ LOOM_KEY_DOWN_ARROW,
    /* 7e */ LOOM_KEY_UP_ARROW,
    /* 7f */ -1,
};

unsigned int convertMacKeyCodeToLoomKeyCode(unsigned int keyCode)
{
    return MAC_TO_LOOM_KEYCODE[keyCode & 0x7f];
}

- (void)keyDown:(NSEvent *)theEvent
{
    unsigned short keyCode = [theEvent keyCode];
    if (keyCode == kVK_Delete)
    {
        cocos2d::CCIMEDispatcher::sharedDispatcher()->dispatchDeleteBackward();
    }
    else
    {
        NSString* str = [theEvent characters];
        const char* cstr = [str UTF8String];
        cocos2d::CCIMEDispatcher::sharedDispatcher()->dispatchInsertText(cstr, strlen(cstr));
    }

    cocos2d::CCDirector::sharedDirector()->getKeypadDispatcher()->dispatchKeypadMSG(cocos2d::kTypeKeyDown, convertMacKeyCodeToLoomKeyCode([theEvent keyCode]));
}

- (void)keyUp:(NSEvent *)theEvent
{  
	DISPATCH_EVENT(theEvent, _cmd);

    cocos2d::CCDirector::sharedDirector()->getKeypadDispatcher()->dispatchKeypadMSG(cocos2d::kTypeKeyUp, convertMacKeyCodeToLoomKeyCode([theEvent keyCode]));
	
	// pass the event along to the next responder (like your NSWindow subclass)
	[super keyUp:theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	DISPATCH_EVENT(theEvent, _cmd);
}

#pragma mark EAGLView - Touch events
- (void)touchesBeganWithEvent:(NSEvent *)theEvent
{
	DISPATCH_EVENT(theEvent, _cmd);
}

- (void)touchesMovedWithEvent:(NSEvent *)theEvent
{
	DISPATCH_EVENT(theEvent, _cmd);
}

- (void)touchesEndedWithEvent:(NSEvent *)theEvent
{
	DISPATCH_EVENT(theEvent, _cmd);
}

- (void)touchesCancelledWithEvent:(NSEvent *)theEvent
{
	DISPATCH_EVENT(theEvent, _cmd);
}
@end
