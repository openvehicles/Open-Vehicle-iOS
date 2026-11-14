//
//  ovmsStatusViewController.m
//  ovms
//
//  Created by Mark Webb-Johnson on 16/11/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import "ovmsStatusViewController.h"
#import "JHNotificationManager.h"
#import <float.h>
#import <math.h>

@interface OVMSSparklineView : UIView
@property (copy, nonatomic) NSArray *series;
@property (copy, nonatomic) NSArray *colors;
@end

@implementation OVMSSparklineView
@synthesize series = _series;
@synthesize colors = _colors;
- (void)setSeries:(NSArray *)series { _series = [series copy]; [self setNeedsDisplay]; }
- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  [[UIColor colorWithRed:0.086 green:0.125 blue:0.196 alpha:1] setFill]; UIRectFill(rect);
  CGContextSetLineWidth(context, 0.5); [[UIColor colorWithWhite:1 alpha:0.10] setStroke];
  for (NSInteger i=1; i<4; i++) { CGFloat y=CGRectGetHeight(rect)*i/4.0; CGContextMoveToPoint(context, 0, y); CGContextAddLineToPoint(context, CGRectGetWidth(rect), y); } CGContextStrokePath(context);
  [self.series enumerateObjectsUsingBlock:^(NSArray *values, NSUInteger seriesIndex, BOOL *stop) {
    if (values.count < 2) return;
    __block double low=DBL_MAX, high=-DBL_MAX; for (NSNumber *number in values) { low=MIN(low,number.doubleValue); high=MAX(high,number.doubleValue); } if (fabs(high-low)<0.0001) { low-=1; high+=1; }
    UIColor *color = seriesIndex < self.colors.count ? self.colors[seriesIndex] : [UIColor colorWithRed:.3 green:.82 blue:.42 alpha:1];
    [color setStroke]; CGContextSetLineWidth(context, 2.0); CGContextBeginPath(context);
    [values enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger index, BOOL *innerStop) {
      CGFloat x = 8 + (CGRectGetWidth(rect)-16) * index / MAX((NSInteger)values.count-1, 1);
      CGFloat y = 8 + (CGRectGetHeight(rect)-16) * (high-number.doubleValue)/(high-low);
      if (index==0) CGContextMoveToPoint(context,x,y); else CGContextAddLineToPoint(context,x,y);
    }]; CGContextStrokePath(context);
  }];
}
@end

@interface OVMSBatteryDiagnosticsViewController : UIViewController <ovmsUpdateDelegate, ovmsCommandDelegate>
@property (strong, nonatomic) NSMutableArray *packRecords;
@property (strong, nonatomic) NSMutableDictionary *latestCells;
@property (strong, nonatomic) NSMutableArray *auxRecords;
@property (copy, nonatomic) NSString *loadPhase;
@property (strong, nonatomic) NSTimer *loadTimeout;
- (void)loadScreenshotPreview:(BOOL)loading;
@end

@implementation OVMSBatteryDiagnosticsViewController
- (UILabel *)line:(NSString *)text tag:(NSInteger)tag
{
  UILabel *label = [[UILabel alloc] init]; label.text = text; label.tag = tag; label.numberOfLines = 0;
  label.textColor = [UIColor whiteColor]; label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  label.backgroundColor = [UIColor colorWithRed:0.086 green:0.125 blue:0.196 alpha:1.0]; label.layer.cornerRadius = 13.0; label.layer.masksToBounds = YES;
  label.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
  [label.heightAnchor constraintGreaterThanOrEqualToConstant:56.0].active = YES;
  return label;
}
- (void)viewDidLoad
{
  [super viewDidLoad]; self.title = @"Battery diagnostics"; self.view.backgroundColor = [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:1.0];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Energy" style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshHistory)];
  self.packRecords = [NSMutableArray array]; self.latestCells = [NSMutableDictionary dictionary]; self.auxRecords = [NSMutableArray array];
  UIScrollView *scroll = [[UIScrollView alloc] init]; scroll.translatesAutoresizingMaskIntoConstraints = NO; [self.view addSubview:scroll];
  UIStackView *content = [[UIStackView alloc] init]; content.translatesAutoresizingMaskIntoConstraints = NO; content.axis = UILayoutConstraintAxisVertical; content.spacing = 10.0; [scroll addSubview:content];
  [NSLayoutConstraint activateConstraints:@[[scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor], [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor], [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:16], [content.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:16], [content.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-16], [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20]]];
  UILabel *heading = [[UILabel alloc] init]; heading.text = @"Live pack health"; heading.textColor = [UIColor whiteColor]; heading.font = [UIFont systemFontOfSize:30 weight:UIFontWeightSemibold]; [content addArrangedSubview:heading];
  UILabel *note = [[UILabel alloc] init]; note.text = @"Values are reported by the vehicle module; unavailable metrics are shown explicitly."; note.textColor = [UIColor colorWithWhite:0.68 alpha:1]; note.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]; note.numberOfLines = 0; [content addArrangedSubview:note];
  for (NSInteger tag = 320; tag <= 325; tag++) [content addArrangedSubview:[self line:@"--" tag:tag]];
  UILabel *load = [self line:@"HISTORY\nTap refresh to retrieve pack, cell and 12 V records" tag:326]; load.accessibilityIdentifier = @"battery-history-status"; [content addArrangedSubview:load];
  [content addArrangedSubview:[self line:@"CELL STATUS\nNo cell data loaded" tag:327]];
  OVMSSparklineView *cells = [[OVMSSparklineView alloc] init]; cells.tag=330; cells.layer.cornerRadius=13; cells.layer.masksToBounds=YES; cells.accessibilityLabel=@"Cell voltage and temperature chart"; [cells.heightAnchor constraintEqualToConstant:170].active=YES; [content addArrangedSubview:cells];
  [content addArrangedSubview:[self line:@"PACK HISTORY\nNo history loaded" tag:328]];
  OVMSSparklineView *pack = [[OVMSSparklineView alloc] init]; pack.tag=331; pack.layer.cornerRadius=13; pack.layer.masksToBounds=YES; pack.accessibilityLabel=@"Pack voltage and temperature history chart"; [pack.heightAnchor constraintEqualToConstant:170].active=YES; [content addArrangedSubview:pack];
  [content addArrangedSubview:[self line:@"12 V HISTORY\nNo history loaded" tag:329]];
  OVMSSparklineView *aux = [[OVMSSparklineView alloc] init]; aux.tag=332; aux.layer.cornerRadius=13; aux.layer.masksToBounds=YES; aux.accessibilityLabel=@"12 volt battery history chart"; [aux.heightAnchor constraintEqualToConstant:150].active=YES; [content addArrangedSubview:aux];
  [self restoreHistory];
#if DEBUG && TARGET_OS_SIMULATOR
  NSString *scenario=[[[NSProcessInfo processInfo] environment] objectForKey:@"OVMS_SCREENSHOT_SCENARIO"];
  if ([scenario isEqualToString:@"battery-diagnostics"] || [scenario isEqualToString:@"battery-history-loading"]) [self loadScreenshotPreview:[scenario isEqualToString:@"battery-history-loading"]];
#endif
  [self update];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [[ovmsAppDelegate myRef] registerForUpdate:self]; [self update]; }
