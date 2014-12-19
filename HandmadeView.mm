/* ========================================================================
   $File: $
   $Date: $
   $Revision: $
   $Creator: Jeff Buck $
   $Notice: (C) Copyright 2014. All Rights Reserved. $
   ======================================================================== */

/*
	TODO(jeff): THIS IS NOT A FINAL PLATFORM LAYER!!!

	This will be updated to keep parity with Casey's win32 platform layer.
	See his win32_handmade.cpp file for TODO details.
*/


#include <Cocoa/Cocoa.h>

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>
#import <CoreVideo/CVDisplayLink.h>

#import <AudioUnit/AudioUnit.h>
#import <IOKit/hid/IOHIDLib.h>

#include <sys/stat.h>

#include <mach/mach_time.h>

#include "handmade.h"
#include "osx_handmade.h"
#include "HandmadeView.h"


//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wnull-dereference"
//#pragma clang diagnostic ignored "-Wc++11-compat-deprecated-writable-strings"
//#pragma clang diagnostic pop


global_variable AudioUnit	GlobalAudioUnit;
global_variable double		GlobalAudioUnitRenderPhase;

global_variable Float64		GlobalFrequency = 800.0;
global_variable Float64		GlobalSampleRate = 48000.0;



#define MAX_HID_BUTTONS 32

// TODO(jeff): Temporary NSObject for testing.
// Replace with simple struct in a set of hash tables.
@interface HandmadeHIDElement : NSObject
{
@public
	long	type;
	long	page;
	long	usage;
	long	min;
	long	max;
};

- (id)initWithType:(long)type usagePage:(long)p usage:(long)u min:(long)n max:(long)x;

@end


@interface HandmadeView ()
{
@public
	// display
	CVDisplayLinkRef			_displayLink;
	
	// graphics
	NSDictionary*				_fullScreenOptions;
	GLuint						_textureId;
	
	// input
	IOHIDManagerRef				_hidManager;
	int							_hidX;
	int							_hidY;
	uint8						_hidButtons[MAX_HID_BUTTONS];

	char _sourceGameCodeDLFullPath[OSX_STATE_FILENAME_COUNT];
	char _tempGameCodeDLFullPath[OSX_STATE_FILENAME_COUNT];

	game_memory					_gameMemory;
	game_sound_output_buffer	_soundBuffer;
	game_offscreen_buffer		_renderBuffer;

	osx_state					_osxState;
	osx_game_code				_game;

	real64						_machTimebaseConversionFactor;
	BOOL						_setupComplete;

	// TODO(jeff): Replace with set of simple hash tables of structs
	NSMutableDictionary*		_elementDictionary;
}
@end

OSStatus SineWaveRenderCallback(void * inRefCon,
                                AudioUnitRenderActionFlags * ioActionFlags,
                                const AudioTimeStamp * inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList * ioData)
{
	#pragma unused(ioActionFlags)
	#pragma unused(inTimeStamp)
	#pragma unused(inBusNumber)

	double currentPhase = *((double*)inRefCon);
	Float32* outputBuffer = (Float32 *)ioData->mBuffers[0].mData;
	const double phaseStep = (GlobalFrequency / GlobalSampleRate) * (2.0 * M_PI);

	for (UInt32 i = 0; i < inNumberFrames; i++)
	{
		outputBuffer[i] = 0.7 * sin(currentPhase);
		currentPhase += phaseStep;
	}

	// Copy to the stereo (or the additional X.1 channels)
	for(UInt32 i = 1; i < ioData->mNumberBuffers; i++)
	{
		memcpy(ioData->mBuffers[i].mData, outputBuffer, ioData->mBuffers[i].mDataByteSize);
	}

	*((double *)inRefCon) = currentPhase;

	return noErr;
}


