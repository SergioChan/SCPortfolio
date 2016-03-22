//
//  AppDelegate.m
//  SonOfGrabber2
//
//  Created by 叔 陈 on 16/3/18.
//  Copyright © 2016年 叔 陈. All rights reserved.
//

#import "AppDelegate.h"
#import "TestViewController.h"
#import "EventMonitor.h"
#import "WindowListApplierData.h"
#import <AVFoundation/AVFoundation.h>
#import "SCScreenRecorder.h"

@interface AppDelegate ()
{
    CGWindowListOption listOptions;
    CGWindowListOption singleWindowListOptions;
    CGWindowImageOption imageOptions;
    
    NSTimer *timer;
}

@property (strong) NSStatusItem *statusItem;
@property (strong) NSPopover *popOver;

@property (strong) EventMonitor *monitor;

@property (strong) WindowListApplierData *windowListData;
@property (strong) TestViewController *contentViewController;

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSImageView *imageView;

@property (strong) SCScreenRecorder *recorder;

@end

@implementation AppDelegate

#pragma mark Basic Profiling Tools
// Set to 1 to enable basic profiling. Profiling information is logged to console.
#ifndef PROFILE_WINDOW_GRAB
#define PROFILE_WINDOW_GRAB 0
#endif

#if PROFILE_WINDOW_GRAB
#define StopwatchStart() AbsoluteTime start = UpTime()
#define Profile(img) CFRelease(CGDataProviderCopyData(CGImageGetDataProvider(img)))
#define StopwatchEnd(caption) do { Duration time = AbsoluteDeltaToDuration(UpTime(), start); double timef = time < 0 ? time / -1000000.0 : time / 1000.0; NSLog(@"%s Time Taken: %f seconds", caption, timef); } while(0)
#else
#define StopwatchStart()
#define Profile(img)
#define StopwatchEnd(caption)
#endif

NSString *kAppNameKey = @"applicationName";	// Application Name & PID
NSString *kWindowOriginKey = @"windowOrigin";	// Window Origin as a string
NSString *kWindowSizeKey = @"windowSize";		// Window Size as a string
NSString *kWindowIDKey = @"windowID";			// Window ID
NSString *kWindowLevelKey = @"windowLevel";	// Window Level
NSString *kWindowOrderKey = @"windowOrder";	// The overall front-to-back ordering of the windows as returned by the window server

#pragma mark Utilities

// Simple helper to twiddle bits in a uint32_t.
uint32_t ChangeBits(uint32_t currentBits, uint32_t flagsToChange, BOOL setFlags);
inline uint32_t ChangeBits(uint32_t currentBits, uint32_t flagsToChange, BOOL setFlags)
{
    if(setFlags)
    {	// Set Bits
        return currentBits | flagsToChange;
    }
    else
    {	// Clear Bits
        return currentBits & ~flagsToChange;
    }
}

-(NSImage *)setOutputImage:(CGImageRef)cgImage
{
    if(cgImage != NULL)
    {
        // Create a bitmap rep from the image...
        NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
        
        CGFloat imageCompression = 0.4; //between 0 and 1; 1 is maximum quality, 0 is maximum compression
        
        // set up the options for creating a JPEG
        NSDictionary* jpegOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithDouble:imageCompression], NSImageCompressionFactor,
                                     [NSNumber numberWithBool:NO], NSImageProgressive,
                                     nil];
        
        // get the JPEG encoded data
        NSData* jpegData = [bitmapRep representationUsingType:NSJPEGFileType properties:jpegOptions];
        //write it to disk
        
        NSImage *image = [[NSImage alloc] initWithData:jpegData];
        
        // Set the output view to the new NSImage.
        return image;
    }
    else
    {
        return nil;
    }
}

void WindowListApplierFunction(const void *inputDictionary, void *context);
void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
    WindowListApplierData *data = (__bridge WindowListApplierData*)context;
    
    // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
    // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
    int sharingState = [entry[(id)kCGWindowSharingState] intValue];
    if(sharingState != kCGWindowSharingNone)
    {
        NSMutableDictionary *outputEntry = [NSMutableDictionary dictionary];
        
        // Grab the application name, but since it's optional we need to check before we can use it.
        NSString *applicationName = entry[(id)kCGWindowOwnerName];
        if(applicationName != NULL)
        {
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"%@ (%@)", applicationName, entry[(id)kCGWindowOwnerPID]];
            outputEntry[kAppNameKey] = nameAndPID;
        }
        else
        {
            // The application name was not provided, so we use a fake application name to designate this.
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"((unknown)) (%@)", entry[(id)kCGWindowOwnerPID]];
            outputEntry[kAppNameKey] = nameAndPID;
        }
        
        // Grab the Window Bounds, it's a dictionary in the array, but we want to display it as a string
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)entry[(id)kCGWindowBounds], &bounds);
        NSString *originString = [NSString stringWithFormat:@"%.0f/%.0f", bounds.origin.x, bounds.origin.y];
        outputEntry[kWindowOriginKey] = originString;
        NSString *sizeString = [NSString stringWithFormat:@"%.0f*%.0f", bounds.size.width, bounds.size.height];
        outputEntry[kWindowSizeKey] = sizeString;
        
        // Grab the Window ID & Window Level. Both are required, so just copy from one to the other
        outputEntry[kWindowIDKey] = entry[(id)kCGWindowNumber];
        outputEntry[kWindowLevelKey] = entry[(id)kCGWindowLayer];
        
        // Finally, we are passed the windows in order from front to back by the window server
        // Should the user sort the window list we want to retain that order so that screen shots
        // look correct no matter what selection they make, or what order the items are in. We do this
        // by maintaining a window order key that we'll apply later.
        outputEntry[kWindowOrderKey] = @(data.order);
        data.order++;
        
        [data.outputArray addObject:outputEntry];
    }
}

