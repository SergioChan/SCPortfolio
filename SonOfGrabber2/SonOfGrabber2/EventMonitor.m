//
//  EventMonitor.m
//  SonOfGrabber2
//
//  Created by 叔 陈 on 16/3/21.
//  Copyright © 2016年 叔 陈. All rights reserved.
//

#import "EventMonitor.h"

@implementation EventMonitor

- (instancetype)initWithMask:(NSEventMask)mask handler:(void (^)(NSEvent *event))handler
{
    self = [super init];
    if(self) {
        self.mask = mask;
        self.handler = handler;
    }
    return self;
}

- (void)start
{
    self.monitor = [NSEvent addGlobalMonitorForEventsMatchingMask:self.mask handler:self.handler];
}

- (void)stop
{
    if (self.monitor) {
        [NSEvent removeMonitor:self.monitor];
        self.monitor = nil;
    }
}
@end
