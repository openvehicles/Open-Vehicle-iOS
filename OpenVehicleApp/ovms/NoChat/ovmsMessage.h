//
//  ovmsMessage.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 25/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#ifndef ovmsMessage_h
#define ovmsMessage_h

#import <Foundation/Foundation.h>
#import "NoChat.h"

typedef NS_ENUM(NSUInteger, OvmsMessageDeliveryStatus) {
    OvmsMessageDeliveryStatusIdle = 0,
    OvmsMessageDeliveryStatusDelivering = 1,
    OvmsMessageDeliveryStatusDelivered = 2,
    OvmsMessageDeliveryStatusFailure = 3,
    OvmsMessageDeliveryStatusRead = 4
};

@interface OvmsMessage : NSObject <NOCChatItem>

@property (nonatomic, strong) NSString *msgId;
@property (nonatomic, strong) NSString *type;

@property (nonatomic, strong) NSString *senderId;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *text;

@property (nonatomic, assign, getter=isOutgoing) BOOL outgoing;
@property (nonatomic, assign) OvmsMessageDeliveryStatus deliveryStatus;

@end

#endif /* ovmsMessage_h */