- (void)viewWillDisappear:(BOOL)animated { [self.loadTimeout invalidate]; if (self.loadPhase) [[ovmsAppDelegate myRef] commandCancel]; [[ovmsAppDelegate myRef] deregisterFromUpdate:self]; [super viewWillDisappear:animated]; }
- (NSString *)available:(BOOL)available value:(NSString *)value { return available ? value : @"Unavailable"; }
- (void)update
{
  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  ((UILabel *)[self.view viewWithTag:320]).text = [NSString stringWithFormat:@"STATE OF HEALTH\n%@", [self available:app.car_soh > 0 value:[NSString stringWithFormat:@"%.1f%%", app.car_soh]]];
  ((UILabel *)[self.view viewWithTag:321]).text = [NSString stringWithFormat:@"PACK\n%@  ·  %.1f A", [self available:app.car_battery_voltage > 0 value:[NSString stringWithFormat:@"%.1f V", app.car_battery_voltage]], app.car_battery_current];
  ((UILabel *)[self.view viewWithTag:322]).text = [NSString stringWithFormat:@"CAPACITY\n%@", [self available:app.car_battery_capacity > 0 value:[NSString stringWithFormat:@"%.1f kWh", app.car_battery_capacity]]];
  ((UILabel *)[self.view viewWithTag:323]).text = [NSString stringWithFormat:@"BATTERY TEMPERATURE\n%@", [self available:app.car_tbattery > -100 value:[NSString stringWithFormat:@"%d°", app.car_tbattery]]];
  ((UILabel *)[self.view viewWithTag:324]).text = [NSString stringWithFormat:@"CAC\n%@", [self available:[app.car_cac length] > 0 value:[NSString stringWithFormat:@"%@ Ah", app.car_cac]]];
  time_t age = time(0) - app.car_lastupdated;
  ((UILabel *)[self.view viewWithTag:325]).text = app.car_lastupdated > 0 ? [NSString stringWithFormat:@"DATA AGE\n%ld seconds", (long)MAX(0, age)] : @"DATA AGE\nUnavailable";
}
- (NSString *)historyKey:(NSString *)kind { return [NSString stringWithFormat:@"batteryHistory.%@.%@", [ovmsAppDelegate myRef].sel_car ?: @"vehicle", kind]; }
- (void)restoreHistory
{
  NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults]; NSArray *pack=[defaults arrayForKey:[self historyKey:@"pack"]]; NSArray *aux=[defaults arrayForKey:[self historyKey:@"aux"]]; NSDictionary *cells=[defaults dictionaryForKey:[self historyKey:@"cells"]];
  if (pack) [self.packRecords addObjectsFromArray:pack]; if (aux) [self.auxRecords addObjectsFromArray:aux]; if (cells) [self.latestCells addEntriesFromDictionary:cells]; [self updateHistoryViews];
}
- (void)saveHistory
{
  NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults]; [defaults setObject:self.packRecords forKey:[self historyKey:@"pack"]]; [defaults setObject:self.auxRecords forKey:[self historyKey:@"aux"]]; [defaults setObject:self.latestCells forKey:[self historyKey:@"cells"]];
}
- (void)refreshHistory
{
  ovmsAppDelegate *app=[ovmsAppDelegate myRef]; if (![app commandIsFree]) { ((UILabel *)[self.view viewWithTag:326]).text=@"HISTORY\nAnother vehicle command is pending"; return; }
  [self.packRecords removeAllObjects]; [self.latestCells removeAllObjects]; [self.auxRecords removeAllObjects]; [self beginHistoryPhase:@"snapshot" command:@"206"];
}
- (void)beginHistoryPhase:(NSString *)phase command:(NSString *)command
{
  self.loadPhase=phase; ((UILabel *)[self.view viewWithTag:326]).text=[NSString stringWithFormat:@"HISTORY\nLoading %@ records…", [phase isEqualToString:@"aux"] ? @"12 V" : phase]; self.navigationItem.rightBarButtonItem.enabled=NO;
  [[ovmsAppDelegate myRef] commandRegister:command callback:self]; [self.loadTimeout invalidate]; self.loadTimeout=[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(historyTimedOut:) userInfo:nil repeats:NO];
}
- (void)historyTimedOut:(NSTimer *)timer
{
  [[ovmsAppDelegate myRef] commandCancel]; self.loadPhase=nil; self.loadTimeout=nil; self.navigationItem.rightBarButtonItem.enabled=YES; ((UILabel *)[self.view viewWithTag:326]).text=@"HISTORY\nRequest timed out; existing vehicle data was not replaced";
}
- (void)advanceHistoryPhase
{
  [self.loadTimeout invalidate]; self.loadTimeout=nil; [[ovmsAppDelegate myRef] commandCancel];
  if ([self.loadPhase isEqualToString:@"snapshot"]) { [self beginHistoryPhase:@"pack" command:@"32,RT-BAT-P"]; return; }
  if ([self.loadPhase isEqualToString:@"pack"]) { [self beginHistoryPhase:@"cells" command:@"32,RT-BAT-C"]; return; }
  if ([self.loadPhase isEqualToString:@"cells"]) { [self beginHistoryPhase:@"aux" command:@"32,D"]; return; }
  self.loadPhase=nil; self.navigationItem.rightBarButtonItem.enabled=YES; [self saveHistory]; [self updateHistoryViews]; ((UILabel *)[self.view viewWithTag:326]).text=[NSString stringWithFormat:@"HISTORY\nLoaded %lu pack, %lu cell and %lu 12 V records",(unsigned long)self.packRecords.count,(unsigned long)self.latestCells.count,(unsigned long)self.auxRecords.count];
}
- (void)commandResult:(NSArray *)result
{
  if (!self.loadPhase || result.count<2) return; NSInteger code=[result[1] integerValue];
  if ([self.loadPhase isEqualToString:@"snapshot"] && code==0) { [self advanceHistoryPhase]; return; }
  if (result.count<3) return;
  if ([result[2] isEqual:@"No historical data available"]) { [self advanceHistoryPhase]; return; }
  if (code!=0) { [self.loadTimeout invalidate]; [[ovmsAppDelegate myRef] commandCancel]; NSString *phase=self.loadPhase; self.loadPhase=nil; self.navigationItem.rightBarButtonItem.enabled=YES; ((UILabel *)[self.view viewWithTag:326]).text=[NSString stringWithFormat:@"HISTORY\n%@ data unavailable: %@",phase,result.count>2?result[2]:@"vehicle rejected request"]; return; }
  if (result.count<6) return; NSString *type=result[4];
  @try {
    if ([type isEqualToString:@"RT-BAT-P"] && result.count>21) [self.packRecords addObject:@{@"time":result[5],@"voltAlert":@([result[7] integerValue]),@"tempAlert":@([result[8] integerValue]),@"soc":@([result[9] doubleValue]/100.0),@"volt":@([result[12] doubleValue]/10.0),@"voltMin":@([result[13] doubleValue]/10.0),@"temp":@([result[15] doubleValue]),@"voltDev":@([result[18] doubleValue]/100.0),@"tempDev":@([result[19] doubleValue])}];
    else if ([type isEqualToString:@"RT-BAT-C"] && result.count>16) self.latestCells[result[6]]=@{@"voltAlert":@([result[7] integerValue]),@"tempAlert":@([result[8] integerValue]),@"volt":@([result[9] doubleValue]/1000.0),@"voltMin":@([result[10] doubleValue]/1000.0),@"voltMax":@([result[11] doubleValue]/1000.0),@"voltDev":@([result[12] doubleValue]/1000.0),@"temp":@([result[13] doubleValue]),@"tempMin":@([result[14] doubleValue]),@"tempMax":@([result[15] doubleValue]),@"tempDev":@([result[16] doubleValue])};
    else if ([type isEqualToString:@"D"] && result.count>21) [self.auxRecords addObject:@{@"time":result[5],@"volt":@([result[21] doubleValue]),@"voltRef":@(result.count>23?[result[23] doubleValue]:0),@"current":@(result.count>26?[result[26] doubleValue]:0),@"ambient":@([result[17] doubleValue]),@"charger":@(result.count>25?[result[25] doubleValue]:0)}];
  } @catch (NSException *exception) { }
  if ([result[2] integerValue]==[result[3] integerValue]) [self advanceHistoryPhase];
}
- (void)updateHistoryViews
{
  NSArray *cellKeys=[[self.latestCells allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *a,NSString *b){ return [a integerValue]<[b integerValue]?NSOrderedAscending:([a integerValue]>[b integerValue]?NSOrderedDescending:NSOrderedSame); }]; NSMutableArray *cellVolts=[NSMutableArray array],*cellTemps=[NSMutableArray array]; NSInteger alerts=0;
  for (NSString *key in cellKeys) { NSDictionary *cell=self.latestCells[key]; [cellVolts addObject:cell[@"volt"]]; [cellTemps addObject:cell[@"temp"]]; if ([cell[@"voltAlert"] integerValue]||[cell[@"tempAlert"] integerValue]) alerts++; }
  double minV=DBL_MAX,maxV=-DBL_MAX,minT=DBL_MAX,maxT=-DBL_MAX; for(NSNumber*n in cellVolts){minV=MIN(minV,n.doubleValue);maxV=MAX(maxV,n.doubleValue);} for(NSNumber*n in cellTemps){minT=MIN(minT,n.doubleValue);maxT=MAX(maxT,n.doubleValue);}
  ((UILabel *)[self.view viewWithTag:327]).text=cellKeys.count?[NSString stringWithFormat:@"CELL STATUS\n%lu cells  ·  %.3f–%.3f V (Δ %.0f mV)\n%.0f–%.0f°  ·  %ld alert%@  ·  green V / orange °",(unsigned long)cellKeys.count,minV,maxV,(maxV-minV)*1000,minT,maxT,(long)alerts,alerts==1?@"":@"s"]:@"CELL STATUS\nNo cell data loaded";
  OVMSSparklineView *cellChart=(OVMSSparklineView *)[self.view viewWithTag:330]; cellChart.series=@[cellVolts,cellTemps]; cellChart.colors=@[[UIColor colorWithRed:.30 green:.82 blue:.42 alpha:1],[UIColor colorWithRed:.96 green:.56 blue:.22 alpha:1]];
  NSMutableArray *packV=[NSMutableArray array],*packT=[NSMutableArray array]; for(NSDictionary*r in self.packRecords){[packV addObject:r[@"volt"]];[packT addObject:r[@"temp"]];} OVMSSparklineView *packChart=(OVMSSparklineView *)[self.view viewWithTag:331]; packChart.series=@[packV,packT]; packChart.colors=cellChart.colors;
  NSDictionary *lastPack=self.packRecords.lastObject; ((UILabel *)[self.view viewWithTag:328]).text=lastPack?[NSString stringWithFormat:@"PACK HISTORY\n%lu samples  ·  latest %.1f V / %.0f°\nMax deviations %.0f mV / %.1f°",(unsigned long)self.packRecords.count,[lastPack[@"volt"] doubleValue],[lastPack[@"temp"] doubleValue],[lastPack[@"voltDev"] doubleValue]*1000,[lastPack[@"tempDev"] doubleValue]]:@"PACK HISTORY\nNo history loaded";
  NSMutableArray *auxV=[NSMutableArray array],*auxRef=[NSMutableArray array]; for(NSDictionary*r in self.auxRecords){[auxV addObject:r[@"volt"]];[auxRef addObject:r[@"voltRef"]];} OVMSSparklineView *auxChart=(OVMSSparklineView *)[self.view viewWithTag:332]; auxChart.series=@[auxV,auxRef]; auxChart.colors=@[[UIColor colorWithRed:.35 green:.75 blue:1 alpha:1],[UIColor colorWithWhite:.7 alpha:1]];
  NSDictionary *lastAux=self.auxRecords.lastObject; ((UILabel *)[self.view viewWithTag:329]).text=lastAux?[NSString stringWithFormat:@"12 V HISTORY\n%lu samples  ·  latest %.2f V (reference %.2f V)\n%.2f A  ·  ambient %.0f°",(unsigned long)self.auxRecords.count,[lastAux[@"volt"] doubleValue],[lastAux[@"voltRef"] doubleValue],[lastAux[@"current"] doubleValue],[lastAux[@"ambient"] doubleValue]]:@"12 V HISTORY\nNo history loaded";
}
- (void)loadScreenshotPreview:(BOOL)loading
{
  [self.packRecords removeAllObjects]; [self.latestCells removeAllObjects]; [self.auxRecords removeAllObjects];
  for (NSInteger i=0;i<18;i++) [self.packRecords addObject:@{@"time":@"2026-09-05 12:00:00",@"voltAlert":@0,@"tempAlert":@0,@"soc":@(78-i*.35),@"volt":@(397.2-i*.18),@"voltMin":@(395.8-i*.19),@"temp":@(24+sin(i/3.0)),@"voltDev":@(.027+i*.0003),@"tempDev":@(1.4)}];
  for (NSInteger i=1;i<=96;i++) self.latestCells[[NSString stringWithFormat:@"%ld",(long)i]]=@{@"voltAlert":@(i==47),@"tempAlert":@0,@"volt":@(4.112+sin(i*.43)*.009-(i==47?.021:0)),@"voltMin":@(4.071+sin(i*.31)*.008),@"voltMax":@(4.129+sin(i*.29)*.006),@"voltDev":@(i==47?-.021:.007),@"temp":@(24+sin(i*.19)*2),@"tempMin":@(20),@"tempMax":@(28),@"tempDev":@(2)};
  for (NSInteger i=0;i<24;i++) [self.auxRecords addObject:@{@"time":@"2026-09-05 12:00:00",@"volt":@(12.54+sin(i*.38)*.18),@"voltRef":@(12.60),@"current":@(-.35+sin(i*.27)*.12),@"ambient":@(18),@"charger":@(25)}];
  [self updateHistoryViews];
  ((UILabel *)[self.view viewWithTag:326]).text=loading?@"HISTORY\nLoading cell records… 64 of 96":@"HISTORY\nLoaded 18 pack, 96 cell and 24 12 V records";
  self.navigationItem.rightBarButtonItem.enabled=!loading;
}
- (void)close:(id)sender { [self.navigationController popViewControllerAnimated:YES]; }
@end

@interface OVMSEnergyViewController : UIViewController <ovmsUpdateDelegate>
@property (strong, nonatomic) NSMutableArray *powerHistory;
@property (assign, nonatomic) NSTimeInterval lastPowerSample;
- (void)openBatteryDiagnostics;
@end

@implementation OVMSEnergyViewController