void OSXInitCoreAudio()
{
	AudioComponentDescription acd;
	acd.componentType         = kAudioUnitType_Output;
	acd.componentSubType      = kAudioUnitSubType_DefaultOutput;
	acd.componentManufacturer = kAudioUnitManufacturer_Apple;

	AudioComponent outputComponent = AudioComponentFindNext(NULL, &acd);

	AudioComponentInstanceNew(outputComponent, &GlobalAudioUnit);
	AudioUnitInitialize(GlobalAudioUnit);

	// NOTE(jeff): Make this stereo
	AudioStreamBasicDescription asbd;
	asbd.mSampleRate       = GlobalSampleRate;
	asbd.mFormatID         = kAudioFormatLinearPCM;
	asbd.mFormatFlags      = kAudioFormatFlagsNativeFloatPacked;
	asbd.mChannelsPerFrame = 1;
	asbd.mFramesPerPacket  = 1;
	asbd.mBitsPerChannel   = 1 * sizeof(Float32) * 8;
	asbd.mBytesPerPacket   = 1 * sizeof(Float32);
	asbd.mBytesPerFrame    = 1 * sizeof(Float32);

	// TODO(jeff): Add some error checking...
	AudioUnitSetProperty(GlobalAudioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         0,
                         &asbd,
                         sizeof(asbd));

	AURenderCallbackStruct cb;
	cb.inputProc       = SineWaveRenderCallback;
	cb.inputProcRefCon = &GlobalAudioUnitRenderPhase;

	AudioUnitSetProperty(GlobalAudioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Global,
                         0,
                         &cb,
                         sizeof(cb));

	AudioOutputUnitStart(GlobalAudioUnit);
}


void OSXStopCoreAudio()
{
	NSLog(@"Stopping Core Audio");
	AudioOutputUnitStop(GlobalAudioUnit);
	AudioUnitUninitialize(GlobalAudioUnit);
	AudioComponentInstanceDispose(GlobalAudioUnit);
}


void OSXHIDAdded(void* context, IOReturn result, void* sender, IOHIDDeviceRef device)
{
	#pragma unused(context)
	#pragma unused(result)
	#pragma unused(sender)
	#pragma unused(device)

	HandmadeView* view = (__bridge HandmadeView*)context;

	//IOHIDManagerRef mr = (IOHIDManagerRef)sender;

	CFStringRef manufacturerCFSR = (CFStringRef)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDManufacturerKey));
	CFStringRef productCFSR = (CFStringRef)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));

	NSLog(@"Gamepad was detected: %@ %@", (__bridge NSString*)manufacturerCFSR, (__bridge NSString*)productCFSR);

	NSArray *elements = (__bridge_transfer NSArray *)IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone);

	for (id element in elements)
	{
		IOHIDElementRef tIOHIDElementRef = (__bridge IOHIDElementRef)element;

		IOHIDElementType tIOHIDElementType = IOHIDElementGetType(tIOHIDElementRef);

		switch(tIOHIDElementType)
		{
			case kIOHIDElementTypeInput_Misc:
			{
				printf("[misc] ");
				break;
			}

			case kIOHIDElementTypeInput_Button:
			{
				printf("[button] ");
				break;
			}

			case kIOHIDElementTypeInput_Axis:
			{
				printf("[axis] ");
				break;
			}

			case kIOHIDElementTypeInput_ScanCodes:
			{
				printf("[scancode] ");
				break;
			}
			default:
				continue;
		}

		uint32_t reportSize = IOHIDElementGetReportSize(tIOHIDElementRef);
		uint32_t reportCount = IOHIDElementGetReportCount(tIOHIDElementRef);
		if ((reportSize * reportCount) > 64)
		{
			continue;
		}

		uint32_t usagePage = IOHIDElementGetUsagePage(tIOHIDElementRef);
		uint32_t usage = IOHIDElementGetUsage(tIOHIDElementRef);
		if (!usagePage || !usage)
		{
			continue;
		}
		if (-1 == usage)
		{
			continue;
		}

		CFIndex logicalMin = IOHIDElementGetLogicalMin(tIOHIDElementRef);
		CFIndex logicalMax = IOHIDElementGetLogicalMax(tIOHIDElementRef);

		printf("page/usage = %d:%d  min/max = (%ld, %ld)\n", usagePage, usage, logicalMin, logicalMax);

		// TODO(jeff): Change NSDictionary to a simple hash table.
		// TODO(jeff): Add a hash table for each controller. Use cookies for ID.
		// TODO(jeff): Change HandmadeHIDElement to a simple struct.
		HandmadeHIDElement* e = [[HandmadeHIDElement alloc] initWithType:tIOHIDElementType
															   usagePage:usagePage
																   usage:usage
																	 min:logicalMin
																	 max:logicalMax];
		long key = (usagePage << 16) | usage;

		[view->_elementDictionary setObject:e forKey:[NSNumber numberWithLong:key]];
	}
}

