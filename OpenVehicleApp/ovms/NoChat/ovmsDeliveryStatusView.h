//
//  ovmsDeliveryStatusView.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 25/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#ifndef ovmsDeliveryStatusView_h
#define ovmsDeliveryStatusView_h

#import <UIKit/UIKit.h>
#import "ovmsClockProgressView.h"
#import "ovmsMessage.h"

@interface OvmsDeliveryStatusView : UIView

@property (nonatomic, strong) OvmsClockProgressView *clockView;
@property (nonatomic, strong) UIImageView *checkmark1ImageView;
@property (nonatomic, strong) UIImageView *checkmark2ImageView;

@property (nonatomic, assign) OvmsMessageDeliveryStatus deliveryStatus;

@end

#endif /* ovmsDeliveryStatusView_h */