- (UILabel *)energyLabel:(NSString *)text size:(CGFloat)size
{
  UILabel *label = [[UILabel alloc] init];
  label.text = text; label.textColor = [UIColor whiteColor];
  label.font = [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
  label.numberOfLines = 0;
  return label;
}

- (UIView *)energyMetric:(NSString *)title tag:(NSInteger)tag
{
  UIStackView *card = [[UIStackView alloc] init];
  card.axis = UILayoutConstraintAxisVertical; card.spacing = 5.0;
  card.layoutMargins = UIEdgeInsetsMake(13, 14, 13, 14); card.layoutMarginsRelativeArrangement = YES;
  card.backgroundColor = [UIColor colorWithRed:0.086 green:0.125 blue:0.196 alpha:1.0]; card.layer.cornerRadius = 14.0;
  UILabel *heading = [self energyLabel:title size:12.0]; heading.textColor = [UIColor colorWithWhite:0.68 alpha:1.0];
  UILabel *value = [self energyLabel:@"--" size:21.0]; value.tag = tag;
  [card addArrangedSubview:heading]; [card addArrangedSubview:value];
  return card;
}

- (void)viewDidLoad
{
  [super viewDidLoad]; self.title = @"Energy";
  NSArray *savedPower = [[NSUserDefaults standardUserDefaults] arrayForKey:[self powerHistoryKey]];
  self.powerHistory = savedPower ? [savedPower mutableCopy] : [NSMutableArray array];
  self.view.backgroundColor = [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:1.0];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close:)];
  UIScrollView *scroll = [[UIScrollView alloc] init]; scroll.translatesAutoresizingMaskIntoConstraints = NO; [self.view addSubview:scroll];
  UIStackView *content = [[UIStackView alloc] init]; content.translatesAutoresizingMaskIntoConstraints = NO; content.axis = UILayoutConstraintAxisVertical; content.spacing = 12.0; [scroll addSubview:content];
  [NSLayoutConstraint activateConstraints:@[
    [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor], [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:16.0], [content.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:16.0], [content.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-16.0], [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20.0]
  ]];
  UILabel *soc = [self energyLabel:@"--" size:48.0]; soc.tag = 300; [content addArrangedSubview:soc];
  UILabel *health = [self energyLabel:@"Battery health --" size:18.0]; health.tag = 301; health.textColor = [UIColor colorWithRed:0.34 green:0.84 blue:0.51 alpha:1.0]; [content addArrangedSubview:health];
  UIStackView *row1 = [[UIStackView alloc] init]; row1.axis = UILayoutConstraintAxisHorizontal; row1.distribution = UIStackViewDistributionFillEqually; row1.spacing = 12.0;
  [row1 addArrangedSubview:[self energyMetric:@"BATTERY VOLTAGE" tag:302]]; [row1 addArrangedSubview:[self energyMetric:@"BATTERY CURRENT" tag:303]]; [content addArrangedSubview:row1];
  UIStackView *row2 = [[UIStackView alloc] init]; row2.axis = UILayoutConstraintAxisHorizontal; row2.distribution = UIStackViewDistributionFillEqually; row2.spacing = 12.0;
  [row2 addArrangedSubview:[self energyMetric:@"POWER" tag:304]]; [row2 addArrangedSubview:[self energyMetric:@"CAPACITY" tag:305]]; [content addArrangedSubview:row2];
  [content addArrangedSubview:[self energyMetric:@"LAST TRIP" tag:306]];
  [content addArrangedSubview:[self energyMetric:@"ENERGY USED / REGENERATED" tag:307]];
  [content addArrangedSubview:[self energyMetric:@"12 V BATTERY" tag:308]];
  [content addArrangedSubview:[self energyMetric:@"RECENT TRACTION POWER" tag:309]];
  OVMSSparklineView *powerChart = [[OVMSSparklineView alloc] init]; powerChart.tag = 310; powerChart.layer.cornerRadius = 13.0; powerChart.layer.masksToBounds = YES;
  powerChart.accessibilityLabel = @"Recent traction power chart; values above zero are consumption and values below zero are regeneration";
  [powerChart.heightAnchor constraintEqualToConstant:180.0].active = YES; [content addArrangedSubview:powerChart];
  UIButton *details = [UIButton buttonWithType:UIButtonTypeSystem]; details.backgroundColor = [UIColor colorWithRed:0.45 green:0.30 blue:0.70 alpha:1.0]; details.layer.cornerRadius = 12.0;
  details.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]; [details setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; [details setTitle:@"Battery diagnostics" forState:UIControlStateNormal];
  [details addTarget:self action:@selector(openBatteryDiagnostics) forControlEvents:UIControlEventTouchUpInside]; [details.heightAnchor constraintEqualToConstant:52.0].active = YES; [content addArrangedSubview:details];
#if DEBUG && TARGET_OS_SIMULATOR
  if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"OVMS_SCREENSHOT_SCENARIO"] isEqualToString:@"energy"] && self.powerHistory.count < 2)
    for (NSInteger index=0; index<40; index++) [self.powerHistory addObject:@{@"time":@(index), @"power":@(8.0*sin(index*.24)-2.5*cos(index*.51))}];
#endif
  [self update];
}
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [[ovmsAppDelegate myRef] registerForUpdate:self]; [self update]; }
- (void)viewWillDisappear:(BOOL)animated { [[ovmsAppDelegate myRef] deregisterFromUpdate:self]; [super viewWillDisappear:animated]; }
- (void)update
{
  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  [self recordPowerSample:app.car_power timestamp:app.car_lastupdated];
  double trip = app.car_trip / 10.0; double net = app.car_energyused - app.car_energyrecd;
  double consumption = trip > 0 ? net * 1000.0 / trip : 0;
  NSString *units = [app.car_units isEqualToString:@"K"] ? @"km" : @"mi";
  ((UILabel *)[self.view viewWithTag:300]).text = [NSString stringWithFormat:@"%d%%", app.car_soc];
  ((UILabel *)[self.view viewWithTag:301]).text = app.car_soh > 0 ? [NSString stringWithFormat:@"Battery health %.1f%%", app.car_soh] : @"Battery health unavailable";
  ((UILabel *)[self.view viewWithTag:302]).text = app.car_battery_voltage > 0 ? [NSString stringWithFormat:@"%.1f V", app.car_battery_voltage] : @"--";
  ((UILabel *)[self.view viewWithTag:303]).text = [NSString stringWithFormat:@"%.1f A", app.car_battery_current];
  ((UILabel *)[self.view viewWithTag:304]).text = [NSString stringWithFormat:@"%.2f kW", app.car_power];
  ((UILabel *)[self.view viewWithTag:305]).text = app.car_battery_capacity > 0 ? [NSString stringWithFormat:@"%.1f kWh", app.car_battery_capacity] : ([app.car_cac length] ? [NSString stringWithFormat:@"%@ Ah", app.car_cac] : @"--");
  ((UILabel *)[self.view viewWithTag:306]).text = [NSString stringWithFormat:@"%.1f %@  ·  %.1f Wh/%@", trip, units, consumption, units];
  ((UILabel *)[self.view viewWithTag:307]).text = [NSString stringWithFormat:@"%.2f kWh used  ·  %.2f kWh regen", app.car_energyused, app.car_energyrecd];
  ((UILabel *)[self.view viewWithTag:308]).text = app.car_aux_battery_voltage > 0 ? [NSString stringWithFormat:@"%.2f V", app.car_aux_battery_voltage] : @"--";
  NSArray *values = [self.powerHistory valueForKey:@"power"];
  OVMSSparklineView *chart = (OVMSSparklineView *)[self.view viewWithTag:310]; chart.series = values.count ? @[values] : @[]; chart.colors = @[[UIColor colorWithRed:.30 green:.82 blue:.62 alpha:1]];
  double minimum=DBL_MAX, maximum=-DBL_MAX; for (NSNumber *value in values) { minimum=MIN(minimum,value.doubleValue); maximum=MAX(maximum,value.doubleValue); }
  ((UILabel *)[self.view viewWithTag:309]).text = values.count ? [NSString stringWithFormat:@"%lu samples  ·  %.1f to %.1f kW\nPositive: consumption  ·  Negative: regeneration",(unsigned long)values.count,minimum,maximum] : @"Waiting for live power samples";
}
- (NSString *)powerHistoryKey { return [NSString stringWithFormat:@"energyPowerHistory.%@", [ovmsAppDelegate myRef].sel_car ?: @"vehicle"]; }
- (void)recordPowerSample:(double)power timestamp:(time_t)timestamp
{
  if (timestamp <= 0 || !isfinite(power) || (self.lastPowerSample > 0 && timestamp-self.lastPowerSample < 15)) return;
  NSDictionary *last=self.powerHistory.lastObject; if (last && [last[@"time"] doubleValue] == timestamp) return;
  self.lastPowerSample=timestamp; [self.powerHistory addObject:@{@"time":@(timestamp),@"power":@(power)}];
  while (self.powerHistory.count > 120) [self.powerHistory removeObjectAtIndex:0];
  [[NSUserDefaults standardUserDefaults] setObject:self.powerHistory forKey:[self powerHistoryKey]];
}
- (void)close:(id)sender { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)openBatteryDiagnostics { [self.navigationController pushViewController:[[OVMSBatteryDiagnosticsViewController alloc] init] animated:YES]; }
@end

@interface OVMSClimateViewController : UIViewController <ovmsUpdateDelegate>
- (void)showClimateConfirmation:(BOOL)turnOn;
- (void)showClimateSchedule;
- (void)showClimateScheduleAdvanced;
- (void)showClearDaySchedule;
- (void)showCopySchedule;
- (void)showClearScheduleConfirmation;
@end

@implementation OVMSClimateViewController

- (UILabel *)climateLabel:(NSString *)text size:(CGFloat)size
{
  UILabel *label = [[UILabel alloc] init];
  label.text = text;
  label.textColor = [UIColor whiteColor];
  label.font = [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
  label.textAlignment = NSTextAlignmentCenter;
  label.numberOfLines = 0;
  return label;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Climate";
  self.view.backgroundColor = [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:1.0];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close:)];

  UIStackView *content = [[UIStackView alloc] init];
  content.translatesAutoresizingMaskIntoConstraints = NO;
  content.axis = UILayoutConstraintAxisVertical;
  content.spacing = 18.0;
  content.alignment = UIStackViewAlignmentFill;
  [self.view addSubview:content];
  [NSLayoutConstraint activateConstraints:@[
    [content.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24.0],
    [content.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
    [content.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0]
  ]];

  UILabel *state = [self climateLabel:@"Climate off" size:25.0]; state.tag = 210;
  state.textColor = [UIColor colorWithRed:0.35 green:0.82 blue:0.98 alpha:1.0];
  [content addArrangedSubview:state];
  UIImageView *car = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[ovmsAppDelegate myRef].sel_imagepath]];
  car.contentMode = UIViewContentModeScaleAspectFit;
  [car.heightAnchor constraintEqualToConstant:180.0].active = YES;
  [content addArrangedSubview:car];

  UIStackView *temperatures = [[UIStackView alloc] init];
  temperatures.axis = UILayoutConstraintAxisHorizontal;
  temperatures.distribution = UIStackViewDistributionFillEqually;
  temperatures.spacing = 12.0;
  UILabel *outside = [self climateLabel:@"--\nOUTSIDE" size:24.0]; outside.tag = 211;
  UILabel *inside = [self climateLabel:@"--\nCABIN" size:24.0]; inside.tag = 212;
  for (UILabel *label in @[outside, inside]) { label.backgroundColor = [UIColor colorWithRed:0.086 green:0.125 blue:0.196 alpha:1.0]; label.layer.cornerRadius = 14.0; label.layer.masksToBounds = YES; [label.heightAnchor constraintEqualToConstant:105.0].active = YES; [temperatures addArrangedSubview:label]; }
  [content addArrangedSubview:temperatures];

  UILabel *note = [self climateLabel:@"Remote climate uses the vehicle's configured target temperature." size:14.0];
  note.textColor = [UIColor colorWithWhite:0.70 alpha:1.0];
  [content addArrangedSubview:note];
  UIButton *toggle = [UIButton buttonWithType:UIButtonTypeSystem];
  toggle.tag = 213; toggle.layer.cornerRadius = 13.0; toggle.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [toggle setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [toggle.heightAnchor constraintEqualToConstant:54.0].active = YES;
  [toggle addTarget:self action:@selector(toggleClimate) forControlEvents:UIControlEventTouchUpInside];
  [content addArrangedSubview:toggle];
  UIStackView *scheduleActions = [[UIStackView alloc] init]; scheduleActions.axis = UILayoutConstraintAxisHorizontal; scheduleActions.distribution = UIStackViewDistributionFillEqually; scheduleActions.spacing = 12;
  UIButton *schedule = [UIButton buttonWithType:UIButtonTypeSystem]; schedule.backgroundColor = [UIColor colorWithRed:0.45 green:0.30 blue:0.70 alpha:1]; schedule.layer.cornerRadius = 12; [schedule setTitle:@"Climate schedule" forState:UIControlStateNormal]; [schedule setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; schedule.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]; [schedule addTarget:self action:@selector(showClimateSchedule) forControlEvents:UIControlEventTouchUpInside]; [schedule.heightAnchor constraintEqualToConstant:48].active = YES; [scheduleActions addArrangedSubview:schedule];
  UIButton *clear = [UIButton buttonWithType:UIButtonTypeSystem]; clear.backgroundColor = [UIColor colorWithRed:0.34 green:0.20 blue:0.24 alpha:1]; clear.layer.cornerRadius = 12; [clear setTitle:@"Clear schedule" forState:UIControlStateNormal]; [clear setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; clear.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]; [clear addTarget:self action:@selector(showClearScheduleConfirmation) forControlEvents:UIControlEventTouchUpInside]; [clear.heightAnchor constraintEqualToConstant:48].active = YES; [scheduleActions addArrangedSubview:clear];
  [content addArrangedSubview:scheduleActions];
  [self update];
}