void OSXHIDRemoved(void* context, IOReturn result, void* sender, IOHIDDeviceRef device)
{
	#pragma unused(context)
	#pragma unused(result)
	#pragma unused(sender)
	#pragma unused(device)

	NSLog(@"Gamepad was unplugged");
}

void OSXHIDAction(void* context, IOReturn result, void* sender, IOHIDValueRef value)
{
	#pragma unused(result)
	#pragma unused(sender)

	// NOTE(jeff): Check suggested by Filip to prevent an access violation when
	// using a PS3 controller.
	// TODO(jeff): Investigate this further...
	if (IOHIDValueGetLength(value) > 2)
	{
		//NSLog(@"OSXHIDAction: value length > 2: %ld", IOHIDValueGetLength(value));
		return;
	}

	IOHIDElementRef element = IOHIDValueGetElement(value);
	if (CFGetTypeID(element) != IOHIDElementGetTypeID())
	{
		return;
	}

	//IOHIDElementCookie cookie = IOHIDElementGetCookie(element);
	//IOHIDElementType type = IOHIDElementGetType(element);
	//CFStringRef name = IOHIDElementGetName(element);
	int usagePage = IOHIDElementGetUsagePage(element);
	int usage = IOHIDElementGetUsage(element);

	CFIndex elementValue = IOHIDValueGetIntegerValue(value);

	// NOTE(jeff): This is the pointer back to our view
	HandmadeView* view = (__bridge HandmadeView*)context;

	// NOTE(jeff): This is just for reference. From the USB HID Usage Tables spec:
	// Usage Pages:
	//   1 - Generic Desktop (mouse, joystick)
	//   2 - Simulation Controls
	//   3 - VR Controls
	//   4 - Sports Controls
	//   5 - Game Controls
	//   6 - Generic Device Controls (battery, wireless, security code)
	//   7 - Keyboard/Keypad
	//   8 - LED
	//   9 - Button
	//   A - Ordinal
	//   B - Telephony
	//   C - Consumer
	//   D - Digitizers
	//  10 - Unicode
	//  14 - Alphanumeric Display
	//  40 - Medical Instrument

	if (usagePage == 1) // Generic Desktop Page
	{
		int hatDelta = 16;

		NSNumber* key = [NSNumber numberWithLong:((usagePage << 16) | usage)];
		HandmadeHIDElement* e = [view->_elementDictionary objectForKey:key];

		float normalizedValue = 0.0;
		if (e->max != e->min)
		{
			normalizedValue = (float)(elementValue - e->min) / (float)(e->max - e->min);
		}
		float scaledMin = -25.0;
		float scaledMax = 25.0;

		int scaledValue = scaledMin + normalizedValue * (scaledMax - scaledMin);

		//printf("page:usage = %d:%d  value = %ld  ", usagePage, usage, elementValue);
		switch(usage)
		{
			case 0x30: // x
				view->_hidX = scaledValue;
				//printf("[x] scaled = %d\n", view->_hidX);
				break;

			case 0x31: // y
				view->_hidY = scaledValue;
				//printf("[y] scaled = %d\n", view->_hidY);
				break;

			case 0x32: // z
				//view->_hidX = scaledValue;
				//printf("[z] scaled = %d\n", view->_hidX);
				break;

			case 0x35: // rz
				//view->_hidY = scaledValue;
				//printf("[rz] scaled = %d\n", view->_hidY);
				break;

			case 0x39: // Hat 0 = up, 2 = right, 4 = down, 6 = left, 8 = centered
			{
				printf("[hat] ");
				switch(elementValue)
				{
					case 0:
						view->_hidX = 0;
						view->_hidY = -hatDelta;
						printf("n\n");
						break;

					case 1:
						view->_hidX = hatDelta;
						view->_hidY = -hatDelta;
						printf("ne\n");
						break;

					case 2:
						view->_hidX = hatDelta;
						view->_hidY = 0;
						printf("e\n");
						break;

					case 3:
						view->_hidX = hatDelta;
						view->_hidY = hatDelta;
						printf("se\n");
						break;

					case 4:
						view->_hidX = 0;
						view->_hidY = hatDelta;
						printf("s\n");
						break;

					case 5:
						view->_hidX = -hatDelta;
						view->_hidY = hatDelta;
						printf("sw\n");
						break;

					case 6:
						view->_hidX = -hatDelta;
						view->_hidY = 0;
						printf("w\n");
						break;

					case 7:
						view->_hidX = -hatDelta;
						view->_hidY = -hatDelta;
						printf("nw\n");
						break;

					case 8:
						view->_hidX = 0;
						view->_hidY = 0;
						printf("up\n");
						break;
				}

			} break;

			default:
				//NSLog(@"Gamepad Element: %@  Type: %d  Page: %d  Usage: %d  Name: %@  Cookie: %i  Value: %ld  _hidX: %d",
				//      element, type, usagePage, usage, name, cookie, elementValue, view->_hidX);
				break;
		}
	}
	else if (usagePage == 7) // Keyboard
	{
		// NOTE(jeff): usages 0-3:
		//   0 - Reserved
		//   1 - ErrorRollOver
		//   2 - POSTFail
		//   3 - ErrorUndefined
		// Ignore them for now...
		if (usage < 4) return;

		NSString* keyName = @"";

		// TODO(jeff): Store the keyboard events somewhere...

		bool isDown = elementValue;

		switch(usage)
		{
			case kHIDUsage_KeyboardW:
				keyName = @"w";
				break;

			case kHIDUsage_KeyboardA:
				keyName = @"a";
				break;

			case kHIDUsage_KeyboardS:
				keyName = @"s";
				break;

			case kHIDUsage_KeyboardD:
				keyName = @"d";
				break;

			case kHIDUsage_KeyboardQ:
				keyName = @"q";
				break;

			case kHIDUsage_KeyboardE:
				keyName = @"e";
				break;

			case kHIDUsage_KeyboardSpacebar:
				keyName = @"Space";
				break;

			case kHIDUsage_KeyboardEscape:
				keyName = @"ESC";
				break;

			case kHIDUsage_KeyboardUpArrow:
				keyName = @"Up";
				break;

			case kHIDUsage_KeyboardLeftArrow:
				keyName = @"Left";
				break;

			case kHIDUsage_KeyboardDownArrow:
				keyName = @"Down";
				break;

			case kHIDUsage_KeyboardRightArrow:
				keyName = @"Right";
				break;

			case kHIDUsage_KeyboardL:
				if (isDown)
				{
					if (view->_osxState.InputRecordingIndex == 0)
					{
						OSXBeginRecordingInput(&view->_osxState, 1);
					}
					else
					{
						OSXEndRecordingInput(&view->_osxState);
						OSXBeginInputPlayback(&view->_osxState, 1);
					}
				}
				break;

			default:
				return;
				break;
		}
		if (elementValue == 1)
		{
			NSLog(@"%@ pressed", keyName);
		}
		else if (elementValue == 0)
		{
			NSLog(@"%@ released", keyName);
		}
	}
	else if (usagePage == 9) // Buttons
	{
		if (elementValue == 1)
		{
			view->_hidButtons[usage] = 1;
			NSLog(@"Button %d pressed", usage);
		}
		else if (elementValue == 0)
		{
			view->_hidButtons[usage] = 0;
			NSLog(@"Button %d released", usage);
		}
		else
		{
			//NSLog(@"Gamepad Element: %@  Type: %d  Page: %d  Usage: %d  Name: %@  Cookie: %i  Value: %ld  _hidX: %d",
			//	  element, type, usagePage, usage, name, cookie, elementValue, view->_hidX);
		}
	}
	else
	{
		//NSLog(@"Gamepad Element: %@  Type: %d  Page: %d  Usage: %d  Name: %@  Cookie: %i  Value: %ld  _hidX: %d",
		//	  element, type, usagePage, usage, name, cookie, elementValue, view->_hidX);
	}
}


