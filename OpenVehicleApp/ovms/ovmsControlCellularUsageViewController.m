//
//  ovmsControlCellularUsageViewController.m
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 2/2/12.
//  Copyright (c) 2012 Open Vehicle Systems. All rights reserved.
//

#import "ovmsControlCellularUsageViewController.h"
#import "JHNotificationManager.h"

@interface OVMSCellularUsageChart : UIView
@property (copy, nonatomic) NSArray *received;
@property (copy, nonatomic) NSArray *transmitted;
@end

@implementation OVMSCellularUsageChart
- (void)setReceived:(NSArray *)received { _received=[received copy]; [self setNeedsDisplay]; }
- (void)setTransmitted:(NSArray *)transmitted { _transmitted=[transmitted copy]; [self setNeedsDisplay]; }
- (void)drawRect:(CGRect)rect
{
  [[UIColor colorWithRed:.086 green:.125 blue:.196 alpha:1] setFill]; UIRectFill(rect);
  CGContextRef context=UIGraphicsGetCurrentContext(); [[UIColor colorWithWhite:1 alpha:.10] setStroke]; CGContextSetLineWidth(context,.5);
  for(NSInteger line=1;line<4;line++){CGFloat y=CGRectGetHeight(rect)*line/4.0;CGContextMoveToPoint(context,8,y);CGContextAddLineToPoint(context,CGRectGetWidth(rect)-8,y);} CGContextStrokePath(context);
  double maximum=1; for(NSNumber *value in self.received) maximum=MAX(maximum,value.doubleValue); for(NSNumber *value in self.transmitted) maximum=MAX(maximum,value.doubleValue);
  NSArray *series=@[self.received?:@[],self.transmitted?:@[]]; NSArray *colors=@[[UIColor colorWithRed:.28 green:.72 blue:1 alpha:1],[UIColor colorWithRed:.96 green:.58 blue:.22 alpha:1]];
  [series enumerateObjectsUsingBlock:^(NSArray *values,NSUInteger seriesIndex,BOOL *stop){if(values.count<2)return;[(UIColor *)colors[seriesIndex] setStroke];CGContextSetLineWidth(context,2);CGContextBeginPath(context);[values enumerateObjectsUsingBlock:^(NSNumber *value,NSUInteger index,BOOL *innerStop){CGFloat x=10+(CGRectGetWidth(rect)-20)*index/MAX((NSInteger)values.count-1,1);CGFloat y=10+(CGRectGetHeight(rect)-20)*(1-value.doubleValue/maximum);if(index==0)CGContextMoveToPoint(context,x,y);else CGContextAddLineToPoint(context,x,y);}];CGContextStrokePath(context);}];
}
@end

@interface ovmsControlCellularUsageViewController ()
@property (strong, nonatomic) UILabel *usageSummary;
@property (strong, nonatomic) UILabel *usageLegend;
@property (strong, nonatomic) OVMSCellularUsageChart *nativeChart;
@property (strong, nonatomic) UILabel *appUsageSummary;
@property (strong, nonatomic) OVMSCellularUsageChart *appNativeChart;
@end

@implementation ovmsControlCellularUsageViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title=@"Cellular usage"; self.view.backgroundColor=[UIColor colorWithRed:.047 green:.071 blue:.118 alpha:1];
    UIScrollView *scroll=[[UIScrollView alloc] init]; scroll.translatesAutoresizingMaskIntoConstraints=NO; [self.view addSubview:scroll];
    UIStackView *content=[[UIStackView alloc] init]; content.translatesAutoresizingMaskIntoConstraints=NO; content.axis=UILayoutConstraintAxisVertical; content.spacing=14; [scroll addSubview:content];
    [NSLayoutConstraint activateConstraints:@[[scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],[scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],[content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:18],[content.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:16],[content.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-16],[content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-18]]];
    UILabel *heading=[[UILabel alloc] init]; heading.text=@"Module data usage"; heading.textColor=UIColor.whiteColor; heading.font=[UIFont systemFontOfSize:30 weight:UIFontWeightSemibold]; [content addArrangedSubview:heading];
    self.usageSummary=[[UILabel alloc] init]; self.usageSummary.text=@"Requesting usage history…"; self.usageSummary.textColor=UIColor.whiteColor; self.usageSummary.numberOfLines=0; self.usageSummary.font=[UIFont preferredFontForTextStyle:UIFontTextStyleTitle2]; [content addArrangedSubview:self.usageSummary];
    self.nativeChart=[[OVMSCellularUsageChart alloc] init]; self.nativeChart.layer.cornerRadius=14; self.nativeChart.layer.masksToBounds=YES; self.nativeChart.accessibilityLabel=@"Daily cellular data usage chart"; [self.nativeChart.heightAnchor constraintEqualToConstant:240].active=YES; [content addArrangedSubview:self.nativeChart];
    self.usageLegend=[[UILabel alloc] init]; self.usageLegend.text=@"Blue: received  ·  Orange: transmitted"; self.usageLegend.textColor=[UIColor colorWithWhite:.72 alpha:1]; self.usageLegend.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]; [content addArrangedSubview:self.usageLegend];
    self.appUsageSummary=[[UILabel alloc] init]; self.appUsageSummary.text=@"Connected apps"; self.appUsageSummary.textColor=UIColor.whiteColor; self.appUsageSummary.numberOfLines=0; self.appUsageSummary.font=[UIFont preferredFontForTextStyle:UIFontTextStyleTitle2]; [content addArrangedSubview:self.appUsageSummary];
    self.appNativeChart=[[OVMSCellularUsageChart alloc] init]; self.appNativeChart.layer.cornerRadius=14; self.appNativeChart.layer.masksToBounds=YES; self.appNativeChart.accessibilityLabel=@"Daily connected application data usage chart"; [self.appNativeChart.heightAnchor constraintEqualToConstant:180].active=YES; [content addArrangedSubview:self.appNativeChart];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self displayChart];
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         
     }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)viewWillAppear:(BOOL)animated
  {
  [super viewWillAppear:animated];

  // Request the list of features from the car...
  t_rxt = 0;
  t_txt = 0;
  t_app_rxt = 0;
  t_app_txt = 0;
  t_days = 0;
  [[ovmsAppDelegate myRef] commandRegister:@"30" callback:self];
  [self startSpinner:@"Loading Usage"];
  }

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
}

