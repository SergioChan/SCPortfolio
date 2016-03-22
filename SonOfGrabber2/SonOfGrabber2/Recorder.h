//
//  Recorder.h
//  SonOfGrabber2
//
//  Created by 叔 陈 on 16/3/22.
//  Copyright © 2016年 叔 陈. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Recorder : NSObject <AVCaptureFileOutputRecordingDelegate,AVCaptureFileOutputDelegate> {
@private
    AVCaptureSession *mSession;
    AVCaptureMovieFileOutput *mMovieFileOutput;
}

@property (weak) NSImageView *imageView;

-(void)screenRecording:(NSURL *)destPath;
-(void)finishRecord;

@end
