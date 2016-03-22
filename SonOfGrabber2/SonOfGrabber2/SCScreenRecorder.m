//
//  SCScreenRecorder.m
//  SonOfGrabber2
//
//  Created by 叔 陈 on 16/3/22.
//  Copyright © 2016年 叔 陈. All rights reserved.
//

#import "SCScreenRecorder.h"

@implementation SCScreenRecorder

@synthesize session;
@synthesize input;
@synthesize output;
@synthesize file;

- (id) init {
    self = [super init];
    if (self) {
        self.session = [[AVCaptureSession alloc] init];
        //  self.session.sessionPreset = AVCaptureSessionPreset1280x720;
        
        self.input   = [[AVCaptureScreenInput alloc] initWithDisplayID:CGMainDisplayID()];
        self.input.capturesMouseClicks = YES;
        
        self.output  = [[AVCaptureMovieFileOutput alloc] init];
        [self.output setDelegate:self];
        
        [self.session addInput:self.input];
        [self.session addOutput:self.output];
    }
    return self;
}

- (BOOL) start {
    static NSDateFormatter* formatter;
    static NSURL*           homeDir;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYYMMDDHHmmss"];
        
        homeDir = [NSURL fileURLWithPath:[@"~/Movies/" stringByExpandingTildeInPath]];
    });
    
    NSString* date = [formatter stringFromDate:[NSDate date]];
    self.file      = [[homeDir URLByAppendingPathComponent:[@"Fuck-" stringByAppendingString:date]] URLByAppendingPathExtension:@"mov"];
    
    [self.session startRunning];
//    [self.output  startRecordingToOutputFileURL:self.file
//                              recordingDelegate:self];
    
    return YES;
}

- (BOOL) toggle {
    if (self.output.recordingPaused) {
        [self.output resumeRecording];
        return YES;
    }
    
    [self.output pauseRecording];
    return NO;
}

- (BOOL) stop {
    [self.session stopRunning];
    [self.output  stopRecording];
    return YES;
}


#pragma mark AVCaptureFileOutputDelegate

- (BOOL)captureOutputShouldProvideSampleAccurateRecordingStart:(AVCaptureOutput *)captureOutput {
    return YES;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CGImageRef cgImage = [self imageFromSampleBuffer:sampleBuffer];
    
//    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
//    
//    CGFloat imageCompression = 0.4; //between 0 and 1; 1 is maximum quality, 0 is maximum compression
//    
//    // set up the options for creating a JPEG
//    NSDictionary* jpegOptions = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSNumber numberWithDouble:imageCompression], NSImageCompressionFactor,
//                                 [NSNumber numberWithBool:NO], NSImageProgressive,
//                                 nil];
//    
//    NSData* jpegData = [bitmapRep representationUsingType:NSJPEGFileType properties:jpegOptions];
//    //    NSData *jpegData = imageToBuffer(sampleBuffer);
//    
//    NSLog(@"fuck length:%ld",jpegData.length);
//    
}


#pragma mark AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections error:(NSError *)error {
}

- (CGImageRef) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
    CMBlockBufferRef imageBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    
    CFArrayRef fuck = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    
    NSLog(@"%@",fuck);
//    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
//    
//    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    size_t width = CVPixelBufferGetWidth(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    
//    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
//    CGContextRelease(newContext);
//    
//    CGColorSpaceRelease(colorSpace);
//    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    /* CVBufferRelease(imageBuffer); */  // do not call this!
    
    size_t lengthAtOffset;
    size_t totalLength;
    char* data;

    CFRetain(imageBuffer);
    
    if(CMBlockBufferGetDataPointer(imageBuffer, 0, &lengthAtOffset, &totalLength, &data ) != noErr )
    {
        NSLog( @"error!" );
    }

    NSLog(@"length : %ld",strlen(data));
    
    CFRelease(imageBuffer);
    
    return nil;
}

@end