- (void)startSpinner:(NSString *)label
{
  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
  hud.labelText = label; 
}

- (void)stopSpinner
{
  [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
}

- (void)displayChart
  {
  NSMutableArray *received=[NSMutableArray array],*transmitted=[NSMutableArray array],*appReceived=[NSMutableArray array],*appTransmitted=[NSMutableArray array];
  for(int index=0;index<t_days;index++){[received addObject:@(t_rx[index]/1024.0)];[transmitted addObject:@(t_tx[index]/1024.0)];[appReceived addObject:@(t_app_rx[index]/1024.0)];[appTransmitted addObject:@(t_app_tx[index]/1024.0)];}
  self.nativeChart.received=received; self.nativeChart.transmitted=transmitted;
  self.appNativeChart.received=appReceived; self.appNativeChart.transmitted=appTransmitted;
  self.usageSummary.text=t_days>0?[NSString stringWithFormat:@"Past %d days\n%.2f MB received  ·  %.2f MB transmitted",t_days,(double)t_rxt/(1024*1024),(double)t_txt/(1024*1024)]:@"No cellular usage history reported";
  self.usageLegend.text=t_days>0?[NSString stringWithFormat:@"Blue: received  ·  Orange: transmitted\nDaily scale in KiB  ·  %@ to %@",t_day[0]?:@"oldest",t_day[t_days-1]?:@"latest"]:@"The vehicle module did not return daily samples.";
  self.appUsageSummary.text=t_days>0?[NSString stringWithFormat:@"Connected apps\n%.2f MB received  ·  %.2f MB transmitted",(double)t_app_rxt/(1024*1024),(double)t_app_txt/(1024*1024)]:@"Connected apps\nNo usage history reported";
  }

- (void)commandResult:(NSArray*)result
{  
  if ([result count]>1)
    {
    int command = [[result objectAtIndex:0] intValue];
    int rcode = [[result objectAtIndex:1] intValue];
    if (command != 30) return; // Not for us
    switch (rcode)
      {
      case 0:
        {
          if ([result count]>=9)
          {
          int fn = [[result objectAtIndex:2] intValue];
          int fm = [[result objectAtIndex:3] intValue];
          NSString *day = [result objectAtIndex:4];
          int rx = [[result objectAtIndex:5] intValue];
          int tx = [[result objectAtIndex:6] intValue];
          int appRx = [[result objectAtIndex:7] intValue];
          int appTx = [[result objectAtIndex:8] intValue];
          if (fn < MAX_DAYS)
            {
            t_day[fm-fn] = day;
            t_rx[fm-fn] = rx;
            t_tx[fm-fn] = tx;
            t_app_rx[fm-fn] = appRx;
            t_app_tx[fm-fn] = appTx;
            t_rxt += rx;
            t_txt += tx;
            t_app_rxt += appRx;
            t_app_txt += appTx;
            t_days = fm;
            }
          if (fn == fm)
            {
            [[ovmsAppDelegate myRef] commandCancel];
            [self stopSpinner];
            [self displayChart];
            }
          }
        }
        break;
      case 1: // failed
        [JHNotificationManager
         notificationWithMessage:
         [NSString stringWithFormat:@"Failed: %@",[result objectAtIndex:2]]];
        [[ovmsAppDelegate myRef] commandCancel];
        [self stopSpinner];
        break;
      case 2: // unsupported
        [JHNotificationManager notificationWithMessage:@"Unsupported operation"];
        [[ovmsAppDelegate myRef] commandCancel];
        [self stopSpinner];
        break;
      case 3: // unimplemented
        [JHNotificationManager notificationWithMessage:@"Unimplemented operation"];
        [[ovmsAppDelegate myRef] commandCancel];
        [self stopSpinner];
        break;
      }
    }
  else
    {
    [[ovmsAppDelegate myRef] commandCancel];
    [self stopSpinner];
    }
}

@end