- (BOOL)climateOn { return ([ovmsAppDelegate myRef].car_doors5 & 0x80) != 0; }
- (void)viewWillAppear:(BOOL)animated { [super viewWillAppear:animated]; [[ovmsAppDelegate myRef] registerForUpdate:self]; [self update]; }
- (void)viewWillDisappear:(BOOL)animated { [[ovmsAppDelegate myRef] deregisterFromUpdate:self]; [super viewWillDisappear:animated]; }
- (void)update
{
  ovmsAppDelegate *app = [ovmsAppDelegate myRef]; BOOL on = [self climateOn];
  ((UILabel *)[self.view viewWithTag:210]).text = on ? @"Climate running" : @"Climate off";
  ((UILabel *)[self.view viewWithTag:211]).text = app.car_ambient_temp > -100 ? [NSString stringWithFormat:@"%d°\nOUTSIDE", app.car_ambient_temp] : @"--\nOUTSIDE";
  ((UILabel *)[self.view viewWithTag:212]).text = app.car_cabin_temp > -100 ? [NSString stringWithFormat:@"%d°\nCABIN", app.car_cabin_temp] : @"--\nCABIN";
  UIButton *toggle = (UIButton *)[self.view viewWithTag:213];
  [toggle setTitle:on ? @"Turn climate off" : @"Turn climate on" forState:UIControlStateNormal];
  toggle.backgroundColor = on ? [UIColor colorWithRed:0.72 green:0.20 blue:0.20 alpha:1.0] : [UIColor colorWithRed:0.10 green:0.50 blue:0.72 alpha:1.0];
}
- (void)toggleClimate { [self showClimateConfirmation:![self climateOn]]; }
- (void)showClimateConfirmation:(BOOL)turnOn
{
  NSString *verb = turnOn ? @"Start" : @"Stop";
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ climate?", verb] message:turnOn ? @"Remote climate will start using the vehicle's configured temperature." : @"Remote climate will be switched off." preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:verb style:turnOn ? UIAlertActionStyleDefault : UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { [[ovmsAppDelegate myRef] commandIssue:[NSString stringWithFormat:@"26,%d", turnOn ? 1 : 0]]; }]];
  [self presentViewController:alert animated:YES completion:nil];
}
- (NSString *)climateScheduleKey { return [NSString stringWithFormat:@"climateScheduleEnabled.%@", [ovmsAppDelegate myRef].sel_car ?: @"vehicle"]; }
- (NSArray *)scheduleDays { return @[@"mon", @"tue", @"wed", @"thu", @"fri", @"sat", @"sun"]; }
- (BOOL)isValidScheduleDay:(NSString *)day { return [[self scheduleDays] containsObject:[day lowercaseString]]; }
- (BOOL)areValidScheduleDays:(NSString *)days
{
  NSArray *parts = [[days lowercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
  BOOL found = NO;
  for (NSString *day in parts) if (day.length) { found = YES; if (![self isValidScheduleDay:day]) return NO; }
  return found;
}
- (void)showScheduleValidationError:(NSString *)message
{
  UIAlertController *error = [UIAlertController alertControllerWithTitle:@"Check schedule" message:message preferredStyle:UIAlertControllerStyleAlert];
  [error addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:error animated:YES completion:nil];
}
- (void)showClimateSchedule
{
  BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:[self climateScheduleKey]];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Climate schedule" message:@"Times use the vehicle module's local clock. Add /minutes for run time, for example 07:30/15." preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"Day (mon-sun)"; field.text = @"mon"; field.autocapitalizationType = UITextAutocapitalizationTypeNone; }];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"Times (07:30/15, 17:00/10)"; field.text = @"07:30/15"; }];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"More…" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [self showClimateScheduleAdvanced]; }]];
  [alert addAction:[UIAlertAction actionWithTitle:enabled ? @"Disable" : @"Enable" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    BOOL next = !enabled; [[NSUserDefaults standardUserDefaults] setBool:next forKey:[self climateScheduleKey]];
    [[ovmsAppDelegate myRef] commandDoCommand:next ? @"climatecontrol schedule enable" : @"climatecontrol schedule disable"];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSString *day = [alert.textFields[0].text lowercaseString]; NSString *times = alert.textFields[1].text;
    NSSet *validDays = [NSSet setWithArray:@[@"mon", @"tue", @"wed", @"thu", @"fri", @"sat", @"sun"]];
    if (![validDays containsObject:day]) { [self showScheduleValidationError:@"Use a day from mon through sun."]; return; }
    if (!times.length) { [self showScheduleValidationError:@"Enter at least one start time."]; return; }
    [[ovmsAppDelegate myRef] commandDoCommand:[NSString stringWithFormat:@"climatecontrol schedule set %@ %@", day, times]];
  }]];
  [[ovmsAppDelegate myRef] commandDoCommand:@"climatecontrol schedule status"];
  [[ovmsAppDelegate myRef] commandDoCommand:@"climatecontrol schedule list"];
  [self presentViewController:alert animated:YES completion:nil];
}
- (void)showClimateScheduleAdvanced
{
  UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Schedule options" message:@"Manage schedules stored by the vehicle module." preferredStyle:UIAlertControllerStyleActionSheet];
  [sheet addAction:[UIAlertAction actionWithTitle:@"List schedules" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [[ovmsAppDelegate myRef] commandDoCommand:@"climatecontrol schedule list"]; }]];
  [sheet addAction:[UIAlertAction actionWithTitle:@"Clear a day" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [self showClearDaySchedule]; }]];
  [sheet addAction:[UIAlertAction actionWithTitle:@"Copy a day" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [self showCopySchedule]; }]];
  [sheet addAction:[UIAlertAction actionWithTitle:@"Clear all" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { [self showClearScheduleConfirmation]; }]];
  [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  UIPopoverPresentationController *popover = sheet.popoverPresentationController;
  if (popover) { popover.sourceView = self.view; popover.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1); popover.permittedArrowDirections = 0; }
  [self presentViewController:sheet animated:YES completion:nil];
}
- (void)showClearDaySchedule
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear one day" message:@"Enter the vehicle-local weekday to remove." preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"Day (mon-sun)"; field.text = @"mon"; field.autocapitalizationType = UITextAutocapitalizationTypeNone; }];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
    NSString *day = [alert.textFields.firstObject.text lowercaseString];
    if (![self isValidScheduleDay:day]) { [self showScheduleValidationError:@"Use a day from mon through sun."]; return; }
    [[ovmsAppDelegate myRef] commandDoCommand:[NSString stringWithFormat:@"climatecontrol schedule clear %@", day]];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}
- (void)showCopySchedule
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Copy schedule" message:@"Copy one day's times to one or more target days." preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"Source day (mon-sun)"; field.text = @"mon"; field.autocapitalizationType = UITextAutocapitalizationTypeNone; }];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"Target days (tue,wed,thu)"; field.text = @"tue,wed,thu,fri"; field.autocapitalizationType = UITextAutocapitalizationTypeNone; }];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSString *source = [alert.textFields[0].text lowercaseString]; NSString *targets = [alert.textFields[1].text lowercaseString];
    if (![self isValidScheduleDay:source] || ![self areValidScheduleDays:targets]) { [self showScheduleValidationError:@"Use mon-sun abbreviations and separate target days with commas."]; return; }
    [[ovmsAppDelegate myRef] commandDoCommand:[NSString stringWithFormat:@"climatecontrol schedule copy %@ %@", source, targets]];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}
- (void)showClearScheduleConfirmation
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear all climate schedules?" message:@"Every scheduled climate start for this vehicle will be removed." preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Clear all" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { [[ovmsAppDelegate myRef] commandDoCommand:@"climatecontrol schedule clear all"]; }]];
  [self presentViewController:alert animated:YES completion:nil];
}
- (void)close:(id)sender { [self dismissViewControllerAnimated:YES completion:nil]; }
@end

@interface OVMSChargingViewController : UIViewController <ovmsUpdateDelegate, ovmsCommandDelegate>
@property (strong, nonatomic) NSTimer *commandTimeout;
@property (copy, nonatomic) NSString *pendingAction;
@property (copy, nonatomic) NSString *pendingFollowupCommand;
- (void)showStartConfirmation;
- (void)showStopConfirmation;
- (void)showChargingSettings;
- (void)showCommandPreview:(NSString *)status pending:(BOOL)pending;
@end

@implementation OVMSChargingViewController

