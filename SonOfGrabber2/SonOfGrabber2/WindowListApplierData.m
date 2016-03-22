//
//  WindowListApplierData.m
//  SonOfGrabber2
//
//  Created by 叔 陈 on 16/3/21.
//  Copyright © 2016年 叔 陈. All rights reserved.
//

#import "WindowListApplierData.h"

@interface WindowListApplierData()
{
}

@end

@implementation WindowListApplierData

-(instancetype)initWindowListData:(NSMutableArray *)array
{
    self = [super init];
    
    self.outputArray = array;
    self.order = 0;
    
    return self;
}

@end