- (NSRect)screenRect
{
    NSRect screenRect;
    NSArray *screenArray = [NSScreen screens];
    NSScreen *screen = [screenArray objectAtIndex: 0];
    screenRect = [screen visibleFrame];
    
    return screenRect;
}

-(void)createScreenShot
{
    // This just invokes the API as you would if you wanted to grab a screen shot. The equivalent using the UI would be to
    // enable all windows, turn off "Fit Image Tightly", and then select all windows in the list.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        StopwatchStart();
        CGImageRef screenShot = CGWindowListCreateImage(CGRectMake(0.0f, 0.0f, [self screenRect].size.width, [self screenRect].size.height), kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault |kCGWindowImageNominalResolution);
        Profile(screenShot);
        StopwatchEnd("Screenshot");
        NSImage *image = [self setOutputImage:screenShot];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
            NSData *imageData = [image TIFFRepresentationUsingCompression:NSTIFFCompressionJPEG factor:0.5f];
            NSLog(@"size : %ld",imageData.length);
        });
        CGImageRelease(screenShot);
    });
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:-2];
    self.statusItem.button.image = [NSImage imageNamed:@"ButtonImage"];
    [self.statusItem.button setAction:@selector(fuck:)];
    
    NSMenu *menu = [[NSMenu alloc]init];
    
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"显示主界面" action:@selector(showRecordScreen:) keyEquivalent:@""]];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"开始录制" action:@selector(beginRecordScreen:) keyEquivalent:@""]];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"停止录制" action:@selector(endRecordScreen:) keyEquivalent:@""]];
    
    self.statusItem.menu = menu;
    self.recorder = [[SCScreenRecorder alloc] init];
    
//    self.popOver = [[NSPopover alloc] init];
//    self.contentViewController = [[TestViewController alloc] initWithNibName:@"TestViewController" bundle:nil];
//    _popOver.contentViewController = self.contentViewController;
//
//    self.monitor = [[EventMonitor alloc] initWithMask:(NSLeftMouseDownMask | NSRightMouseDownMask) handler:^(NSEvent *event) {
//        if (_popOver.shown) {
//            [self closePopOver:event];
//        }
//    }];
//    
//    [self.monitor start];
    
//    [[NSApplication sharedApplication] setPresentationOptions:NSApplicationPresentationDisableCursorLocationAssistance];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WindowWillMove:) name:NSWindowDidEnterFullScreenNotification object:nil];
}

- (void)showRecordScreen:(id)sender
{
    if(self.window) {
        [NSApp activateIgnoringOtherApps:YES];
        [self.window makeKeyAndOrderFront:nil];
    }
}

- (void)beginRecordScreen:(id)sender
{
//    timer = [NSTimer scheduledTimerWithTimeInterval:0.02f target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
//    [timer fire];
    [self.recorder start];
}

- (void)endRecordScreen:(id)sender
{
//    [timer invalidate];
//    timer = nil;
    [self.recorder stop];
}

- (void)timerUpdate:(id)sender
{
    [self createScreenShot];
}

- (void)WindowWillMove:(NSNotification *)notif
{
    NSLog(@"%@",notif);
    
    if ([NSStringFromClass([notif.object class]) isEqualToString:@"NSStatusBarWindow"]) {
        NSWindow *window = notif.object;
        NSLog(@"%f,%f,%f,%f",window.contentLayoutRect.origin.x,window.contentLayoutRect.origin.y,window.contentLayoutRect.size.height,window.contentLayoutRect.size.width);
        
        //[_popOver close];
    }
}

- (void)fuck:(id)sender
{
    if(_popOver.shown) {
        [self closePopOver:sender];
    } else {
        [self.monitor start];
        
        timer = [NSTimer scheduledTimerWithTimeInterval:0.02f target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
        [timer fire];
        
        [_popOver showRelativeToRect:_statusItem.button.bounds ofView:_statusItem.button preferredEdge:NSRectEdgeMinY];
    }
}

- (void)closePopOver:(id)sender
{
    [_popOver performClose:sender];
    [self.monitor stop];
    [timer invalidate];
    timer = nil;
    
//    [NSEvent removeMonitor:self.monitor];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