- (UILabel *)valueLabel:(NSString *)text size:(CGFloat)size
{
  UILabel *label = [[UILabel alloc] init];
  label.text = text;
  label.textColor = [UIColor whiteColor];
  label.font = [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
  label.numberOfLines = 0;
  return label;
}

- (UIView *)metricWithTitle:(NSString *)title value:(NSString *)value tag:(NSInteger)tag
{
  UIStackView *stack = [[UIStackView alloc] init];
  stack.axis = UILayoutConstraintAxisVertical;
  stack.spacing = 5.0;
  stack.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
  stack.layoutMarginsRelativeArrangement = YES;
  stack.backgroundColor = [UIColor colorWithRed:0.086 green:0.125 blue:0.196 alpha:1.0];
  stack.layer.cornerRadius = 14.0;
  UILabel *heading = [self valueLabel:title size:12.0];
  heading.textColor = [UIColor colorWithWhite:0.70 alpha:1.0];
  [stack addArrangedSubview:heading];
  UILabel *valueLabel = [self valueLabel:value size:21.0];
  valueLabel.tag = tag;
  [stack addArrangedSubview:valueLabel];
  return stack;
}

- (UIButton *)actionButton:(NSString *)title selector:(SEL)selector color:(UIColor *)color
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.backgroundColor = color;
  button.layer.cornerRadius = 12.0;
  button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
  [button.heightAnchor constraintEqualToConstant:50.0].active = YES;
  return button;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Charging";
  self.view.backgroundColor = [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:1.0];
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                           target:self
                           action:@selector(close:)];

  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  UIScrollView *scroll = [[UIScrollView alloc] init];
  scroll.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:scroll];
  UIStackView *content = [[UIStackView alloc] init];
  content.translatesAutoresizingMaskIntoConstraints = NO;
  content.axis = UILayoutConstraintAxisVertical;
  content.spacing = 12.0;
  [scroll addSubview:content];
  [NSLayoutConstraint activateConstraints:@[
    [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
    [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:16.0],
    [content.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:16.0],
    [content.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-16.0],
    [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20.0]
  ]];

  UILabel *soc = [self valueLabel:[NSString stringWithFormat:@"%d%%", app.car_soc] size:52.0];
  soc.tag = 100;
  UILabel *state = [self valueLabel:[app.car_chargestate length] ? [app.car_chargestate capitalizedString] : @"Not charging" size:18.0];
  state.tag = 101;
  state.textColor = [UIColor colorWithRed:0.32 green:0.84 blue:0.48 alpha:1.0];
  [content addArrangedSubview:soc];
  [content addArrangedSubview:state];

  UIStackView *electrical = [[UIStackView alloc] init];
  electrical.axis = UILayoutConstraintAxisHorizontal;
  electrical.distribution = UIStackViewDistributionFillEqually;
  electrical.spacing = 12.0;
  [electrical addArrangedSubview:[self metricWithTitle:@"VOLTAGE" value:[NSString stringWithFormat:@"%d V", app.car_linevoltage] tag:102]];
  [electrical addArrangedSubview:[self metricWithTitle:@"CURRENT" value:[NSString stringWithFormat:@"%d A", app.car_chargecurrent] tag:103]];
  [content addArrangedSubview:electrical];

  double power = (app.car_linevoltage * app.car_chargecurrent) / 1000.0;
  NSString *remaining = app.car_minutestofull > 0
    ? [NSString stringWithFormat:@"%dh %02dm", app.car_minutestofull / 60, app.car_minutestofull % 60]
    : @"—";
  UIStackView *progress = [[UIStackView alloc] init];
  progress.axis = UILayoutConstraintAxisHorizontal;
  progress.distribution = UIStackViewDistributionFillEqually;
  progress.spacing = 12.0;
  [progress addArrangedSubview:[self metricWithTitle:@"POWER" value:[NSString stringWithFormat:@"%.1f kW", power] tag:104]];
  [progress addArrangedSubview:[self metricWithTitle:@"TO FULL" value:remaining tag:105]];
  [content addArrangedSubview:progress];

  NSString *limits = [NSString stringWithFormat:@"Mode: %@\nCurrent limit: %d A\nSOC limit: %@\nRange limit: %@",
                      [app.car_chargemode length] ? [app.car_chargemode capitalizedString] : @"Standard",
                      app.car_chargelimit,
                      app.car_soclimit > 0 ? [NSString stringWithFormat:@"%d%%", app.car_soclimit] : @"Not set",
                      app.car_rangelimit > 0 ? [NSString stringWithFormat:@"%d", app.car_rangelimit] : @"Not set"];
  [content addArrangedSubview:[self metricWithTitle:@"CHARGING LIMITS" value:limits tag:106]];

  UILabel *commandStatus = [self valueLabel:@"Ready" size:14.0];
  commandStatus.tag = 107;
  commandStatus.textColor = [UIColor colorWithWhite:0.70 alpha:1.0];
  commandStatus.accessibilityIdentifier = @"charging-command-status";
  [content addArrangedSubview:commandStatus];

  UIButton *settings = [self actionButton:@"Charging settings" selector:@selector(showChargingSettings) color:[UIColor colorWithRed:0.12 green:0.34 blue:0.62 alpha:1.0]];
  [content addArrangedSubview:settings];
  UIStackView *actions = [[UIStackView alloc] init];
  actions.axis = UILayoutConstraintAxisHorizontal;
  actions.distribution = UIStackViewDistributionFillEqually;
  actions.spacing = 12.0;
  UIButton *start = [self actionButton:@"Start charging" selector:@selector(showStartConfirmation) color:[UIColor colorWithRed:0.12 green:0.55 blue:0.32 alpha:1.0]]; start.tag = 108;
  UIButton *stop = [self actionButton:@"Stop charging" selector:@selector(showStopConfirmation) color:[UIColor colorWithRed:0.72 green:0.20 blue:0.20 alpha:1.0]]; stop.tag = 109;
  [actions addArrangedSubview:start];
  [actions addArrangedSubview:stop];
  [content addArrangedSubview:actions];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [[ovmsAppDelegate myRef] registerForUpdate:self];
  [self update];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.commandTimeout invalidate];
  self.commandTimeout = nil;
  if (self.pendingAction) [[ovmsAppDelegate myRef] commandCancel];
  [[ovmsAppDelegate myRef] deregisterFromUpdate:self];
  [super viewWillDisappear:animated];
}

- (void)setCommandControlsEnabled:(BOOL)enabled status:(NSString *)status
{
  ((UIButton *)[self.view viewWithTag:108]).enabled = enabled;
  ((UIButton *)[self.view viewWithTag:109]).enabled = enabled;
  UILabel *label = (UILabel *)[self.view viewWithTag:107];
  label.text = status;
  label.textColor = enabled ? [UIColor colorWithWhite:0.70 alpha:1.0] : [UIColor colorWithRed:0.96 green:0.72 blue:0.25 alpha:1.0];
}

- (void)showCommandPreview:(NSString *)status pending:(BOOL)pending
{
  [self setCommandControlsEnabled:!pending status:status];
  UILabel *label = (UILabel *)[self.view viewWithTag:107];
  if (!pending) label.textColor = [UIColor colorWithRed:0.95 green:0.38 blue:0.36 alpha:1.0];
}

- (void)issueChargingCommand:(NSString *)command action:(NSString *)action followup:(NSString *)followup
{
  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  if (![app commandIsFree]) {
    [self setCommandControlsEnabled:YES status:@"Another vehicle command is still pending"];
    return;
  }
  self.pendingAction = action;
  self.pendingFollowupCommand = followup;
  [self setCommandControlsEnabled:NO status:[NSString stringWithFormat:@"%@… waiting for vehicle", action]];
  [app commandRegister:command callback:self];
  [self.commandTimeout invalidate];
  self.commandTimeout = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(chargingCommandTimedOut:) userInfo:nil repeats:NO];
}

- (void)chargingCommandTimedOut:(NSTimer *)timer
{
  [[ovmsAppDelegate myRef] commandCancel];
  NSString *action = self.pendingAction ?: @"Command";
  self.pendingAction = nil; self.pendingFollowupCommand = nil; self.commandTimeout = nil;
  [self setCommandControlsEnabled:YES status:[NSString stringWithFormat:@"%@ timed out — vehicle state was not changed", action]];
}

- (void)commandResult:(NSArray *)result
{
  [self.commandTimeout invalidate]; self.commandTimeout = nil;
  NSInteger resultCode = result.count > 1 ? [result[1] integerValue] : -1;
  NSString *action = self.pendingAction ?: @"Command";
  NSString *followup = self.pendingFollowupCommand;
  self.pendingAction = nil; self.pendingFollowupCommand = nil;
  [[ovmsAppDelegate myRef] commandCancel];
  if (resultCode == 0 && followup.length) {
    [self issueChargingCommand:followup action:@"Saving automatic limits" followup:nil];
    return;
  }
  if (resultCode == 0) {
    [self setCommandControlsEnabled:YES status:[NSString stringWithFormat:@"%@ acknowledged by vehicle", action]];
  } else {
    NSString *detail = result.count > 2 ? result[2] : @"Vehicle rejected the command";
    [self setCommandControlsEnabled:YES status:[NSString stringWithFormat:@"%@ failed: %@", action, detail]];
  }
}

- (void)update
{
  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  ((UILabel *)[self.view viewWithTag:100]).text = [NSString stringWithFormat:@"%d%%", app.car_soc];
  ((UILabel *)[self.view viewWithTag:101]).text = [app.car_chargestate length] ? [app.car_chargestate capitalizedString] : @"Not charging";
  ((UILabel *)[self.view viewWithTag:102]).text = [NSString stringWithFormat:@"%d V", app.car_linevoltage];
  ((UILabel *)[self.view viewWithTag:103]).text = [NSString stringWithFormat:@"%d A", app.car_chargecurrent];
  ((UILabel *)[self.view viewWithTag:104]).text = [NSString stringWithFormat:@"%.1f kW", (app.car_linevoltage * app.car_chargecurrent) / 1000.0];
  ((UILabel *)[self.view viewWithTag:105]).text = app.car_minutestofull > 0
    ? [NSString stringWithFormat:@"%dh %02dm", app.car_minutestofull / 60, app.car_minutestofull % 60] : @"—";
  ((UILabel *)[self.view viewWithTag:106]).text = [NSString stringWithFormat:@"Mode: %@\nCurrent limit: %d A\nSOC limit: %@\nRange limit: %@",
    [app.car_chargemode length] ? [app.car_chargemode capitalizedString] : @"Standard",
    app.car_chargelimit,
    app.car_soclimit > 0 ? [NSString stringWithFormat:@"%d%%", app.car_soclimit] : @"Not set",
    app.car_rangelimit > 0 ? [NSString stringWithFormat:@"%d", app.car_rangelimit] : @"Not set"];
}

- (void)close:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showStartConfirmation
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Start charging?" message:@"The vehicle will begin charging immediately when supported." preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Start" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self issueChargingCommand:@"11" action:@"Starting charge" followup:nil];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showStopConfirmation
{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Stop charging?" message:@"Charging will stop before the configured limit is reached." preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Stop" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
    [self issueChargingCommand:@"12" action:@"Stopping charge" followup:nil];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showChargingSettings
{
  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Charging limits" message:@"Set a safe supply current and optional automatic limits. Use 0 to disable an SOC or range limit." preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
    field.placeholder = @"Current limit (A)";
    field.keyboardType = UIKeyboardTypeNumberPad;
    field.text = [NSString stringWithFormat:@"%d", app.car_chargelimit];
  }];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
    field.placeholder = @"SOC limit (0-100%)";
    field.keyboardType = UIKeyboardTypeNumberPad;
    field.text = [NSString stringWithFormat:@"%d", MAX(0, app.car_soclimit)];
  }];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
    field.placeholder = @"Range limit (0 = off)";
    field.keyboardType = UIKeyboardTypeNumberPad;
    field.text = [NSString stringWithFormat:@"%d", MAX(0, app.car_rangelimit)];
  }];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSInteger current = [alert.textFields.firstObject.text integerValue];
    NSInteger soc = [alert.textFields[1].text integerValue];
    NSInteger range = [alert.textFields[2].text integerValue];
    if (current < 1 || current > 80 || soc < 0 || soc > 100 || range < 0) {
      UIAlertController *error = [UIAlertController alertControllerWithTitle:@"Check charging limits" message:@"Current must be 1-80 A, SOC 0-100%, and range cannot be negative." preferredStyle:UIAlertControllerStyleAlert];
      [error addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
      [self presentViewController:error animated:YES completion:nil];
      return;
    }
    // Serialize both acknowledged commands: the OVMS v2 protocol only has one
    // command callback slot, so issuing these concurrently can lose a response.
    NSString *limitsCommand = [NSString stringWithFormat:@"204,%ld,%ld,0", (long)range, (long)soc];
    [self issueChargingCommand:[NSString stringWithFormat:@"15,%ld", (long)current] action:@"Saving current limit" followup:limitsCommand];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

@end

@interface OVMSQuickActionsEditorViewController : UITableViewController
@property (strong, nonatomic) NSMutableArray *actions;
@property (strong, nonatomic) NSMutableSet *disabled;
@property (copy, nonatomic) NSString *preferenceKey;
@property (copy, nonatomic) void (^completion)(void);
@end

@implementation OVMSQuickActionsEditorViewController
- (void)viewDidLoad
{
  [super viewDidLoad]; self.title=@"Home quick actions"; self.tableView.backgroundColor=[UIColor colorWithRed:.047 green:.071 blue:.118 alpha:1]; self.tableView.separatorColor=[UIColor colorWithWhite:1 alpha:.10];
  self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(resetActions)]; self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)]; self.editing=YES;
}
- (NSString *)titleForAction:(NSString *)identifier { return @{ @"charging":@"Charging", @"climate":@"Climate", @"energy":@"Energy", @"controls":@"Controls", @"location":@"Location", @"messages":@"Messages" }[identifier] ?: identifier; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.actions.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"QuickAction"]; if(!cell) cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"QuickAction"];
  NSString *identifier=self.actions[indexPath.row]; cell.textLabel.text=[self titleForAction:identifier]; cell.detailTextLabel.text=@"Tap to show or hide; drag to reorder"; cell.textLabel.textColor=UIColor.whiteColor; cell.detailTextLabel.textColor=[UIColor colorWithWhite:.65 alpha:1]; cell.backgroundColor=[UIColor colorWithRed:.086 green:.125 blue:.196 alpha:1]; cell.accessoryType=[self.disabled containsObject:identifier]?UITableViewCellAccessoryNone:UITableViewCellAccessoryCheckmark; return cell;
}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath { return YES; }
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)source toIndexPath:(NSIndexPath *)destination { NSString *item=self.actions[source.row]; [self.actions removeObjectAtIndex:source.row]; [self.actions insertObject:item atIndex:destination.row]; }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { NSString *item=self.actions[indexPath.row]; if([self.disabled containsObject:item]) [self.disabled removeObject:item]; else [self.disabled addObject:item]; [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic]; }
- (void)resetActions { self.actions=[@[@"charging",@"climate",@"energy",@"controls",@"location",@"messages"] mutableCopy]; [self.disabled removeAllObjects]; [self.tableView reloadData]; }
- (void)done { NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults]; [defaults setObject:self.actions forKey:[self.preferenceKey stringByAppendingString:@".order"]]; [defaults setObject:self.disabled.allObjects forKey:[self.preferenceKey stringByAppendingString:@".disabled"]]; if(self.completion) self.completion(); [self dismissViewControllerAnimated:YES completion:nil]; }
@end

