//
//  JHNotificationManager.h
//  Notifications
//
//  Created by Jeff Hodnett on 13/09/2011.
//
//  Updated by Toni Chau on 12/12/13.
//  Copyright (c) 2013 Toni Chau. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    JHNotificationAnimationDirectionSlideInTop,
    JHNotificationAnimationDirectionSlideInLeft,
    JHNotificationAnimationDirectionSlideInLeftOutRight,
    JHNotificationAnimationDirectionSlideInRight,
    JHNotificationAnimationDirectionSlideInRightOutLeft,
    JHNotificationAnimationDirectionFlipDown,
    JHNotificationAnimationDirectionRotateIn,
    JHNotificationAnimationDirectionSwingInUpLeft,
    JHNotificationAnimationDirectionSwingInDownLeft,
    JHNotificationAnimationDirectionSwingInUpRight,
    JHNotificationAnimationDirectionSwingInDownRight
}JHNotificationAnimationDirection;

@interface JHNotificationManager : NSObject

+(JHNotificationManager *)sharedManager;

+(void)notificationWithMessage:(NSString *)message;
+(void)notificationWithMessage:(NSString *)message direction:(JHNotificationAnimationDirection)direction;

-(void)showNotificationView:(UIView *)notificationView direction:(JHNotificationAnimationDirection)direction;

@end
