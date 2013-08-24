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
 
#import "AppController.h"
#import "../common/AppDelegate.h"
#import "loom/engine/cocos2dx/loom/CCLoomCocos2D.h"
#include "loom/engine/bindings/loom/lmApplication.h"

extern "C"
{
  void loom_appSetup();
  void loom_appShutdown();
};

void handleGenericEvent(void *userdata, const char *type, const char *payload)
{
	// Only listen for windowResize event.
	if(strcmp(type, "windowResize"))
		return;

	// Parse the payload.
	int width=-1, height=-1;
	sscanf(payload, "%d %d", &width, &height);
	if(width == -1 || height == -1)
		return;

	AppController *ac = (AppController*)userdata;
	[ac resizeToWidth:width andHeight:height];
}

@implementation AppController

	@synthesize window, glView;

	-(void) applicationDidFinishLaunching:(NSNotification *)aNotification
	{
        
        int width = CCLoomCocos2d::getDisplayWidth();
        int height = CCLoomCocos2d::getDisplayHeight();
        const char* ccaption = CCLoomCocos2d::getDisplayCaption().c_str();
        
		// create the window
		// note that using NSResizableWindowMask causes the window to be a little
		// smaller and therefore ipad graphics are not loaded
		NSRect rect = NSMakeRect(0, 0, width, height);
		window = [[NSWindow alloc] initWithContentRect:rect
			styleMask:( NSClosableWindowMask | NSTitledWindowMask | NSResizableWindowMask )
			backing:NSBackingStoreBuffered
			defer:YES];
		
		// allocate our GL view
		// (isn't there already a shared EAGLView?)
		glView = [[EAGLView alloc] initWithFrame:rect];
		[glView initWithFrame:rect];
        
        NSString *caption = [[NSString alloc] initWithUTF8String:ccaption];

		// set window parameters
		[window becomeFirstResponder];
		[window setContentView:glView];
		[window setTitle:caption];
		[window makeKeyAndOrderFront:self];
		[window setAcceptsMouseMovedEvents:NO];

		// Initialize menu items to drive DPI/Resolution simulation.
		NSMenuItem* newItem1 = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Next Resolution" action:@selector(handleNextResClick) keyEquivalent:@"]"];
		[newItem1 setEnabled:YES];
		NSMenuItem* newItem2 = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Prev Resolution" action:@selector(handlePrevResClick) keyEquivalent:@"["];
		[newItem2 setEnabled:YES];

		NSMenu* rootMenu = [NSApp mainMenu];
		NSMenuItem* menu = [rootMenu itemWithTitle:@"View"];
		[[menu submenu] insertItem:newItem1 atIndex: [[[menu submenu] itemArray] count]]; [newItem1 release];
		[[menu submenu] insertItem:newItem2 atIndex: [[[menu submenu] itemArray] count]]; [newItem2 release];

		// set cocos2d-x's opengl view
		cocos2d::CCApplication::sharedApplication().run();

		// Listen for resize events.
		LoomApplication::listenForGenericEvents(handleGenericEvent, (void*)self);
	}

	-(void)handleNextResClick
	{
		LoomApplication::fireGenericEvent("simulator", "nextRes");
	}

	-(void)handlePrevResClick
	{
		LoomApplication::fireGenericEvent("simulator", "prevRes");
	}

	-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)theApplication
	{
		return YES;
	}

	-(void) dealloc
	{
		cocos2d::CCDirector::sharedDirector()->end();
		[super dealloc];
	}

	-(void)resizeToWidth:(int)width andHeight:(int)height
	{
		NSRect frame = [window frame];
		frame.origin.y -= frame.size.height; // remove the old height
		frame.origin.y += height; // add the new height
		frame.size.width = width;
		frame.size.height = height;
		[window setFrame: frame display: YES animate: YES];
	}

#pragma mark -
#pragma mark IB Actions

	-(IBAction) toggleFullScreen:(id)sender
	{
		EAGLView* pView = [EAGLView sharedEGLView];
		[pView setFullScreen:!pView.isFullScreen];
	}

	-(IBAction) exitFullScreen:(id)sender
	{
		[[EAGLView sharedEGLView] setFullScreen:NO];
	}

@end
