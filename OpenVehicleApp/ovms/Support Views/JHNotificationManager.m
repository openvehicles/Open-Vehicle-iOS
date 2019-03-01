//
//  JHNotificationManager.m
//  Notifications
//
//  Created by Jeff Hodnett on 13/09/2011.
//
//  Updated by Toni Chau on 12/12/13.
//  Copyright (c) 2013 Toni Chau. All rights reserved.
//

#import "JHNotificationManager.h"
#import <math.h>
#import <QuartzCore/QuartzCore.h>

#define kSecondsVisibleDelay 1.0f
#define kAnimationDuration 0.4f
#define kAnimationDelay 0.1f

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface JHNotificationManager()
{
    // The notificatin views array
    NSMutableArray *_notificationQueue;
    
    // Are we showing a notification
    BOOL _showingNotification;
}

@end

@implementation JHNotificationManager

+(JHNotificationManager *)sharedManager
{
    static JHNotificationManager *instance = nil;
    
    @synchronized(self) {
        if(instance == nil) {
            instance = [[self alloc] init];
        }
    }
    
    return instance;
}

-(id)init
{
    if( (self = [super init]) ) {
        
        // Setup the array
        _notificationQueue = [[NSMutableArray alloc] init];
        
        // Set not showing by default
        _showingNotification = NO;
    }
    return self;
}

#pragma mark Messages
+(void)notificationWithMessage:(NSString *)message
{
    // Show the notification -- default animation to slide from top
    [[JHNotificationManager sharedManager] addNotificationViewWithMessage:message direction:JHNotificationAnimationDirectionSlideInTop];
}

+(void)notificationWithMessage:(NSString *)message direction:(JHNotificationAnimationDirection)direction
{
    // Show the notification
    [[JHNotificationManager sharedManager] addNotificationViewWithMessage:message direction:direction];
}

-(void)addNotificationViewWithMessage:(NSString *)message direction:(JHNotificationAnimationDirection)direction
{
    // Grab the main window
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    
    // Setup size variables
    CGSize notificationViewSize = CGSizeMake(CGRectGetWidth(window.bounds), 100.0f);
    
    // Create the notification view
    CGRect notificationViewFrame;
    UIView *notificationView = [[UIView alloc] init];
    
    // Get starting position
    switch (direction) {
        case JHNotificationAnimationDirectionSlideInLeft:
        case JHNotificationAnimationDirectionSlideInLeftOutRight:
            notificationViewFrame = CGRectMake(-notificationViewSize.width, 0, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSlideInRight:
        case JHNotificationAnimationDirectionSlideInRightOutLeft:
            notificationViewFrame = CGRectMake(notificationViewSize.width, 0, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSwingInUpLeft:
            notificationView.layer.anchorPoint = CGPointMake(0, 0);
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSwingInDownLeft:
            notificationView.layer.anchorPoint = CGPointMake(0, 1);
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSwingInUpRight:
            notificationView.layer.anchorPoint = CGPointMake(1, 0);
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionSwingInDownRight:
            notificationView.layer.anchorPoint = CGPointMake(1, 1);
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
        case JHNotificationAnimationDirectionFlipDown:
        case JHNotificationAnimationDirectionRotateIn:
        case JHNotificationAnimationDirectionSlideInTop:
        default:
            notificationViewFrame = CGRectMake(0, -notificationViewSize.height, notificationViewSize.width, notificationViewSize.height);
            break;
    }
    
    // Create the view
    [notificationView setFrame:notificationViewFrame];
    [notificationView setBackgroundColor:[UIColor blackColor]];
    
    // Add some text to the label
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, notificationViewSize.width, notificationViewSize.height)];
    [label setNumberOfLines:0];
    [label setText:message];
    [label setFont:[UIFont systemFontOfSize:18.0f]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    [notificationView addSubview:label];
    
    // Add to the window
    [window addSubview:notificationView];
    
    // Create array of notification view dictionaries
    [_notificationQueue addObject:[NSDictionary dictionaryWithObjectsAndKeys:notificationView, @"view", [NSNumber numberWithInt:direction], @"direction", nil]];
    
    // Should we show this notification view
    if(!_showingNotification) {
        [self showCurrentNotification];
    }
}

-(void)showCurrentNotification
{
    [self showNotificationView:[self currentView] direction:[self currentDirection]];
}

-(void)showNotificationView:(UIView *)notificationView direction:(JHNotificationAnimationDirection)direction
{
    // Set showing the notification
    _showingNotification = YES;
    
    // Animate the notification
    [UIView animateWithDuration:kAnimationDuration delay:kAnimationDelay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        // Create the notification view frame
        CGRect notificationViewFrame;
        CABasicAnimation *rotate;
        
        // Setup end positions
        switch (direction) {
            case JHNotificationAnimationDirectionSlideInLeft:
            case JHNotificationAnimationDirectionSlideInLeftOutRight:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x+CGRectGetWidth(notificationView.frame), notificationView.frame.origin.y, CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionSlideInRight:
            case JHNotificationAnimationDirectionSlideInRightOutLeft:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x-CGRectGetWidth(notificationView.frame), notificationView.frame.origin.y, CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionFlipDown:
                // Flip in on x-axis
                rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
                rotate.fromValue = [NSNumber numberWithFloat:0];
                rotate.toValue = [NSNumber numberWithFloat:M_PI / 2.0];
                rotate.duration = kAnimationDuration;

                [notificationView.layer addAnimation:rotate forKey:nil];
                    notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y+CGRectGetHeight(notificationView.frame), CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionRotateIn:
                // Rotate in from top
            case JHNotificationAnimationDirectionSwingInUpLeft:
                // Swing upwards from left
            case JHNotificationAnimationDirectionSwingInDownRight:
                // Swing downwards from right
                rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
                rotate.fromValue = [NSNumber numberWithFloat:DEGREES_RADIANS(180)];
                rotate.toValue = [NSNumber numberWithFloat:DEGREES_RADIANS(0)];
                rotate.duration = kAnimationDuration;
                [notificationView.layer addAnimation:rotate forKey:nil];
                
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y+CGRectGetHeight(notificationView.frame), CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionSwingInDownLeft:
                // Swing downwards from left
            case JHNotificationAnimationDirectionSwingInUpRight:
                // Swing downwards from left
                rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
                rotate.fromValue = [NSNumber numberWithFloat:DEGREES_RADIANS(-180)];
                rotate.toValue = [NSNumber numberWithFloat:DEGREES_RADIANS(0)];
                rotate.duration = kAnimationDuration;
                [notificationView.layer addAnimation:rotate forKey:nil];
                
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y+CGRectGetHeight(notificationView.frame), CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionSlideInTop:
            default:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y+CGRectGetHeight(notificationView.frame), CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
        }
        
        [notificationView setFrame: notificationViewFrame];
        
    } completion:^(BOOL finished) {
        
        // Hide the notification after a set second delay
        [self hideCurrentNotificationWithDirection:direction delay:kSecondsVisibleDelay];
    }];
}

