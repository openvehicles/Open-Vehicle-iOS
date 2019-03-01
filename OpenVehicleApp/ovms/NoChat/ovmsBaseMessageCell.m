//
//  ovmsBaseMessageCell.m
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 25/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NoChat.h"
#import "ovmsBaseMessageCell.h"
#import "ovmsBaseMessageCellLayout.h"

@implementation OvmsBaseMessageCell

+ (NSString *)reuseIdentifier
{
    return @"OvmsBaseMessageCell";
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _bubbleView = [[UIView alloc] init];
        [self.itemView addSubview:_bubbleView];
    }
    return self;
}

- (void)setLayout:(id<NOCChatItemCellLayout>)layout
{
    [super setLayout:layout];
    self.bubbleView.frame = ((OvmsBaseMessageCellLayout *)layout).bubbleViewFrame;
}

@end
