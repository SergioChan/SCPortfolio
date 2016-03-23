//
//  ViewController.m
//  ProjectArgosServer
//
//  Created by Fincher Justin on 16/3/22.
//  Copyright © 2016年 JustZht. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()

@property (nonatomic) CGDirectDisplayID display;
@property (nonatomic,strong) NSMutableArray *frameMutableArray;
@property (weak) IBOutlet NSImageView *screenImageView;


@property (strong,nonatomic) NSImage *screenImg;

@end

@implementation ViewController
@synthesize display;
@synthesize frameMutableArray,screenImageView,screenImg;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    display = kCGDirectMainDisplay;
    frameMutableArray = [NSMutableArray array];
    
    screenImg = [[NSImage alloc] initWithSize:NSMakeSize(1200, 900)];
    [screenImageView setImage:screenImg];
    [screenImg setCacheMode:NSImageCacheNever];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)recordButtonPressed:(id)sender
{
    [NSTimer scheduledTimerWithTimeInterval:1.0f/60.f target:self selector:@selector(createImageNSData) userInfo:nil repeats:YES];
}

- (void)createImageNSData
{
    @autoreleasepool
    {
        CGImageRef Ref = CGDisplayCreateImage(display);
        //NSData *data = (NSData *)CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(Ref)));
        screenImg = [[NSImage alloc] initWithCGImage:Ref size:CGDisplayScreenSize(display)];
        //screenImg = [image mutableCopy];
        CGImageRelease(Ref);
        CGDisplayRelease (display);
        
        
        screenImageView.image = screenImg;
        
        NSData *data = [screenImg TIFFRepresentation];
        NSLog(@"createImageNSData");
        [frameMutableArray addObject:data];
        if (frameMutableArray.count > 120.0f)
        {
            [frameMutableArray removeAllObjects];
        }
    }
    
    //    //SAVE
    //    NSData *imageData = [RefImage TIFFRepresentation];
    //    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    //    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    //    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    //    [imageData writeToFile:@"/Users/Fincher/Downloads/HAHAHA.png" atomically:NO];
}

@end