@interface ovmsStatusViewController ()

@property (strong, nonatomic) UIScrollView *modernScrollView;
@property (strong, nonatomic) UIStackView *modernContentStack;
@property (strong, nonatomic) UIImageView *modernCarImage;
@property (strong, nonatomic) UILabel *modernConnectionLabel;
@property (strong, nonatomic) UILabel *modernSOCLabel;
@property (strong, nonatomic) UIProgressView *modernSOCProgress;
@property (strong, nonatomic) UILabel *modernChargeLabel;
@property (strong, nonatomic) UILabel *modernIdealRangeLabel;
@property (strong, nonatomic) UILabel *modernEstimatedRangeLabel;
@property (strong, nonatomic) UILabel *modernParkingLabel;
@property (copy, nonatomic) NSString *modernCapabilityType;
@property (assign, nonatomic) BOOL screenshotScenarioHandled;

@end

@implementation ovmsStatusViewController
@synthesize m_car_connection_image;
@synthesize m_car_connection_state;
@synthesize m_car_image;
@synthesize m_car_charge_state;
@synthesize m_car_charge_type;
@synthesize m_car_soc;
@synthesize m_battery_front;
@synthesize m_battery_front_width;
@synthesize m_car_parking_image;
@synthesize m_car_parking_state;
@synthesize m_car_range_ideal;
@synthesize m_car_range_estimated;
@synthesize m_charger_plug;
@synthesize m_charger_slider;
@synthesize m_battery_button;
@synthesize m_car_charge_message;
@synthesize m_car_charge_mode;
@synthesize m_car_charge_time;
@synthesize m_car_charge_remaining_time;
@synthesize m_car_chargekwh;
@synthesize m_battery_charging;

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  
  UIImage *stetchLeftTrack= [[UIImage imageNamed:@"Nothing.png"]
                             stretchableImageWithLeftCapWidth:30.0 topCapHeight:0.0];
  UIImage *stetchRightTrack= [[UIImage imageNamed:@"Nothing.png"]
                              stretchableImageWithLeftCapWidth:30.0 topCapHeight:0.0];
  
  // this code to set the slider ball image
  [m_charger_slider setThumbImage: [UIImage imageNamed:@"charger_button.png"] forState:UIControlStateNormal];
  [m_charger_slider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
  [m_charger_slider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];

  [self setupModernHome];
  
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;

  [self update];
}

- (UIColor *)modernBackgroundColor
{
  return [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:1.0];
}

- (UIColor *)modernCardColor
{
  return [UIColor colorWithRed:0.086 green:0.125 blue:0.196 alpha:1.0];
}

- (UIView *)modernCardWithTitle:(NSString *)title content:(UIView *)content
{
  UIView *card = [[UIView alloc] init];
  card.translatesAutoresizingMaskIntoConstraints = NO;
  card.backgroundColor = [self modernCardColor];
  card.layer.cornerRadius = 16.0;
  card.layer.masksToBounds = YES;

  UILabel *heading = [[UILabel alloc] init];
  heading.translatesAutoresizingMaskIntoConstraints = NO;
  heading.text = title;
  heading.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
  heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

  content.translatesAutoresizingMaskIntoConstraints = NO;
  [card addSubview:heading];
  [card addSubview:content];
  [NSLayoutConstraint activateConstraints:@[
    [heading.topAnchor constraintEqualToAnchor:card.topAnchor constant:16.0],
    [heading.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
    [heading.trailingAnchor constraintLessThanOrEqualToAnchor:card.trailingAnchor constant:-16.0],
    [content.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:8.0],
    [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.0],
    [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16.0],
    [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16.0]
  ]];
  return card;
}

- (UILabel *)modernValueLabel
{
  UILabel *label = [[UILabel alloc] init];
  label.textColor = [UIColor whiteColor];
  label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
  label.adjustsFontForContentSizeCategory = YES;
  label.numberOfLines = 0;
  return label;
}

- (UIButton *)modernNavigationButton:(NSString *)title tabIndex:(NSInteger)tabIndex
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  button.tag = tabIndex;
  button.backgroundColor = [UIColor colorWithRed:0.10 green:0.35 blue:0.66 alpha:1.0];
  button.layer.cornerRadius = 12.0;
  button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:@selector(openPrimaryTab:) forControlEvents:UIControlEventTouchUpInside];
  [button.heightAnchor constraintEqualToConstant:48.0].active = YES;
  return button;
}

- (UIButton *)modernChargingButton
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.backgroundColor = [UIColor colorWithRed:0.12 green:0.55 blue:0.32 alpha:1.0];
  button.layer.cornerRadius = 12.0;
  button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [button setTitle:@"Charging" forState:UIControlStateNormal];
  [button addTarget:self action:@selector(openCharging) forControlEvents:UIControlEventTouchUpInside];
  button.enabled=[[ovmsAppDelegate myRef] supportsVehicleCapability:OVMSVehicleCapabilityCharging]; button.alpha=button.enabled?1.0:.4;
  [button.heightAnchor constraintEqualToConstant:52.0].active = YES;
  return button;
}

- (OVMSChargingViewController *)openCharging
{
  OVMSChargingViewController *charging = [[OVMSChargingViewController alloc] init];
  UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:charging];
  navigation.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:navigation animated:YES completion:nil];
  return charging;
}

- (OVMSClimateViewController *)openClimate
{
  OVMSClimateViewController *climate = [[OVMSClimateViewController alloc] init];
  UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:climate];
  navigation.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:navigation animated:YES completion:nil];
  return climate;
}

- (OVMSEnergyViewController *)openEnergy
{
  OVMSEnergyViewController *energy = [[OVMSEnergyViewController alloc] init];
  UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:energy];
  navigation.modalPresentationStyle = UIModalPresentationFullScreen;
  [self presentViewController:navigation animated:YES completion:nil];
  return energy;
}

- (UIButton *)modernClimateButton
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.backgroundColor = [UIColor colorWithRed:0.10 green:0.50 blue:0.72 alpha:1.0];
  button.layer.cornerRadius = 12.0;
  button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [button setTitle:@"Climate" forState:UIControlStateNormal];
  [button addTarget:self action:@selector(openClimate) forControlEvents:UIControlEventTouchUpInside];
  button.enabled=[[ovmsAppDelegate myRef] supportsVehicleCapability:OVMSVehicleCapabilityClimate]; button.alpha=button.enabled?1.0:.4;
  [button.heightAnchor constraintEqualToConstant:52.0].active = YES;
  return button;
}

- (UIButton *)modernEnergyButton
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.backgroundColor = [UIColor colorWithRed:0.45 green:0.30 blue:0.70 alpha:1.0];
  button.layer.cornerRadius = 12.0; button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; [button setTitle:@"Energy" forState:UIControlStateNormal];
  [button addTarget:self action:@selector(openEnergy) forControlEvents:UIControlEventTouchUpInside];
  [button.heightAnchor constraintEqualToConstant:52.0].active = YES;
  return button;
}

- (void)openPrimaryTab:(UIButton *)sender
{
  self.tabBarController.selectedIndex = sender.tag;
}

- (NSString *)quickActionsPreferenceKey { return [NSString stringWithFormat:@"homeQuickActions.%@",[ovmsAppDelegate myRef].sel_car?:@"vehicle"]; }
- (NSArray *)quickActionOrder
{
  NSArray *defaults=@[@"charging",@"climate",@"energy",@"controls",@"location",@"messages"]; NSArray *saved=[[NSUserDefaults standardUserDefaults] arrayForKey:[[self quickActionsPreferenceKey] stringByAppendingString:@".order"]];
  if(saved.count!=defaults.count || ![[NSSet setWithArray:saved] isEqualToSet:[NSSet setWithArray:defaults]]) return defaults; return saved;
}
- (UIButton *)quickActionButton:(NSString *)identifier
{
  if([identifier isEqualToString:@"charging"]) return [self modernChargingButton]; if([identifier isEqualToString:@"climate"]) return [self modernClimateButton]; if([identifier isEqualToString:@"energy"]) return [self modernEnergyButton];
  NSDictionary *tabs=@{@"controls":@1,@"location":@2,@"messages":@3}; return [self modernNavigationButton:[identifier capitalizedString] tabIndex:[tabs[identifier] integerValue]];
}
- (void)showQuickActionsEditor
{
  OVMSQuickActionsEditorViewController *editor=[[OVMSQuickActionsEditorViewController alloc] initWithStyle:UITableViewStyleGrouped]; editor.preferenceKey=[self quickActionsPreferenceKey]; editor.actions=[[self quickActionOrder] mutableCopy]; editor.disabled=[NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:[[self quickActionsPreferenceKey] stringByAppendingString:@".disabled"]]?:@[]]; __weak typeof(self) weakSelf=self; editor.completion=^{[weakSelf setupModernHome];}; UINavigationController *navigation=[[UINavigationController alloc] initWithRootViewController:editor]; navigation.modalPresentationStyle=UIModalPresentationFullScreen; [self presentViewController:navigation animated:YES completion:nil];
}

