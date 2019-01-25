//
//  ovmsBaseMessageCell.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 25/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#ifndef ovmsBaseMessageCell_h
#define ovmsBaseMessageCell_h

#import "NoChat.h"

@interface OvmsBaseMessageCell : NOCChatItemCell

@property (nonatomic, strong) UIView *bubbleView;

@property (nonatomic, assign, getter=isHighlight) BOOL hightlight;

@end

#endif /* ovmsBaseMessageCell_h */
