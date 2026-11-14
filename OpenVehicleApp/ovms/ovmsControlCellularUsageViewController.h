//
//  ovmsControlCellularUsageViewController.h
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 2/2/12.
//  Copyright (c) 2012 Open Vehicle Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "ovmsAppDelegate.h"

#define MAX_DAYS 100

@interface ovmsControlCellularUsageViewController : UIViewController <ovmsCommandDelegate, MBProgressHUDDelegate>
  {
  NSString *t_day[MAX_DAYS];
  int t_rx[MAX_DAYS];
  int t_tx[MAX_DAYS];
  int t_app_rx[MAX_DAYS];
  int t_app_tx[MAX_DAYS];
  int t_days;
  int t_rxt;
  int t_txt;
  int t_app_rxt;
  int t_app_txt;
  }

- (void)startSpinner:(NSString *)label;
- (void)stopSpinner;
- (void)displayChart;

@end
