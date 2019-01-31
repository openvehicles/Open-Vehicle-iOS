//
//  ovmsDeliveryStatusView.m
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 25/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ovmsDeliveryStatusView.h"

@implementation OvmsDeliveryStatusView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _clockView = [[OvmsClockProgressView alloc] init];
        [self addSubview:_clockView];
        
        _checkmark1ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OvmsMessageCheckmark1"]];
        [self addSubview:_checkmark1ImageView];
        
        _checkmark2ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OvmsMessageCheckmark2"]];
        [self addSubview:_checkmark2ImageView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.clockView.frame = self.bounds;
    self.checkmark1ImageView.frame = CGRectMake(0, 2, 12, 11);
    self.checkmark2ImageView.frame = CGRectMake(3, 2, 12, 11);
}

- (void)setDeliveryStatus:(OvmsMessageDeliveryStatus)deliveryStatus
{
    if (deliveryStatus == OvmsMessageDeliveryStatusDelivering) {
        self.clockView.hidden = NO;
        [self.clockView startAnimating];
        self.checkmark1ImageView.hidden = YES;
        self.checkmark2ImageView.hidden = YES;
    } else if (deliveryStatus == OvmsMessageDeliveryStatusDelivered) {
        [self.clockView stopAnimating];
        self.clockView.hidden = YES;
        self.checkmark1ImageView.hidden = NO;
        self.checkmark2ImageView.hidden = YES;
    } else if (deliveryStatus == OvmsMessageDeliveryStatusRead) {
        [self.clockView stopAnimating];
        self.clockView.hidden = YES;
        self.checkmark1ImageView.hidden = NO;
        self.checkmark2ImageView.hidden = NO;
    } else {
        [self.clockView stopAnimating];
        self.clockView.hidden = YES;
        self.checkmark1ImageView.hidden = YES;
        self.checkmark2ImageView.hidden = YES;
    }
}

@end
