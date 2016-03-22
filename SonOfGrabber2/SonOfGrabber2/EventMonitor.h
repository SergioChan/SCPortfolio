//
//  EventMonitor.h
//  SonOfGrabber2
//
//  Created by 叔 陈 on 16/3/21.
//  Copyright © 2016年 叔 陈. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface EventMonitor : NSObject

@property (strong) id monitor;
@property (assign) NSEventMask mask;
@property (nonatomic, copy) void (^handler)(NSEvent *event);

- (instancetype)initWithMask:(NSEventMask)mask handler:(void (^)(NSEvent *event))handler;
- (void)start;
- (void)stop;
@end
