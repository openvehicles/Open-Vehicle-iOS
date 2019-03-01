//
//  ovmsMessage.m
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 25/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#import "ovmsMessage.h"

@implementation OvmsMessage

- (instancetype)init
{
    self = [super init];
    if (self) {
        _msgId = [NSUUID new].UUIDString;
        _type = @"Text";
        _date = [NSDate date];
    }
    return self;
}

- (NSString *)uniqueIdentifier
{
    return self.msgId;
}

@end