-(void)hideCurrentNotificationWithDirection:(JHNotificationAnimationDirection)direction
{
    [self hideCurrentNotificationWithDirection:direction delay:kAnimationDelay];
}

-(void)hideCurrentNotificationWithDirection:(JHNotificationAnimationDirection)direction delay:(CGFloat)delay
{
    // Get the current view
    UIView *notificationView = [self currentView];
    
    // Animate the view
    [UIView animateWithDuration:kAnimationDuration delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect notificationViewFrame;
        
        // Get positions
        switch (direction) {
            case JHNotificationAnimationDirectionSlideInLeft:
            case JHNotificationAnimationDirectionSlideInRightOutLeft:
                notificationViewFrame = CGRectMake(-CGRectGetWidth(notificationView.frame), notificationView.frame.origin.y, CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionSlideInRight:
            case JHNotificationAnimationDirectionSlideInLeftOutRight:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x+CGRectGetWidth(notificationView.frame), notificationView.frame.origin.y, CGRectGetWidth(notificationView.frame), CGRectGetHeight(notificationView.frame));
                break;
            case JHNotificationAnimationDirectionFlipDown:
            case JHNotificationAnimationDirectionRotateIn:
            case JHNotificationAnimationDirectionSwingInUpLeft:
            case JHNotificationAnimationDirectionSwingInUpRight:
            case JHNotificationAnimationDirectionSwingInDownRight:
            case JHNotificationAnimationDirectionSlideInTop:
            default:
                notificationViewFrame = CGRectMake(notificationView.frame.origin.x, notificationView.frame.origin.y-notificationView.frame.size.height, notificationView.frame.size.width, notificationView.frame.size.height);
                break;
        }
        
        [notificationView setFrame:notificationViewFrame];
        
    } completion:^(BOOL finished) {
        // Remove the old one
        UIView *notificationView = [self currentView];
        [notificationView removeFromSuperview];
        [self->_notificationQueue removeObjectAtIndex:0];
        
        // Set not showing
        self->_showingNotification = NO;
        
        // Do we have to add anymore items - if so show them
        if([self->_notificationQueue count] > 0) {
            [self showCurrentNotification];
        }
    }];
}

-(UIView *)currentView
{
    NSDictionary *notificationDataQueue = [_notificationQueue objectAtIndex:0];
    UIView *view  = [notificationDataQueue objectForKey:@"view"];
    return view;
}

-(JHNotificationAnimationDirection)currentDirection
{
    NSDictionary *notificationDataQueue = [_notificationQueue objectAtIndex:0];
    JHNotificationAnimationDirection direction = [[notificationDataQueue objectForKey:@"direction"] intValue];
    return direction;
}
@end
