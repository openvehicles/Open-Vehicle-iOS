//
//  ovmsMessageInputPanel.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 15/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#ifndef ovmsMessageInputPanel_h
#define ovmsMessageInputPanel_h

#import "NoChat.h"

@class OvmsChatInputTextPanel;
@class HPGrowingTextView;

@protocol OvmsChatInputTextPanelDelegate <NOCChatInputPanelDelegate>

@optional
- (void)inputTextPanel:(OvmsChatInputTextPanel *)inputTextPanel requestSendText:(NSString *)text;

@end

@interface OvmsChatInputTextPanel : NOCChatInputPanel

@property (nonatomic, strong) CALayer *stripeLayer;
@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) HPGrowingTextView *inputField;
@property (nonatomic, strong) UIView *inputFieldClippingContainer;
@property (nonatomic, strong) UIImageView *fieldBackground;

@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *attachButton;
@property (nonatomic, strong) UIButton *micButton;

- (void)toggleSendButtonEnabled;
- (void)clearInputField;

@end

#endif /* ovmsMessageInputPanel_h */