@implementation HandmadeHIDElement

- (id)initWithType:(long)t usagePage:(long)p usage:(long)u min:(long)n max:(long)x
{
	self = [super init];

	if (!self) return nil;

	type = t;
	page = p;
	usage = u;
	min = n;
	max = x;

	return self;
}

@end



@implementation HandmadeView

-(void)setupGamepad
{
	_hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);

	if (_hidManager)
	{
		// NOTE(jeff): We're asking for Joysticks, GamePads, Multiaxis Controllers
		// and Keyboards
		NSArray* criteria = @[ @{ [NSString stringWithUTF8String:kIOHIDDeviceUsagePageKey]:
									[NSNumber numberWithInt:kHIDPage_GenericDesktop],
								[NSString stringWithUTF8String:kIOHIDDeviceUsageKey]:
									[NSNumber numberWithInt:kHIDUsage_GD_Joystick]
								},
							@{ (NSString*)CFSTR(kIOHIDDeviceUsagePageKey):
									[NSNumber numberWithInt:kHIDPage_GenericDesktop],
								(NSString*)CFSTR(kIOHIDDeviceUsageKey):
									[NSNumber numberWithInt:kHIDUsage_GD_GamePad]
								},
							@{ (NSString*)CFSTR(kIOHIDDeviceUsagePageKey):
									[NSNumber numberWithInt:kHIDPage_GenericDesktop],
								(NSString*)CFSTR(kIOHIDDeviceUsageKey):
									[NSNumber numberWithInt:kHIDUsage_GD_MultiAxisController]
							   }
#if 1
							   ,
							@{ (NSString*)CFSTR(kIOHIDDeviceUsagePageKey):
									[NSNumber numberWithInt:kHIDPage_GenericDesktop],
								(NSString*)CFSTR(kIOHIDDeviceUsageKey):
									[NSNumber numberWithInt:kHIDUsage_GD_Keyboard]
							   }
#endif
							];

		// NOTE(jeff): These all return void, so no error checking...
		IOHIDManagerSetDeviceMatchingMultiple(_hidManager, (__bridge CFArrayRef)criteria);
		IOHIDManagerRegisterDeviceMatchingCallback(_hidManager, OSXHIDAdded, (__bridge void*)self);
		IOHIDManagerRegisterDeviceRemovalCallback(_hidManager, OSXHIDRemoved, (__bridge void*)self);
		IOHIDManagerScheduleWithRunLoop(_hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

		if (IOHIDManagerOpen(_hidManager, kIOHIDOptionsTypeNone) == kIOReturnSuccess)
		{
			IOHIDManagerRegisterInputValueCallback(_hidManager, OSXHIDAction, (__bridge void*)self);
		}
		else
		{
			// TODO(jeff): Diagnostic
		}
	}
	else
	{
		// TODO(jeff): Diagnostic
	}
}


