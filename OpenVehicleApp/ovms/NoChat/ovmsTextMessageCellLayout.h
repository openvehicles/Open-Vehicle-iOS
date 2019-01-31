//
//  ovmsTextMessageCellLayout.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 15/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#ifndef ovmsTextMessageCellLayout_h
#define ovmsTextMessageCellLayout_h

#import "ovmsBaseMessageCellLayout.h"
#import "YYText.h"

@interface OvmsTextMessageCellLayout : OvmsBaseMessageCellLayout

@property (nonatomic, strong) NSAttributedString *attributedTime;
@property (nonatomic, assign) BOOL hasTail;
@property (nonatomic, strong) UIImage *bubbleImage;
@property (nonatomic, strong) UIImage *highlightBubbleImage;

@property (nonatomic, assign) CGRect bubbleImageViewFrame;
@property (nonatomic, assign) CGRect textLabelFrame;
@property (nonatomic, strong) YYTextLayout *textLayout;
@property (nonatomic, assign) CGRect timeLabelFrame;
@property (nonatomic, assign) CGRect deliveryStatusViewFrame;

@end

@interface OvmsTextMessageCellLayout (TGStyle)

+ (UIImage *)fullOutgoingBubbleImage;
+ (UIImage *)highlightFullOutgoingBubbleImage;
+ (UIImage *)partialOutgoingBubbleImage;
+ (UIImage *)highlightPartialOutgoingBubbleImage;
+ (UIImage *)fullIncomingBubbleImage;
+ (UIImage *)highlightFullIncomingBubbleImage;
+ (UIImage *)partialIncomingBubbleImage;
+ (UIImage *)highlightPartialIncomingBubbleImage;

+ (UIFont *)textFont;
+ (UIColor *)textColor;
+ (UIColor *)linkColor;
+ (UIColor *)linkBackgroundColor;

+ (UIFont *)timeFont;
+ (UIColor *)outgoingTimeColor;
+ (UIColor *)incomingTimeColor;
+ (NSDateFormatter *)timeFormatter;

@end

@interface OvmsTextLinePositionModifier : NSObject <YYTextLinePositionModifier>

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, assign) CGFloat paddingTop;
@property (nonatomic, assign) CGFloat paddingBottom;
@property (nonatomic, assign) CGFloat lineHeightMultiple;

- (CGFloat)heightForLineCount:(NSUInteger)lineCount;

@end

#endif /* ovmsTextMessageCellLayout_h */
