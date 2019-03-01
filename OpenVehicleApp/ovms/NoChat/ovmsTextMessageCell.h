//
//  ovmsTextMessageCell.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 15/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#ifndef ovmsTextMessageCell_h
#define ovmsTextMessageCell_h

#import "ovmsBaseMessageCell.h"
#import "ovmsDeliveryStatusView.h"

@class YYLabel;

@interface OvmsTextMessageCell : OvmsBaseMessageCell

@property (nonatomic, strong) UIImageView *bubbleImageView;
@property (nonatomic, strong) YYLabel *textLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) OvmsDeliveryStatusView *deliveryStatusView;

@end

@protocol OvmsTextMessageCellDelegate <NOCChatItemCellDelegate>

@optional
- (void)cell:(OvmsTextMessageCell *)cell didTapLink:(NSDictionary *)linkInfo;

@end

#endif /* ovmsTextMessageCell_h */
