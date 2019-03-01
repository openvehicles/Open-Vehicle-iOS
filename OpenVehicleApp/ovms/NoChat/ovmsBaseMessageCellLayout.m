//
//  ovmsBaseMessageCellLayout.m
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 25/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ovmsBaseMessageCellLayout.h"
#import "ovmsMessage.h"

@implementation OvmsBaseMessageCellLayout

- (instancetype)initWithChatItem:(id<NOCChatItem>)chatItem cellWidth:(CGFloat)width
{
    self = [super init];
    if (self) {
        _reuseIdentifier = @"OvmsBaseMessageCell";
        _chatItem = chatItem;
        _width = width;
        _bubbleViewMargin = UIEdgeInsetsMake(4, 2, 4, 2);
    }
    return self;
}

- (void)calculateLayout
{
    
}

- (OvmsMessage *)message
{
    return (OvmsMessage *)self.chatItem;
}

- (BOOL)isOutgoing
{
    return self.message.isOutgoing;
}

@end
