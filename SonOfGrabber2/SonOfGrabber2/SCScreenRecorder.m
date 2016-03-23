//
//  SCScreenRecorder.m
//  SonOfGrabber2
//
//  Created by 叔 陈 on 16/3/22.
//  Copyright © 2016年 叔 陈. All rights reserved.
//

#import "SCScreenRecorder.h"

@interface SCScreenRecorder()
{
    NSMutableData *elementaryStream;
}
@end

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
        self.input.minFrameDuration = CMTimeMake(1, 60);
        self.input.scaleFactor = 0.5f;
        self.input.cropRect = [self screenRect];
        
        self.output  = [[AVCaptureVideoDataOutput alloc] init];
        [((AVCaptureVideoDataOutput *)self.output) setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys:@(kCVPixelFormatType_32BGRA),kCVPixelBufferPixelFormatTypeKey, nil]];
        dispatch_queue_t queue = dispatch_queue_create("com.sergio.chan", 0);
        [(AVCaptureVideoDataOutput *)self.output setSampleBufferDelegate:self queue:queue];
        //dispatch_release(queue);
        
        [self.session addInput:self.input];
        [self.session addOutput:self.output];
        
        elementaryStream = [NSMutableData data];
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
    return NO;
}

- (BOOL) stop {
    [self.session stopRunning];
    return YES;
}


#pragma mark AVCaptureFileOutputDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    [self videoFramebuffer:sampleBuffer];
    
    [self imageFromSampleBuffer:sampleBuffer];

    
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

- (void) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
//    @autoreleasepool
//    {
    @try {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
        
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        CGContextRelease(newContext);
        
        CGColorSpaceRelease(colorSpace);
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        
        NSImage *image = [[NSImage alloc] initWithCGImage:newImage size:[self screenRect].size];
        CGImageRelease(newImage);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.imageView) {
                self.imageView.image = image;
            }
        });
    }
    @catch (NSException *exception) {
        NSLog(@"Error at %@",exception.debugDescription);
    }
    @finally {
        return;
    }
    
        /* CVBufferRelease(imageBuffer); */  // do not call this!
        
//        NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:newImage];
//        CGFloat imageCompression = 0.4; //between 0 and 1; 1 is maximum quality, 0 is maximum compression
//        
//        // set up the options for creating a JPEG
//        NSDictionary* jpegOptions = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     [NSNumber numberWithDouble:imageCompression], NSImageCompressionFactor,
//                                     [NSNumber numberWithBool:NO], NSImageProgressive,
//                                     nil];
//        
//        NSData* jpegData = [bitmapRep representationUsingType:NSJPEGFileType properties:jpegOptions];
//        //    NSData *jpegData = imageToBuffer(sampleBuffer);
//        
//        NSLog(@"fuck length:%ld",jpegData.length);
    
//    }
    
//    CMBlockBufferRef imageBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    
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
    
//    size_t len = CMBlockBufferGetDataLength(imageBuffer);
//    char * data = NULL;
//    CMBlockBufferGetDataPointer(imageBuffer, 0, NULL, &len, &data);
//    NSData * d = [[NSData alloc] initWithBytes:data length:len];
//    
////    size_t lengthAtOffset;
////    size_t totalLength;
////    char* data;
////
////    CFRetain(imageBuffer);
////    
////    if(CMBlockBufferGetDataPointer(imageBuffer, 0, &lengthAtOffset, &totalLength, &data ) != noErr )
////    {
////        NSLog( @"error!" );
////    }
//
//    NSLog(@"length : %ld,%ld,%ld",[d length],len,strlen(data));
//    
////    CFRelease(imageBuffer);
//
//    
//    size_t W = [self screenRect].size.width;
//    size_t H = [self screenRect].size.height;
//    
//    size_t BitsPerComponent = 8;
//    size_t BytesPerRow=((BitsPerComponent * W) / 8) * 4;
//    
//    int bytes = BytesPerRow * H;
//    
//    uint8_t *baseAddress = malloc(bytes);
//    memcpy(baseAddress,data,bytes);
//    
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    
//    CGContextRef newContext = CGBitmapContextCreate(baseAddress,W,H,BitsPerComponent,BytesPerRow,colorSpace,kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
//    CGContextRelease(newContext);
//    CGColorSpaceRelease(colorSpace);
//    
//    NSImage *image = [[NSImage alloc] initWithCGImage:newImage size:NSMakeSize(W, H)];
//    
//    free(baseAddress);
//    
//    return image;
}