- (CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime
{
	// NOTE(jeff): We'll probably use this outputTime later for more precise
	// drawing, but ignore it for now
	#pragma unused(outputTime)

    @autoreleasepool
    {
		[self processFrame:NO];
    }

    return kCVReturnSuccess;
}


// Renderer callback function
static CVReturn GLXViewDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                           const CVTimeStamp* now,
                                           const CVTimeStamp* outputTime,
                                           CVOptionFlags inFlags,
                                           CVOptionFlags* outFlags,
                                           void* displayLinkContext)
{
	#pragma unused(displayLink)
	#pragma unused(now)
	#pragma unused(inFlags)
	#pragma unused(outFlags)

    CVReturn result = [(__bridge HandmadeView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}


- (void)setup
{
	if (_setupComplete)
	{
		return;
	}

	// TODO(jeff): Remove this
	_elementDictionary = [[NSMutableDictionary alloc] init];


	///////////////////////////////////////////////////////////////////
	// Get the game shared library paths

	OSXGetAppFilename(&_osxState);

	OSXBuildAppPathFilename(&_osxState, (char*)"libhandmade.so",
	                        sizeof(_sourceGameCodeDLFullPath), _sourceGameCodeDLFullPath);

	OSXBuildAppPathFilename(&_osxState, (char*)"libhandmade_temp.so",
	                        sizeof(_tempGameCodeDLFullPath), _tempGameCodeDLFullPath);

	_game = OSXLoadGameCode(_sourceGameCodeDLFullPath,
	                        _tempGameCodeDLFullPath);


	///////////////////////////////////////////////////////////////////
	// Set up memory

#if HANDMADE_INTERNAL
	char* RequestedAddress = (char*)Gigabytes(8);
#else
	char* RequestedAddress = (char*)0;
#endif

	_gameMemory.PermanentStorageSize = Megabytes(64);
	_gameMemory.TransientStorageSize = Gigabytes(1);
	_gameMemory.DEBUGPlatformFreeFileMemory = DEBUGPlatformFreeFileMemory;
	_gameMemory.DEBUGPlatformReadEntireFile = DEBUGPlatformReadEntireFile;
	_gameMemory.DEBUGPlatformWriteEntireFile = DEBUGPlatformWriteEntireFile;

	_osxState.TotalSize = _gameMemory.PermanentStorageSize + _gameMemory.TransientStorageSize;

#ifdef HANDMADE_USE_VM_ALLOCATE
	kern_return_t result = vm_allocate((vm_map_t)mach_task_self(),
									   (vm_address_t*)&_osxState.GameMemoryBlock,
									   _osxState.TotalSize,
									   VM_FLAGS_ANYWHERE);
	if (result != KERN_SUCCESS)
	{
		// TODO(jeff): Diagnostic
		NSLog(@"Error allocating memory");
	}
#else

	_osxState.GameMemoryBlock = mmap(RequestedAddress, _osxState.TotalSize,
	                                 PROT_READ|PROT_WRITE,
	                                 MAP_PRIVATE|MAP_FIXED|MAP_ANON,
	                                 -1, 0);
	if (_osxState.GameMemoryBlock == MAP_FAILED)
	{
		printf("mmap error: %d  %s", errno, strerror(errno));
	}
#endif

	_gameMemory.PermanentStorage = _osxState.GameMemoryBlock;
	_gameMemory.TransientStorage = ((uint8*)_gameMemory.PermanentStorage
								   + _gameMemory.PermanentStorageSize);


	// Get the conversion factor for doing profile timing with mach_absolute_time()
	mach_timebase_info_data_t timebase;
	mach_timebase_info(&timebase);
	_machTimebaseConversionFactor = (double)timebase.numer / (double)timebase.denom;
	
	[self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFADoubleBuffer,
        //NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };
    NSOpenGLPixelFormat* pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

    if (pf == nil)
    {
        NSLog(@"No OpenGL pixel format");
    }

    NSOpenGLContext* context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    [self setPixelFormat:pf];
    [self setOpenGLContext:context];

	_fullScreenOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
													 forKey:NSFullScreenModeSetting];

	int BytesPerPixel = 4;
	_renderBuffer.Width = 800;
	_renderBuffer.Height = 600;
	_renderBuffer.Memory = (uint8*)malloc(_renderBuffer.Width * _renderBuffer.Height * 4);
	_renderBuffer.Pitch = _renderBuffer.Width * BytesPerPixel;
	_renderBuffer.BytesPerPixel = BytesPerPixel;


	[self setupGamepad];

	OSXInitCoreAudio();

	_setupComplete = YES;
}


- (id)init
{
	self = [super init];

	if (self == nil)
	{
		return nil;
	}

	[self setup];

	return self;
}


- (void)awakeFromNib
{
	[self setup];
}


- (void)prepareOpenGL
{
    [super prepareOpenGL];

    [[self openGLContext] makeCurrentContext];

    // NOTE(jeff): Use the vertical refresh rate to sync buffer swaps
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    glGenTextures(1, &_textureId);
    glBindTexture(GL_TEXTURE_2D, _textureId);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _renderBuffer.Width, _renderBuffer.Height,
				 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, NULL);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE /*GL_MODULATE*/);

    CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
    CVDisplayLinkSetOutputCallback(_displayLink, &GLXViewDisplayLinkCallback, (__bridge void *)(self));

    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, cglContext, cglPixelFormat);

    CVDisplayLinkStart(_displayLink);
}