- (void)setupModernHome
{
  [self.modernScrollView removeFromSuperview];
  self.modernCapabilityType=[ovmsAppDelegate myRef].car_type?:@"";
  for (UIView *subview in [self.view.subviews copy])
    subview.hidden = YES;

  self.view.backgroundColor = [self modernBackgroundColor];
  self.modernScrollView = [[UIScrollView alloc] init];
  self.modernScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  self.modernScrollView.alwaysBounceVertical = YES;
  self.modernScrollView.backgroundColor = [self modernBackgroundColor];
  [self.view addSubview:self.modernScrollView];

  self.modernContentStack = [[UIStackView alloc] init];
  self.modernContentStack.translatesAutoresizingMaskIntoConstraints = NO;
  self.modernContentStack.axis = UILayoutConstraintAxisVertical;
  self.modernContentStack.spacing = 12.0;
  [self.modernScrollView addSubview:self.modernContentStack];

  [NSLayoutConstraint activateConstraints:@[
    [self.modernScrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
    [self.modernScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.modernScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.modernScrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    [self.modernContentStack.topAnchor constraintEqualToAnchor:self.modernScrollView.contentLayoutGuide.topAnchor constant:16.0],
    [self.modernContentStack.leadingAnchor constraintEqualToAnchor:self.modernScrollView.frameLayoutGuide.leadingAnchor constant:16.0],
    [self.modernContentStack.trailingAnchor constraintEqualToAnchor:self.modernScrollView.frameLayoutGuide.trailingAnchor constant:-16.0],
    [self.modernContentStack.bottomAnchor constraintEqualToAnchor:self.modernScrollView.contentLayoutGuide.bottomAnchor constant:-20.0]
  ]];

  UIStackView *identityRow = [[UIStackView alloc] init];
  identityRow.axis = UILayoutConstraintAxisHorizontal;
  identityRow.alignment = UIStackViewAlignmentCenter;
  identityRow.distribution = UIStackViewDistributionEqualSpacing;
  UILabel *vehicleLabel = [[UILabel alloc] init];
  vehicleLabel.text = @"VEHICLE STATUS";
  vehicleLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
  vehicleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
  self.modernConnectionLabel = [[UILabel alloc] init];
  self.modernConnectionLabel.textColor = [UIColor colorWithRed:0.25 green:0.85 blue:0.55 alpha:1.0];
  self.modernConnectionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
  [identityRow addArrangedSubview:vehicleLabel];
  [identityRow addArrangedSubview:self.modernConnectionLabel];
  [self.modernContentStack addArrangedSubview:identityRow];

  self.modernCarImage = [[UIImageView alloc] init];
  self.modernCarImage.contentMode = UIViewContentModeScaleAspectFit;
  [self.modernCarImage.heightAnchor constraintEqualToConstant:190.0].active = YES;
  [self.modernContentStack addArrangedSubview:self.modernCarImage];

  UIStackView *batteryStack = [[UIStackView alloc] init];
  batteryStack.axis = UILayoutConstraintAxisVertical;
  batteryStack.spacing = 10.0;
  self.modernSOCLabel = [self modernValueLabel];
  self.modernSOCLabel.font = [UIFont systemFontOfSize:42.0 weight:UIFontWeightSemibold];
  self.modernSOCProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
  self.modernSOCProgress.progressTintColor = [UIColor colorWithRed:0.30 green:0.82 blue:0.42 alpha:1.0];
  self.modernSOCProgress.trackTintColor = [UIColor colorWithWhite:1.0 alpha:0.12];
  self.modernSOCProgress.layer.cornerRadius = 3.0;
  self.modernSOCProgress.clipsToBounds = YES;
  [self.modernSOCProgress.heightAnchor constraintEqualToConstant:7.0].active = YES;
  self.modernChargeLabel = [[UILabel alloc] init];
  self.modernChargeLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
  self.modernChargeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
  [batteryStack addArrangedSubview:self.modernSOCLabel];
  [batteryStack addArrangedSubview:self.modernSOCProgress];
  [batteryStack addArrangedSubview:self.modernChargeLabel];
  [self.modernContentStack addArrangedSubview:[self modernCardWithTitle:@"BATTERY" content:batteryStack]];

  UIStackView *rangeRow = [[UIStackView alloc] init];
  rangeRow.axis = UILayoutConstraintAxisHorizontal;
  rangeRow.distribution = UIStackViewDistributionFillEqually;
  rangeRow.spacing = 12.0;
  self.modernEstimatedRangeLabel = [self modernValueLabel];
  self.modernIdealRangeLabel = [self modernValueLabel];
  [rangeRow addArrangedSubview:[self modernCardWithTitle:@"ESTIMATED RANGE" content:self.modernEstimatedRangeLabel]];
  [rangeRow addArrangedSubview:[self modernCardWithTitle:@"IDEAL RANGE" content:self.modernIdealRangeLabel]];
  [self.modernContentStack addArrangedSubview:rangeRow];

  self.modernParkingLabel = [self modernValueLabel];
  self.modernParkingLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  [self.modernContentStack addArrangedSubview:[self modernCardWithTitle:@"CURRENT STATE" content:self.modernParkingLabel]];

  NSSet *disabled=[NSSet setWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:[[self quickActionsPreferenceKey] stringByAppendingString:@".disabled"]]?:@[]]; NSMutableArray *visible=[NSMutableArray array]; for(NSString *identifier in [self quickActionOrder]) if(![disabled containsObject:identifier]) [visible addObject:identifier];
  for(NSUInteger offset=0;offset<visible.count;offset+=3){UIStackView *row=[[UIStackView alloc] init];row.axis=UILayoutConstraintAxisHorizontal;row.distribution=UIStackViewDistributionFillEqually;row.spacing=10;for(NSUInteger index=offset;index<MIN(offset+3,visible.count);index++)[row addArrangedSubview:[self quickActionButton:visible[index]]];[self.modernContentStack addArrangedSubview:row];}
  UIButton *customize=[UIButton buttonWithType:UIButtonTypeSystem]; [customize setTitle:@"Customize quick actions" forState:UIControlStateNormal]; customize.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]; [customize addTarget:self action:@selector(showQuickActionsEditor) forControlEvents:UIControlEventTouchUpInside]; [customize.heightAnchor constraintEqualToConstant:44].active=YES; [self.modernContentStack addArrangedSubview:customize];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
#if DEBUG && TARGET_OS_SIMULATOR
  if (self.screenshotScenarioHandled) return;
  NSString *scenario = [[[NSProcessInfo processInfo] environment] objectForKey:@"OVMS_SCREENSHOT_SCENARIO"];
  if (![scenario hasPrefix:@"charging"] && ![scenario hasPrefix:@"climate"] && ![scenario isEqualToString:@"energy"] && ![scenario hasPrefix:@"battery-"] && ![scenario isEqualToString:@"quick-actions"]) return;
  self.screenshotScenarioHandled = YES;
  if ([scenario isEqualToString:@"quick-actions"]) { [self showQuickActionsEditor]; return; }
  if ([scenario isEqualToString:@"energy"]) { [self openEnergy]; return; }
  if ([scenario isEqualToString:@"battery-diagnostics"] || [scenario isEqualToString:@"battery-history-loading"]) {
    OVMSEnergyViewController *energy = [self openEnergy];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [energy openBatteryDiagnostics]; });
    return;
  }
  if ([scenario hasPrefix:@"climate"]) {
    OVMSClimateViewController *climate = [self openClimate];
    if ([scenario isEqualToString:@"climate-start-confirmation"])
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [climate showClimateConfirmation:YES]; });
    else if ([scenario isEqualToString:@"climate-stop-confirmation"])
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [climate showClimateConfirmation:NO]; });
    else if ([scenario isEqualToString:@"climate-schedule"])
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [climate showClimateSchedule]; });
    else if ([scenario isEqualToString:@"climate-schedule-options"])
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [climate showClimateScheduleAdvanced]; });
    else if ([scenario isEqualToString:@"climate-schedule-clear-day"])
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [climate showClearDaySchedule]; });
    else if ([scenario isEqualToString:@"climate-schedule-copy"])
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [climate showCopySchedule]; });
    else if ([scenario isEqualToString:@"climate-schedule-clear"])
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [climate showClearScheduleConfirmation]; });
    return;
  }
  OVMSChargingViewController *charging = [self openCharging];
  if ([scenario isEqualToString:@"charging-start-confirmation"])
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [charging showStartConfirmation]; });
  else if ([scenario isEqualToString:@"charging-stop-confirmation"])
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [charging showStopConfirmation]; });
  else if ([scenario isEqualToString:@"charging-settings"])
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [charging showChargingSettings]; });
  else if ([scenario isEqualToString:@"charging-command-pending"])
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [charging showCommandPreview:@"Starting charge… waiting for vehicle" pending:YES]; });
  else if ([scenario isEqualToString:@"charging-command-failed"])
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [charging showCommandPreview:@"Starting charge failed: Vehicle is asleep" pending:NO]; });
#endif
}

