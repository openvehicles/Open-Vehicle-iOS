//
//  ovmsBaseMessageCellLayout.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 25/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#ifndef ovmsBaseMessageCellLayout_h
#define ovmsBaseMessageCellLayout_h

#include "NoChat.h"

@class OvmsMessage;

@interface OvmsBaseMessageCellLayout : NSObject <NOCChatItemCellLayout>

@property (nonatomic, strong) NSString *reuseIdentifier;
@property (nonatomic, strong) id<NOCChatItem> chatItem;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@property (nonatomic, strong, readonly) OvmsMessage *message;
@property (nonatomic, assign, readonly) BOOL isOutgoing;

@property (nonatomic, assign) UIEdgeInsets bubbleViewMargin;
@property (nonatomic, assign) CGRect bubbleViewFrame;

- (instancetype)initWithChatItem:(id<NOCChatItem>)chatItem cellWidth:(CGFloat)width;
- (void)calculateLayout;

@end

#endif /* ovmsBaseMessageCellLayout_h */
