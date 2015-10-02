/* ========================================================================
   $File: $
   $Date: $
   $Revision: $
   $Creator: Jeff Buck $
   $Notice: (C) Copyright 2014. All Rights Reserved. $
   ======================================================================== */

#include <Cocoa/Cocoa.h>

#include <mach/mach_time.h>

// TODO: Implement sine ourselves
#import <math.h>

#import "handmade_platform.h"
#import "osx_handmade.h"
#import "HandmadeView.h"

static bool32 GlobalRunning;


///////////////////////////////////////////////////////////////////////
// Application Delegate

@interface HandmadeAppDelegate : NSObject<NSApplicationDelegate>
@end


@implementation HandmadeAppDelegate

- (void)applicationDidFinishLaunching:(id)sender
{
	#pragma unused(sender)

	// NOTE(jeff): Good place to do any additional initialization
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
	#pragma unused(sender)

	// NOTE(jeff): Returning NO keeps the app running, but the window is
	// still closed.
	return YES;
}

- (void)applicationWillTerminate:(NSApplication*)sender
{
	#pragma unused(sender)

	// NOTE(jeff): Called just before the app exits.
	printf("applicationWillTerminate\n");
}

@end


#if 0
@interface HandmadeApplication : NSApplication
@end


@implementation HandmadeApplication

- (void)run
{
	[[NSApplication sharedApplication] finishLaunching];

	[[NSNotificationCenter defaultCenter]
		postNotificationName:NSApplicationWillFinishLaunchingNotification
		object:NSApp];

	[[NSNotificationCenter defaultCenter]
		postNotificationName:NSApplicationDidFinishLaunchingNotification
		object:NSApp];

	while (GlobalRunning)
	{
		NSEvent* event;

		do
		{
			event = [self nextEventMatchingMask:NSAnyEventMask
									  untilDate:nil
									  	 inMode:NSDefaultRunLoopMode
										dequeue:YES];
			[self sendEvent:event];
			[self updateWindows];
		} while (event != nil);
	}
}

- (void)terminate:(id)sender
{
	GlobalRunning = false;
}

@end
#endif


void OSXCreateMainMenu()
{
	// Create the Menu. Two options right now:
	//   Toggle Full Screen
	//   Quit
	NSMenu* menubar = [NSMenu new]; 

	NSMenuItem* appMenuItem = [NSMenuItem new];
	[menubar addItem:appMenuItem];

	[NSApp setMainMenu:menubar];

	NSMenu* appMenu = [NSMenu new];

    //NSString* appName = [[NSProcessInfo processInfo] processName];
    NSString* appName = @"Handmade Hero";


    NSString* toggleFullScreenTitle = @"Toggle Full Screen";
    NSMenuItem* toggleFullScreenMenuItem = [[NSMenuItem alloc] initWithTitle:toggleFullScreenTitle
    											 action:@selector(toggleFullScreen:)
    									  keyEquivalent:@"f"];
    [appMenu addItem:toggleFullScreenMenuItem];

    NSString* quitTitle = [@"Quit " stringByAppendingString:appName];
    NSMenuItem* quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
    											 action:@selector(terminate:)
    									  keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];
}

///////////////////////////////////////////////////////////////////////
// Startup

int main(int argc, const char* argv[])
{
	#pragma unused(argc)
	#pragma unused(argv)

	//return NSApplicationMain(argc, argv);
	@autoreleasepool
	{
	NSApplication* app = [NSApplication sharedApplication];
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

	NSString *dir = [[NSFileManager defaultManager] currentDirectoryPath];
	NSLog(@"working directory: %@", dir);

	OSXCreateMainMenu();

	[app setDelegate:[[HandmadeAppDelegate alloc] init]];


	// Create the main window and the content view
	NSRect screenRect = [[NSScreen mainScreen] frame];
	float w = 960.0; // 1920.0;
	float h = 540.0; // 1080.0;
	NSRect frame = NSMakeRect((screenRect.size.width - w) * 0.5,
	                          (screenRect.size.height - h) * 0.5,
	                          w,
	                          h);

	NSWindow* window = [[NSWindow alloc] initWithContentRect:frame
										 styleMask:NSTitledWindowMask
											               | NSClosableWindowMask
											               | NSMiniaturizableWindowMask
											               | NSResizableWindowMask
										   backing:NSBackingStoreBuffered
										     defer:NO];

	HandmadeView* view = [[HandmadeView alloc] init];
	[view setFrame:[[window contentView] bounds]];
	[view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

	// NOTE(jeff): Make our view a subview of the default content view that gets created
	// with the window. You used to be able to be able to replace the default contentView
	// itself to our new view, but in Yosemite, you'll get a warning if you do that and 
	// toggle to full screen mode.
	[[window contentView] addSubview:view];
	[window setMinSize:NSMakeSize(100, 100)];
	[window setTitle:@"Handmade Hero"];
	[window makeKeyAndOrderFront:nil];


	// NOTE(jeff): You can also explicitly create your own run loop here instead of
	// calling [NSApp run], but at the moment, there's no real reason to.
	//
	// Don't call NSApplicationMain() here if you are doing everything programmatically
	// as it expects an Info.plist file and a nib to load.

	GlobalRunning = true;

	[NSApp run];
	}
}