- (NSRect)screenRect
{
    NSRect screenRect;
    NSArray *screenArray = [NSScreen screens];
    NSScreen *screen = [screenArray objectAtIndex: 0];
    screenRect = [screen visibleFrame];
    
    return screenRect;
}

- (void)videoFramebuffer:(CMSampleBufferRef)sampleBuffer
{
    // In this example we will use a NSMutableData object to store the
    // elementary stream.
    
    // Find out if the sample buffer contains an I-Frame.
    // If so we will write the SPS and PPS NAL units to the elementary stream.
    BOOL isIFrame = NO;
    CFArrayRef attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, 0);
    if (CFArrayGetCount(attachmentsArray)) {
        CFBooleanRef notSync;
        CFDictionaryRef dict = CFArrayGetValueAtIndex(attachmentsArray, 0);
        BOOL keyExists = CFDictionaryGetValueIfPresent(dict,
                                                       kCMSampleAttachmentKey_NotSync,
                                                       (const void **)&notSync);
        // An I-Frame is a sync frame
        isIFrame = !keyExists || !CFBooleanGetValue(notSync);
    }
    
    // This is the start code that we will write to
    // the elementary stream before every NAL unit
    static const size_t startCodeLength = 4;
    static const uint8_t startCode[] = {0x00, 0x00, 0x00, 0x01};
    
    // Write the SPS and PPS NAL units to the elementary stream before every I-Frame
    if (isIFrame) {
        CMFormatDescriptionRef description = CMSampleBufferGetFormatDescription(sampleBuffer);
        NSImage *cgImage = [[NSImage alloc] initWithData:elementaryStream];
        if(self.imageView) {
            self.imageView.image = cgImage;
        }
        elementaryStream = [NSMutableData data];
        
        // Find out how many parameter sets there are
        size_t numberOfParameterSets;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                           0, NULL, NULL,
                                                           &numberOfParameterSets,
                                                           NULL);
        
        // Write each parameter set to the elementary stream
        for (int i = 0; i < numberOfParameterSets; i++) {
            const uint8_t *parameterSetPointer;
            size_t parameterSetLength;
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                               i,
                                                               &parameterSetPointer,
                                                               &parameterSetLength,
                                                               NULL, NULL);
            
            // Write the parameter set to the elementary stream
            [elementaryStream appendBytes:startCode length:startCodeLength];
            [elementaryStream appendBytes:parameterSetPointer length:parameterSetLength];
        }
    }
    
    // Get a pointer to the raw AVCC NAL unit data in the sample buffer
    size_t blockBufferLength;
    uint8_t *bufferDataPointer = NULL;
    CMBlockBufferGetDataPointer(CMSampleBufferGetDataBuffer(sampleBuffer),
                                0,
                                NULL,
                                &blockBufferLength,
                                (char **)&bufferDataPointer);
    
    // Loop through all the NAL units in the block buffer
    // and write them to the elementary stream with
    // start codes instead of AVCC length headers
    size_t bufferOffset = 0;
    static const int AVCCHeaderLength = 4;
    while (bufferOffset < blockBufferLength - AVCCHeaderLength) {
        // Read the NAL unit length
        uint32_t NALUnitLength = 0;
        memcpy(&NALUnitLength, bufferDataPointer + bufferOffset, AVCCHeaderLength);
        // Convert the length value from Big-endian to Little-endian
        NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
        // Write start code to the elementary stream
        [elementaryStream appendBytes:startCode length:startCodeLength];
        // Write the NAL unit without the AVCC length header to the elementary stream
        [elementaryStream appendBytes:bufferDataPointer + bufferOffset + AVCCHeaderLength
                               length:NALUnitLength];
        // Move to the next NAL unit in the block buffer
        bufferOffset += AVCCHeaderLength + NALUnitLength;
    }
}

@end