- (void)dealloc
{
  [self setM_car_image:nil];
  [self setM_car_charge_state:nil];
  [self setM_car_charge_type:nil];
  [self setM_car_charge_time:nil];
  [self setM_car_charge_remaining_time:nil];
  [self setM_car_chargekwh:nil];
  [self setM_car_soc:nil];
  [self setM_battery_front:nil];
  [self setM_car_connection_state:nil];
  [self setM_car_connection_image:nil];
  [self setM_car_parking_image:nil];
  [self setM_car_parking_state:nil];
  [self setM_battery_charging:nil];
  [self setM_car_range_ideal:nil];
  [self setM_car_range_estimated:nil];
  [self setM_car_charge_mode:nil];
  [self setM_charger_plug:nil];
  [self setM_charger_slider:nil];
  [self setM_car_charge_message:nil];
  [self setM_battery_button:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
  
  [[ovmsAppDelegate myRef] registerForUpdate:self];

  [self update];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
  [[ovmsAppDelegate myRef] deregisterFromUpdate:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

-(void) update
  {
  NSString* units;
  if ([[ovmsAppDelegate myRef].car_units isEqualToString:@"K"])
    units = @"km";
  else
    units = @"m";
  
  int connected = [ovmsAppDelegate myRef].car_connected;
  time_t lastupdated = [ovmsAppDelegate myRef].car_lastupdated;
  int seconds = (int)(time(0)-lastupdated);
  int minutes = (int)(time(0)-lastupdated)/60;
  int hours = minutes/60;
  int days = minutes/(60*24);
  
  NSString* mode;

  NSString* c_good;
  NSString* c_bad;
  NSString* c_unknown;
  if ([ovmsAppDelegate myRef].car_paranoid)
    {
    c_good = @"connection_good_paranoid.png";
    c_bad = @"connection_bad_paranoid.png";
    c_unknown = @"connection_unknown_paranoid.png";
    }
  else
    {
    c_good = @"connection_good.png";
    c_bad = @"connection_bad.png";
    c_unknown = @"connection_unknown.png";
    }

  NSString* imagewanted;
  
  if (connected>0)
    {
    imagewanted = c_good;
    }
  else
    {
    imagewanted = c_unknown;
    }
  
  if (lastupdated == 0)
    {
    m_car_connection_state.text = @"";
    m_car_connection_state.textColor = [UIColor whiteColor];
    }
  else if (minutes == 0)
    {
    m_car_connection_state.text = @"live";
    m_car_connection_state.textColor = [UIColor whiteColor];
    }
  else if (minutes == 1)
    {
    m_car_connection_state.text = @"1 min";
    m_car_connection_state.textColor = [UIColor whiteColor];
    }
  else if (days > 1)
    {
    m_car_connection_state.text = [NSString stringWithFormat:@"%d days",days];
    m_car_connection_state.textColor = [UIColor redColor];
    imagewanted = c_bad;
    }
  else if (hours > 1)
    {
    m_car_connection_state.text = [NSString stringWithFormat:@"%d hours",hours];
    m_car_connection_state.textColor = [UIColor redColor];
    imagewanted = c_bad;
    }
  else if (minutes > 60)
    {
    m_car_connection_state.text = [NSString stringWithFormat:@"%d mins",minutes];
    m_car_connection_state.textColor = [UIColor redColor];
    imagewanted = c_bad;
    }
  else
    {
    m_car_connection_state.text = [NSString stringWithFormat:@"%d mins",minutes];
    m_car_connection_state.textColor = [UIColor whiteColor];
    }

  if ([ovmsAppDelegate myRef].car_online)
    {
    m_battery_button.enabled=YES;
    [m_car_connection_image stopAnimating];
    m_car_connection_image.animationImages = nil;
    m_car_connection_image.image=[UIImage imageNamed:imagewanted];
    }
  else
    {
    m_battery_button.enabled=NO;
    NSArray *images = [[NSArray alloc] initWithObjects:
                        [UIImage imageNamed:@"Nothing.png"],
                        [UIImage imageNamed:imagewanted],
                        nil];
    m_car_connection_image.image = nil;
    m_car_connection_image.animationImages = images;
    m_car_connection_image.animationDuration = 1.0;
    m_car_connection_image.animationRepeatCount = 0;
    [m_car_connection_image startAnimating];
    }

  int parktime = [ovmsAppDelegate myRef].car_parktime;
  int chargetime = [ovmsAppDelegate myRef].car_chargeduration;
  int chargeremainingtime = [ovmsAppDelegate myRef].car_minutestofull;
  int chargekWh = [ovmsAppDelegate myRef].car_chargekwh;
  if ((parktime > 0)&&(lastupdated>0)) parktime += seconds;
  
  if (parktime == 0)
    {
    m_car_parking_image.hidden = 1;
    m_car_parking_state.text = @"";
    }
  else if (parktime < 120)
    {
    m_car_parking_image.hidden = 0;
    m_car_parking_state.text = @"just now";
    }
  else if (parktime < (3600*2))
    {
    m_car_parking_image.hidden = 0;
    m_car_parking_state.text = [NSString stringWithFormat:@"%d mins",parktime/60];
    }
  else if (parktime < (3600*24*2))
    {
    m_car_parking_image.hidden = 0;
    m_car_parking_state.text = [NSString stringWithFormat:@"%02d:%02d",
                                parktime/3600,
                                (parktime%3600)/60];
    }
  else
    {
    m_car_parking_image.hidden = 0;
    m_car_parking_state.text = [NSString stringWithFormat:@"%d days",parktime/(3600*24)];
    }

  if (chargetime == 0 || m_charger_plug.hidden == 1)
    {
    m_car_charge_time.text = @"";
    }
  else if (chargetime < 120)
    {
    m_car_charge_time.text = @"CHARGING STARTED";
    }
  else if (chargetime < 3600)
    {
    m_car_charge_time.text = [NSString stringWithFormat:@"%d mins",chargetime/60];
    }
  else if (chargetime < (3600*24*2))
    {
    m_car_charge_time.text = [NSString stringWithFormat:@"%02d:%02d",
                                       chargetime/3600,
                                       (chargetime%3600)/60];
    }

  if (chargeremainingtime <= 0)
    {
    m_car_charge_remaining_time.text = @"";
    }
  else if (chargeremainingtime < 60)
    {
    m_car_charge_remaining_time.text = [NSString stringWithFormat:@"%d mins",chargeremainingtime];
    }
  else
    {
    m_car_charge_remaining_time.text = [NSString stringWithFormat:@"%02d:%02d",
                               chargeremainingtime/60,
                               chargeremainingtime%60];
    }

  if ( chargekWh==0 )
    {
    m_car_chargekwh.text = @"";
    }
  else
    {
    float effect=([ovmsAppDelegate myRef].car_linevoltage*[ovmsAppDelegate myRef].car_chargecurrent)/1000.0;
    if ((effect>0)&&(effect<250))
      {
      m_car_chargekwh.text = [NSString stringWithFormat:@"%dkWh@%0.1fkW",chargekWh,effect];
      }
    else
      {
      m_car_chargekwh.text = [NSString stringWithFormat:@"%dkWh",chargekWh];
      }
    }

  m_car_image.image=[UIImage imageNamed:[ovmsAppDelegate myRef].sel_imagepath];
  m_car_soc.text = [NSString stringWithFormat:@"%d%%",[ovmsAppDelegate myRef].car_soc];
  m_car_range_ideal.text = [ovmsAppDelegate myRef].car_idealrange_s;
  m_car_range_estimated.text = [ovmsAppDelegate myRef].car_estimatedrange_s;

  NSString *currentType=[ovmsAppDelegate myRef].car_type?:@"";
  if (![self.modernCapabilityType isEqualToString:currentType]) [self setupModernHome];
  self.modernCarImage.image = [UIImage imageNamed:[ovmsAppDelegate myRef].sel_imagepath];
  self.modernSOCLabel.text = [NSString stringWithFormat:@"%d%%", [ovmsAppDelegate myRef].car_soc];
  self.modernSOCProgress.progress = MAX(0.0, MIN(1.0, [ovmsAppDelegate myRef].car_soc / 100.0));
  self.modernEstimatedRangeLabel.text = [ovmsAppDelegate myRef].car_estimatedrange_s;
  self.modernIdealRangeLabel.text = [ovmsAppDelegate myRef].car_idealrange_s;
  self.modernConnectionLabel.text = lastupdated == 0 ? @"Waiting for data" : m_car_connection_state.text;
  self.modernConnectionLabel.textColor = m_car_connection_state.textColor;
  NSString *chargeSummary = [[ovmsAppDelegate myRef].car_chargestate length] > 0
    ? [[ovmsAppDelegate myRef].car_chargestate capitalizedString] : @"Not charging";
  self.modernChargeLabel.text = chargeSummary;
  self.modernParkingLabel.text = parktime > 0
    ? [NSString stringWithFormat:@"Parked %@", m_car_parking_state.text]
    : @"Vehicle state is live";
      
  CGRect bounds = m_battery_front.bounds;
  CGPoint center = m_battery_front.center;
  CGFloat oldwidth = bounds.size.width;
  CGFloat newwidth = (((0.0+[ovmsAppDelegate myRef].car_soc)/100.0)*(233-17))+18;
  bounds.size.width = newwidth;
  center.x = center.x + ((newwidth - oldwidth)/2);
  m_battery_front_width.constant = newwidth;
  //m_battery_front.bounds = bounds;
  //m_battery_front.center = center;
  //bounds = m_battery_front.bounds;

  center = m_car_charge_remaining_time.center;
      center.x = (m_battery_front.center.x+bounds.size.width/2 + 233+17)/2;
  m_car_charge_remaining_time.center = center;
      
  if ((([ovmsAppDelegate myRef].car_doors1 & 0x04)==0)||
      ([ovmsAppDelegate myRef].car_chargesubstate == 0x07))
    { // Charge port is closed, or connect-pwr-cable charge sub-state
    m_charger_plug.hidden = 1;            // The plug image
    m_charger_slider.hidden = 1;          // The slider control on the plug
    m_charger_slider.enabled = 0;         // The slider control on the plug
    m_car_charge_state.hidden = 1;        // The car charge state label (left of slider)
    m_car_charge_type.hidden = 1;         // The car charge type label (left of slider)
    m_car_charge_message.hidden = 1;      // The car charge message (right of slider)
    m_battery_charging.hidden = 1;        // Copper tops on the battery
    m_car_charge_mode.hidden = 1;         // The car charge mode message (copper on battery)
    }
  else
    { // Charge port is open and plugged in
    m_charger_plug.hidden = 0;            // The plug image
    m_charger_slider.hidden = 0;          // The slider control on the plug
    m_charger_slider.enabled =            // The slider control on the plug
      connected &&
      ([ovmsAppDelegate myRef].car_chargestateN<0x100) &&
      ([ovmsAppDelegate myRef].car_online);
    m_car_charge_state.hidden = 0;        // The car charge state label (left of slider)
    m_car_charge_type.hidden = 0;         // The car charge type label (left of slider)
    switch ([ovmsAppDelegate myRef].car_chargestateN)
      {
      case 0x04:    // Done
      case 0x115:   // Stopping
      case 0x15:    // Stopped
      case 0x16:    // Stopped
      case 0x17:    // Stopped
      case 0x18:    // Stopped
      case 0x19:    // Stopped
        m_car_charge_message.text = @"SLIDE TO CHARGE";
        m_car_charge_state.text = @"";
        m_car_charge_type.text = @"";
        m_car_charge_mode.text = @"";
        // Slider on the left, message is "Slide to charge"
        m_charger_slider.value = 0.0;
        m_car_charge_message.hidden = 0;
        m_car_charge_state.hidden = 1;
        m_car_charge_type.hidden = 1;
        m_battery_charging.hidden = 1;
        m_car_charge_mode.hidden = 1;
        
        break;

      case 0x0e:    // Wait for schedule charge
        m_car_charge_message.text = @"TIMED CHARGE";
        m_car_charge_state.text = @"";
        m_car_charge_type.text = @"";
        m_car_charge_mode.text = @"";
        // Slider on the left, message is "Slide to charge"
        m_charger_slider.value = 0.0;
        m_car_charge_message.hidden = 0;
        m_car_charge_state.hidden = 1;
        m_car_charge_type.hidden = 1;
        m_battery_charging.hidden = 1;
        m_car_charge_mode.hidden = 1;
        break;

      case 0x01:    // Charging
      case 0x101:   // Starting
      case 0x02:    // Top-off
      case 0x0d:    // Preparing to charge
      case 0x0f:    // Heating
        m_car_charge_state.text = [[ovmsAppDelegate myRef].car_chargestate uppercaseString];
        m_car_charge_type.text = [NSString stringWithFormat:@"%dV @%dA",
                                  [ovmsAppDelegate myRef].car_linevoltage,
                                  [ovmsAppDelegate myRef].car_chargecurrent];
        
        if( [ovmsAppDelegate myRef].car_chargetype==1 ){
            mode = @"Type 1";
        }else if( [ovmsAppDelegate myRef].car_chargetype==2 ){
            mode = @"ChaDeMo";
        }else{
            mode = [[ovmsAppDelegate myRef].car_chargemode uppercaseString];
        }
        m_car_charge_mode.text = [NSString stringWithFormat:@"%@ %dA",
                                mode,
                                [ovmsAppDelegate myRef].car_chargelimit];
        // Slider on the right, message blank
        m_charger_slider.value = 1.0;        
        m_car_charge_message.hidden = 1;
        m_car_charge_state.hidden = 0;
        m_car_charge_type.hidden = 0;
        m_battery_charging.hidden = 0;
        m_car_charge_mode.hidden = 0;
        break;

      default:
        m_car_charge_state.text = @"";
        m_car_charge_type.text = @"";
        m_car_charge_mode.text = @"";
        // Slider on the right, message blank
        m_charger_slider.value = 1.0;
        m_car_charge_message.hidden = 1;
        m_car_charge_state.hidden = 0;
        m_car_charge_type.hidden = 0;
        m_battery_charging.hidden = 1;
        m_car_charge_mode.hidden = 1;
        break;
      }
    }
  }

- (IBAction)ChargeSliderTouch:(id)sender
  {
  if (([[ovmsAppDelegate myRef].car_chargestate isEqualToString:@"done"])||
      ([[ovmsAppDelegate myRef].car_chargestate isEqualToString:@"stopped"])||
      ([[ovmsAppDelegate myRef].car_chargestate isEqualToString:@"timerwait"]))
    {
    // The slider is on the left, and should spring back there
    if (m_charger_slider.value == 1.0)
      {
      // We are done, and should start the charge
      [[ovmsAppDelegate myRef] commandDoStartCharge];
      }
    else
      {
      // Spring back
      [UIView beginAnimations: @"SlideCanceled" context: nil];
      [UIView setAnimationDelegate: self];
      [UIView setAnimationDuration: 0.35];
      // use CurveEaseOut to create "spring" effect
      [UIView setAnimationCurve: UIViewAnimationCurveEaseOut]; 
      m_charger_slider.value = 0.0;      
      [UIView commitAnimations];
      }
    }
  else
    {
    // The slider is on the right, and should sprint back there
    if (m_charger_slider.value == 0.0)
      {
      // We are done, and should stop the charge
      [[ovmsAppDelegate myRef] commandDoStopCharge];
      }
    else
      {
      // Spring back
      [UIView beginAnimations: @"SlideCanceled" context: nil];
      [UIView setAnimationDelegate: self];
      [UIView setAnimationDuration: 0.35];
      // use CurveEaseOut to create "spring" effect
      [UIView setAnimationCurve: UIViewAnimationCurveEaseOut]; 
      m_charger_slider.value = 1.0;      
      [UIView commitAnimations];
      }
    }
  }

- (IBAction)ChargeSliderValue:(id)sender
  {
  }

@end