- (void)reshape
{
    [super reshape];

	[self processFrame:YES];
}


- (void)processFrame:(BOOL)resize
{
	// NOTE(jeff): Drawing is normally done on a background thread via CVDisplayLink.
	// When the window/view is resized, reshape is called automatically on the
	// main thread, so lock the context from simultaneous access during a resize.

	// TODO(jeff): Tighten up this GLContext lock
	CGLLockContext([[self openGLContext] CGLContextObj]);


	///////////////////////////////////////////////////////////////////
	// Check for updated game code

	time_t NewDLWriteTime = OSXGetLastWriteTime(_sourceGameCodeDLFullPath);
	if (NewDLWriteTime != _game.DLLastWriteTime)
	{
		OSXUnloadGameCode(&_game);
		_game = OSXLoadGameCode(_sourceGameCodeDLFullPath,
		                        _tempGameCodeDLFullPath);
	}

	uint64 LastCycleCount = rdtsc();
	uint64 StartTime = mach_absolute_time();

	if (resize)
	{
		// NOTE(jeff): Don't run the game update logic during resize events
		NSRect rect = [self bounds];

		glDisable(GL_DEPTH_TEST);
		glLoadIdentity();
		glViewport(0, 0, rect.size.width, rect.size.height);
	}
	else
	{
		// NOTE(jeff): Not a resize, render the next frame

		// TODO(jeff): Fix this for multiple controllers
		local_persist game_input Input[2] = {};
		local_persist game_input* NewInput = &Input[0];
		local_persist game_input* OldInput = &Input[1];

		game_controller_input* OldController = &OldInput->Controllers[0];
		game_controller_input* NewController = &NewInput->Controllers[0];

		NewController->IsAnalog = true;
		NewController->StickAverageX = _hidX;
		NewController->StickAverageY = _hidY;

		NewController->ActionDown.EndedDown = _hidButtons[1];
		NewController->ActionUp.EndedDown = _hidButtons[2];
		NewController->ActionLeft.EndedDown = _hidButtons[3];
		NewController->ActionRight.EndedDown = _hidButtons[4];


		if (_osxState.InputRecordingIndex)
		{
			OSXRecordInput(&_osxState, NewInput);
		}

		if (_osxState.InputPlayingIndex)
		{
			OSXPlaybackInput(&_osxState, NewInput);
		}

		if (_game.UpdateAndRender)
		{
			_game.UpdateAndRender(&_gameMemory, NewInput, &_renderBuffer);
		}


		// TODO(jeff): Move this into the sound render code
		GlobalFrequency = 440.0 + (15 * _hidY);

		game_input* Temp = NewInput;
		NewInput = OldInput;
		OldInput = Temp;
	}


	///////////////////////////////////////////////////////////////////
	// Draw the latest frame to the screen

	[[self openGLContext] makeCurrentContext];
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	GLfloat vertices[] =
	{
		-1, 1, 0,
		-1, -1, 0,
		1, -1, 0,
		1, 1, 0
	};

	GLfloat tex_coords[] =
	{
		0, 1,
		0, 0,
		1, 0,
		1, 1,
	};

    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, tex_coords);

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glBindTexture(GL_TEXTURE_2D, _textureId);

    glEnable(GL_TEXTURE_2D);
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _renderBuffer.Width, _renderBuffer.Height,
					GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, _renderBuffer.Memory);
	
    GLushort indices[] = { 0, 1, 2, 0, 2, 3 };
    glColor4f(1,1,1,1);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices);
    glDisable(GL_TEXTURE_2D);

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);

    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);

	
	///////////////////////////////////////////////////////////////////
	// Update performance counters

	uint64 EndCycleCount = rdtsc();
	uint64 EndTime = mach_absolute_time();
	
	//uint64 CyclesElapsed = EndCycleCount - LastCycleCount;
	
	real64 MSPerFrame = (real64)(EndTime - StartTime) * _machTimebaseConversionFactor / 1.0E6;
	real64 SPerFrame = MSPerFrame / 1000.0;
	//real64 FPS = 1.0 / SPerFrame;
	
	// NSLog(@"%.02fms/f,  %.02ff/s", MSPerFrame, FPS);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)dealloc
{
	OSXStopCoreAudio();

	// NOTE(jeff): It's a good idea to stop the display link before
	// anything in the view is released. Otherwise, the display link
	// might try calling into the view for an update after the view's
	// memory is released.
    CVDisplayLinkStop(_displayLink);
    CVDisplayLinkRelease(_displayLink);

    //[super dealloc];
}
#pragma clang diagnostic pop


- (void)toggleFullScreen:(id)sender
{
	#pragma unused(sender)

	if ([self isInFullScreenMode])
	{
		[self exitFullScreenModeWithOptions:_fullScreenOptions];
		[[self window] makeFirstResponder:self];
	}
	else
	{
		[self enterFullScreenMode:[NSScreen mainScreen]
					  withOptions:_fullScreenOptions];
	}
}


- (BOOL) acceptsFirstResponder
{
	return YES;
}


- (BOOL) becomeFirstResponder
{
	return  YES;
}


- (BOOL) resignFirstResponder
{
	return YES;
}

@end


