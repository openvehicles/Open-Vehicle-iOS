//
//  ovmsBodyViewController.m
//  ovms
//
//  Created by Mark Webb-Johnson on 9/12/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ovmsBodyViewController.h"
#import "ovmsControlPINEntry.h"
#import <TargetConditionals.h>

@implementation ovmsBodyViewController
@synthesize m_car_lockunlock;
@synthesize m_car_outlineimage;
@synthesize m_car_lights;
@synthesize m_car_valetonoff;
@synthesize m_car_door_ld;
@synthesize m_car_door_rd;
@synthesize m_car_door_hd;
@synthesize m_car_door_cp;
@synthesize m_car_door_tr;
@synthesize m_car_wheel_fr_pressure;
@synthesize m_car_wheel_fr_temp;
@synthesize m_car_wheel_rr_pressure;
@synthesize m_car_wheel_rr_temp;
@synthesize m_car_wheel_fl_pressure;
@synthesize m_car_wheel_fl_temp;
@synthesize m_car_wheel_rl_pressure;
@synthesize m_car_wheel_rl_temp;
@synthesize m_car_temp_pem;
@synthesize m_car_temp_motor;
@synthesize m_car_temp_battery;
@synthesize m_car_temp_pem_l;
@synthesize m_car_temp_motor_l;
@synthesize m_car_temp_battery_l;
@synthesize m_car_ambient_temp;
@synthesize m_car_weather;
@synthesize m_car_tpmsboxes;
@synthesize m_lock_button;
@synthesize m_valet_button;
@synthesize m_wakeup_button;
@synthesize m_homelink_button;
@synthesize m_car_aux_battery;

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

-(void)animateLayer
  {
  // Setup animation for the charging port...
  CABasicAnimation *theAnimation;
  theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
  theAnimation.duration=0.75;
  theAnimation.repeatCount= 3.4E38;
  theAnimation.autoreverses=YES;
  theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
  theAnimation.toValue=[NSNumber numberWithFloat:0.35];
  [m_car_door_cp.layer removeAllAnimations];
  [m_car_door_cp.layer addAnimation:theAnimation forKey:@"animateOpacity"];
  
  m_car_door_cp.layer.speed = 0.0; // Effectively pauses the animation
  }

-(void)animatePause
  {
  if (m_car_door_cp.layer.speed == 0.0) return;
  
  CFTimeInterval pausedTime = [m_car_door_cp.layer convertTime:CACurrentMediaTime() fromLayer:nil];
  m_car_door_cp.layer.speed = 0.0;
  m_car_door_cp.layer.timeOffset = pausedTime;
  }

-(void)animateResume
  {
  if (m_car_door_cp.layer.speed == 1.0) return;

  CFTimeInterval pausedTime = [m_car_door_cp.layer timeOffset];
  m_car_door_cp.layer.speed = 1.0;
  m_car_door_cp.layer.timeOffset = 0.0;
  m_car_door_cp.layer.beginTime = 0.0;
  CFTimeInterval timeSincePause = [m_car_door_cp.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
  m_car_door_cp.layer.beginTime = timeSincePause;
  }

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
  {
  [super viewDidLoad];
  [self setupModernControls];
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
  }

- (UIButton *)modernButton:(NSString *)title action:(SEL)action color:(UIColor *)color
  {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  button.backgroundColor = color; button.layer.cornerRadius = 12.0;
  button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
  [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside]; [button.heightAnchor constraintEqualToConstant:50].active = YES;
  return button;
  }

- (UILabel *)modernCardLabel:(NSString *)text
  {
  UILabel *label = [[UILabel alloc] init]; label.text = text; label.textColor = [UIColor whiteColor]; label.numberOfLines = 0;
  label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody]; label.backgroundColor = [UIColor colorWithRed:0.086 green:0.125 blue:0.196 alpha:1];
  label.layer.cornerRadius = 14; label.layer.masksToBounds = YES; [label.heightAnchor constraintGreaterThanOrEqualToConstant:72].active = YES; return label;
  }

- (void)setupModernControls
  {
  [self.modernRootScroll removeFromSuperview];
  for (UIView *subview in [self.view.subviews copy]) subview.hidden = YES;
  self.modernCapabilityType = [ovmsAppDelegate myRef].car_type ?: @"";
  self.view.backgroundColor = [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:1];
  UIScrollView *scroll = [[UIScrollView alloc] init]; scroll.translatesAutoresizingMaskIntoConstraints = NO; scroll.backgroundColor = self.view.backgroundColor; [self.view addSubview:scroll];
  self.modernRootScroll = scroll;
  UIStackView *content = [[UIStackView alloc] init]; content.translatesAutoresizingMaskIntoConstraints = NO; content.axis = UILayoutConstraintAxisVertical; content.spacing = 12; [scroll addSubview:content];
  [NSLayoutConstraint activateConstraints:@[[scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor], [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor], [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor], [scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor], [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:16], [content.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:16], [content.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-16], [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20]]];
  UIImageView *car = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[ovmsAppDelegate myRef].sel_imagepath]]; car.contentMode = UIViewContentModeScaleAspectFit; [car.heightAnchor constraintEqualToConstant:175].active = YES; [content addArrangedSubview:car];
  self.modernSecurityState = [self modernCardLabel:@""]; self.modernVehicleState = [self modernCardLabel:@""]; self.modernTPMSState = [self modernCardLabel:@""];
  [content addArrangedSubview:self.modernSecurityState]; [content addArrangedSubview:self.modernVehicleState]; [content addArrangedSubview:self.modernTPMSState];
  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  UIStackView *security = [[UIStackView alloc] init]; security.axis = UILayoutConstraintAxisHorizontal; security.distribution = UIStackViewDistributionFillEqually; security.spacing = 10;
  UIButton *lock = [self modernButton:@"Lock / unlock" action:@selector(showLockControl) color:[UIColor colorWithRed:0.10 green:0.35 blue:0.66 alpha:1]]; lock.enabled = [app supportsVehicleCapability:OVMSVehicleCapabilityLock]; lock.alpha = lock.enabled ? 1.0 : 0.4; [security addArrangedSubview:lock];
  if ([app supportsVehicleCapability:OVMSVehicleCapabilityValet]) [security addArrangedSubview:[self modernButton:@"Valet mode" action:@selector(showValetControl) color:[UIColor colorWithRed:0.45 green:0.30 blue:0.70 alpha:1]]];
  [content addArrangedSubview:security];
  UIStackView *other = [[UIStackView alloc] init]; other.axis = UILayoutConstraintAxisHorizontal; other.distribution = UIStackViewDistributionFillEqually; other.spacing = 10;
  [other addArrangedSubview:[self modernButton:@"Wake vehicle" action:@selector(showWakeConfirmation) color:[UIColor colorWithRed:0.12 green:0.55 blue:0.32 alpha:1]]];
  NSString *secondaryTitle = [app supportsVehicleCapability:OVMSVehicleCapabilityDriveProfiles] ? @"Drive profiles" : @"Homelink";
  if ([app supportsVehicleCapability:OVMSVehicleCapabilityHomelink] || [app supportsVehicleCapability:OVMSVehicleCapabilityDriveProfiles]) [other addArrangedSubview:[self modernButton:secondaryTitle action:@selector(showHomelinkControl) color:[UIColor colorWithRed:0.72 green:0.38 blue:0.12 alpha:1]]];
  [content addArrangedSubview:other];
  if ([app supportsVehicleCapability:OVMSVehicleCapabilityDDT4All]) [content addArrangedSubview:[self modernButton:@"Scenic DDT4all actions" action:@selector(showDDT4AllControl) color:[UIColor colorWithRed:0.48 green:0.28 blue:0.62 alpha:1]]];
  }

- (void)dealloc
{
  [self setM_car_lockunlock:nil];
  [self setM_car_door_ld:nil];
  [self setM_car_door_rd:nil];
  [self setM_car_door_hd:nil];
  [self setM_car_door_cp:nil];
  [self setM_car_door_tr:nil];
  [self setM_car_temp_pem:nil];
  [self setM_car_temp_motor:nil];
  [self setM_car_temp_battery:nil];
  [self setM_car_wheel_fr_pressure:nil];
  [self setM_car_wheel_fr_temp:nil];
  [self setM_car_wheel_rr_pressure:nil];
  [self setM_car_wheel_rr_temp:nil];
  [self setM_car_wheel_fl_pressure:nil];
  [self setM_car_wheel_fl_temp:nil];
  [self setM_car_wheel_rl_pressure:nil];
  [self setM_car_wheel_rl_temp:nil];
  [self setM_car_temp_pem_l:nil];
  [self setM_car_temp_motor_l:nil];
  [self setM_car_temp_battery_l:nil];
  [self setM_car_outlineimage:nil];
  [self setM_car_ambient_temp:nil];
  [self setM_car_valetonoff:nil];
  [self setM_car_lights:nil];
  [self setM_lock_button:nil];
  [self setM_valet_button:nil];
  [self setM_wakeup_button:nil];
  [self setM_car_weather:nil];
  [self setM_car_tpmsboxes:nil];
  [self setM_homelink_button:nil];
  [self setM_car_aux_battery:nil];
}

- (void)viewWillAppear:(BOOL)animated
  {
  [super viewWillAppear:animated];
  NSString *currentType = [ovmsAppDelegate myRef].car_type ?: @"";
  if (![self.modernCapabilityType isEqualToString:currentType]) [self setupModernControls];
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;

  [[ovmsAppDelegate myRef] registerForUpdate:self];

  [self animateLayer];
  [self update];
  }

- (void)viewDidAppear:(BOOL)animated
  {
  [super viewDidAppear:animated];
#if DEBUG && TARGET_OS_SIMULATOR
  if (!self.screenshotScenarioHandled) {
    NSString *scenario = [[[NSProcessInfo processInfo] environment] objectForKey:@"OVMS_SCREENSHOT_SCENARIO"];
    self.screenshotScenarioHandled = [scenario hasPrefix:@"controls-"];
    if ([scenario isEqualToString:@"controls-lock"]) [self showLockControl];
    else if ([scenario isEqualToString:@"controls-valet"]) [self showValetControl];
    else if ([scenario isEqualToString:@"controls-wake"]) [self showWakeConfirmation];
    else if ([scenario isEqualToString:@"controls-homelink"]) [self showHomelinkControl];
  }
#endif
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
  if ([ovmsAppDelegate myRef].car_online)
    {
    m_lock_button.enabled=YES;
    m_valet_button.enabled=YES;
    m_wakeup_button.enabled=YES;
    m_homelink_button.enabled=YES;
    }
  else
    {
    m_lock_button.enabled=NO;
    m_valet_button.enabled=NO;
    m_wakeup_button.enabled=NO;    
    m_homelink_button.enabled=NO;
    }
  
  int car_ambient_weather = [ovmsAppDelegate myRef].car_ambient_weather;
  if (car_ambient_weather <= 0)
    {
    m_car_weather.hidden = YES;
    }
  else
    {
    m_car_weather.image = [UIImage imageNamed:
                           [NSString stringWithFormat:@"wsymbol_%d.png",car_ambient_weather]];
    m_car_weather.hidden = NO;
    }

  m_car_outlineimage.image=[UIImage
                            imageNamed:[NSString stringWithFormat:@"ol_%@",
                                        [ovmsAppDelegate myRef].sel_imagepath]];

  if ([ovmsAppDelegate myRef].car_doors2 & 0x08)
    m_car_lockunlock.image = [UIImage imageNamed:@"carlock.png"];
  else
    m_car_lockunlock.image = [UIImage imageNamed:@"carunlock.png"];

  if ([ovmsAppDelegate myRef].car_doors2 & 0x10)
    m_car_valetonoff.image = [UIImage imageNamed:@"carvaleton.png"];
  else
    m_car_valetonoff.image = [UIImage imageNamed:@"carvaletoff.png"];

  if ([ovmsAppDelegate myRef].car_doors2 & 0x20)
    m_car_lights.hidden = 0;
  else
    m_car_lights.hidden = 1;

  if ([ovmsAppDelegate myRef].car_doors1 & 0x01)
    m_car_door_ld.hidden = 0;
  else
    m_car_door_ld.hidden = 1;
  
  if ([ovmsAppDelegate myRef].car_doors1 & 0x02)
    m_car_door_rd.hidden = 0;
  else
    m_car_door_rd.hidden = 1;

  if ([ovmsAppDelegate myRef].car_doors2 & 0x40)
    m_car_door_hd.hidden = 0;
  else
    m_car_door_hd.hidden = 1;

  if ([ovmsAppDelegate myRef].car_doors2 & 0x80)
    m_car_door_tr.hidden = 0;
  else
    m_car_door_tr.hidden = 1;

  if (([ovmsAppDelegate myRef].car_doors1 & 0x04)==0)
    {
    // Charge port door is shut
    m_car_door_cp.hidden = 1;
    [self animatePause];
    }
  else
    {
    // Charge port door is open
    m_car_door_cp.hidden = 0;
    int car_chargestate = [ovmsAppDelegate myRef].car_chargestateN;
    int car_chargesubstate = [ovmsAppDelegate myRef].car_chargesubstate;
    if (car_chargesubstate == 0x07)
      {
      // We need to connect the power cable
      m_car_door_cp.image = [UIImage imageNamed:@"roadster_outline_cu.png"];
      [self animatePause];
      }
    else if ((car_chargestate == 0x0d)||(car_chargestate == 0x0e)||(car_chargestate == 0x101))
      {
      // Preparing to charge, timer wait, or fake 'starting' state
      m_car_door_cp.image = [UIImage imageNamed:@"roadster_outline_ce.png"];
      [self animateResume];
      }
    else if ((car_chargestate == 0x01)||  // Charging
             (car_chargestate == 0x02)||  // Top-off
             (car_chargestate == 0x0f)||  // Heating
             ([ovmsAppDelegate myRef].car_doors1 & 0x10)) // Charging
      {
      m_car_door_cp.image = [UIImage imageNamed:@"roadster_outline_cp.png"];
      [self animateResume];
      }
    else if (car_chargestate == 0x04)
      {
      // Charging done
      m_car_door_cp.image = [UIImage imageNamed:@"roadster_outline_cd.png"];
      [self animateResume];
      }
    else if ((car_chargestate >= 0x15)&&(car_chargestate <= 0x19))
      {
      // Stopped
      m_car_door_cp.image = [UIImage imageNamed:@"roadster_outline_cs.png"];
      [self animateResume];
      }
    else
      {
      // Fake 0x115 'stoppping' state, or something else not understood
      m_car_door_cp.image = [UIImage imageNamed:@"roadster_outline_cp.png"];
      [self animatePause];
      }
    }

  int car_stale_pemtemps = [ovmsAppDelegate myRef].car_stale_pemtemps;
  if (car_stale_pemtemps < 0)
    {
    // No PEM temperatures
    m_car_temp_pem.hidden = YES;
    m_car_temp_motor.hidden = YES;
    m_car_temp_battery.hidden = YES;
    m_car_temp_pem_l.textColor = [UIColor grayColor];
    m_car_temp_motor_l.textColor = [UIColor grayColor];
    m_car_temp_battery_l.textColor = [UIColor grayColor];
    }
  else if (car_stale_pemtemps == 0)
    {
    // Stale PEM temperatures
    m_car_temp_pem.hidden = NO;
    m_car_temp_motor.hidden = NO;
    m_car_temp_battery.hidden = NO;
    m_car_temp_pem.textColor = [UIColor grayColor];
    m_car_temp_pem_l.textColor = [UIColor grayColor];
    m_car_temp_motor.textColor = [UIColor grayColor];
    m_car_temp_motor_l.textColor = [UIColor grayColor];
    m_car_temp_battery.textColor = [UIColor grayColor];
    m_car_temp_battery_l.textColor = [UIColor grayColor];
    m_car_temp_pem.text = [ovmsAppDelegate myRef].car_tpem_s;
    m_car_temp_motor.text = [ovmsAppDelegate myRef].car_tmotor_s;
    m_car_temp_battery.text = [ovmsAppDelegate myRef].car_tbattery_s;
    }
  else
    {
    // OK PEM temperatures
    m_car_temp_pem.hidden = NO;
    m_car_temp_motor.hidden = NO;
    m_car_temp_battery.hidden = NO;
    m_car_temp_pem.textColor = [UIColor whiteColor];
    m_car_temp_pem_l.textColor = [UIColor whiteColor];
    m_car_temp_motor.textColor = [UIColor whiteColor];
    m_car_temp_motor_l.textColor = [UIColor whiteColor];
    m_car_temp_battery.textColor = [UIColor whiteColor];
    m_car_temp_battery_l.textColor = [UIColor whiteColor];
    m_car_temp_pem.text = [ovmsAppDelegate myRef].car_tpem_s;
    m_car_temp_motor.text = [ovmsAppDelegate myRef].car_tmotor_s;
    m_car_temp_battery.text = [ovmsAppDelegate myRef].car_tbattery_s;
    }

  int car_stale_ambienttemps = [ovmsAppDelegate myRef].car_stale_ambienttemps;
  if (car_stale_ambienttemps < 0)
    {
    // No Ambient temperature
    }
  else if (car_stale_ambienttemps == 0)
    {
    // Stale Ambient temperature
    m_car_ambient_temp.textColor = [UIColor grayColor];
    m_car_ambient_temp.text = [ovmsAppDelegate myRef].car_ambient_temp_s;
    }
  else
    {
    // OK Ambient temperature
    m_car_ambient_temp.textColor = [UIColor whiteColor];
    m_car_ambient_temp.text = [ovmsAppDelegate myRef].car_ambient_temp_s;
    }
    
  int car_stale_tpms = [ovmsAppDelegate myRef].car_stale_tpms;
  if (car_stale_tpms < 0)
    {
    // No TPMS
    m_car_tpmsboxes.hidden = YES;
    }
  else if (car_stale_tpms == 0)
    {
    // Stale TPMS
    m_car_tpmsboxes.hidden = NO;
    m_car_wheel_fr_pressure.textColor = [UIColor grayColor];
    m_car_wheel_fr_temp.textColor = [UIColor grayColor];
    m_car_wheel_fl_pressure.textColor = [UIColor grayColor];
    m_car_wheel_fl_temp.textColor = [UIColor grayColor];
    m_car_wheel_rr_pressure.textColor = [UIColor grayColor];
    m_car_wheel_rr_temp.textColor = [UIColor grayColor];
    m_car_wheel_rl_pressure.textColor = [UIColor grayColor];
    m_car_wheel_rl_temp.textColor = [UIColor grayColor];
    }
  else
    {
    // OK TPMS
    m_car_tpmsboxes.hidden = NO;
    m_car_wheel_fr_pressure.textColor = [UIColor whiteColor];
    m_car_wheel_fr_temp.textColor = [UIColor whiteColor];
    m_car_wheel_fl_pressure.textColor = [UIColor whiteColor];
    m_car_wheel_fl_temp.textColor = [UIColor whiteColor];
    m_car_wheel_rr_pressure.textColor = [UIColor whiteColor];
    m_car_wheel_rr_temp.textColor = [UIColor whiteColor];
    m_car_wheel_rl_pressure.textColor = [UIColor whiteColor];
    m_car_wheel_rl_temp.textColor = [UIColor whiteColor];
    }
  
  if ([ovmsAppDelegate myRef].car_tpms_fr_pressure > 0)
    m_car_wheel_fr_pressure.text = [ovmsAppDelegate myRef].car_tpms_fr_pressure_s;
  else
    m_car_wheel_fr_pressure.text = @"";
  if ([ovmsAppDelegate myRef].car_tpms_fr_temp > 0)
    m_car_wheel_fr_temp.text = [ovmsAppDelegate myRef].car_tpms_fr_temp_s;
  else
    m_car_wheel_fr_temp.text = @"";

  if ([ovmsAppDelegate myRef].car_tpms_rr_pressure > 0)
    m_car_wheel_rr_pressure.text = [ovmsAppDelegate myRef].car_tpms_rr_pressure_s;
  else
    m_car_wheel_rr_pressure.text = @"";
  if ([ovmsAppDelegate myRef].car_tpms_rr_temp > 0)
    m_car_wheel_rr_temp.text = [ovmsAppDelegate myRef].car_tpms_rr_temp_s;
  else
    m_car_wheel_rr_temp.text = @"";

  if ([ovmsAppDelegate myRef].car_tpms_fl_pressure > 0)
    m_car_wheel_fl_pressure.text = [ovmsAppDelegate myRef].car_tpms_fl_pressure_s;
  else
    m_car_wheel_fl_pressure.text = @"";
  if ([ovmsAppDelegate myRef].car_tpms_fl_temp > 0)
    m_car_wheel_fl_temp.text = [ovmsAppDelegate myRef].car_tpms_fl_temp_s;
  else
    m_car_wheel_fl_temp.text = @"";
  
  if ([ovmsAppDelegate myRef].car_tpms_rl_pressure > 0)
    m_car_wheel_rl_pressure.text = [ovmsAppDelegate myRef].car_tpms_rl_pressure_s;
  else
    m_car_wheel_rl_pressure.text = @"";
  if ([ovmsAppDelegate myRef].car_tpms_rl_temp > 0)
    m_car_wheel_rl_temp.text = [ovmsAppDelegate myRef].car_tpms_rl_temp_s;
  else
    m_car_wheel_rl_temp.text = @"";
    
    m_car_aux_battery.text = [NSString stringWithFormat:@"%0.1fV",
                                [ovmsAppDelegate myRef].car_aux_battery_voltage];

  ovmsAppDelegate *app = [ovmsAppDelegate myRef];
  BOOL locked = (app.car_doors2 & 0x08) != 0;
  BOOL valet = (app.car_doors2 & 0x10) != 0;
  self.modernSecurityState.text = [NSString stringWithFormat:@"  SECURITY\n  %@  ·  valet %@", locked ? @"Locked" : @"Unlocked", valet ? @"on" : @"off"];
  NSMutableArray *openItems = [NSMutableArray array];
  if (app.car_doors1 & 0x01) [openItems addObject:@"driver door"];
  if (app.car_doors1 & 0x02) [openItems addObject:@"passenger door"];
  if (app.car_doors2 & 0x40) [openItems addObject:@"bonnet"];
  if (app.car_doors2 & 0x80) [openItems addObject:@"boot"];
  self.modernVehicleState.text = [NSString stringWithFormat:@"  VEHICLE\n  %@  ·  12 V %.1f V", [openItems count] ? [openItems componentsJoinedByString:@", "] : @"All doors closed", app.car_aux_battery_voltage];
  self.modernTPMSState.text = [NSString stringWithFormat:@"  TYRE PRESSURES\n  FL %@  ·  FR %@\n  RL %@  ·  RR %@", [app.car_tpms_fl_pressure_s length] ? app.car_tpms_fl_pressure_s : @"--", [app.car_tpms_fr_pressure_s length] ? app.car_tpms_fr_pressure_s : @"--", [app.car_tpms_rl_pressure_s length] ? app.car_tpms_rl_pressure_s : @"--", [app.car_tpms_rr_pressure_s length] ? app.car_tpms_rr_pressure_s : @"--"];
}

- (void)showPINControlWithTitle:(NSString *)title message:(NSString *)message actionTitle:(NSString *)actionTitle handler:(void (^)(NSString *pin))handler
  {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"Vehicle PIN"; field.keyboardType = UIKeyboardTypeNumberPad; field.secureTextEntry = YES; }];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    // Match the legacy PIN form: the vehicle module validates the PIN, including
    // an empty value for modules that do not require one.
    handler(alert.textFields.firstObject.text ?: @"");
  }]];
  [self presentViewController:alert animated:YES completion:nil];
  }

- (void)showLockControl
  {
  BOOL locked = ([ovmsAppDelegate myRef].car_doors2 & 0x08) != 0;
  NSString *verb = locked ? @"Unlock" : @"Lock";
  [self showPINControlWithTitle:[NSString stringWithFormat:@"%@ vehicle", verb] message:@"Enter the vehicle PIN to authorize this security command." actionTitle:verb handler:^(NSString *pin) { if (locked) [[ovmsAppDelegate myRef] commandDoUnlockCar:pin]; else [[ovmsAppDelegate myRef] commandDoLockCar:pin]; }];
  }

- (void)showValetControl
  {
  BOOL enabled = ([ovmsAppDelegate myRef].car_doors2 & 0x10) != 0;
  NSString *verb = enabled ? @"Disable" : @"Enable";
  [self showPINControlWithTitle:[NSString stringWithFormat:@"%@ valet mode", verb] message:@"Enter the vehicle PIN to change valet mode." actionTitle:verb handler:^(NSString *pin) { if (enabled) [[ovmsAppDelegate myRef] commandDoDeactivateValet:pin]; else [[ovmsAppDelegate myRef] commandDoActivateValet:pin]; }];
  }

- (void)showWakeConfirmation
  {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Wake vehicle?" message:@"Ask the OVMS module to wake the vehicle systems." preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Wake" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [[ovmsAppDelegate myRef] commandDoWakeupCar]; }]]; [self presentViewController:alert animated:YES completion:nil];
  }

- (void)showHomelinkControl
  {
  BOOL profiles = [[ovmsAppDelegate myRef] supportsVehicleCapability:OVMSVehicleCapabilityDriveProfiles];
  UIAlertController *sheet = [UIAlertController alertControllerWithTitle:profiles ? @"Drive profiles" : @"Homelink" message:profiles ? @"Choose the Renault Twizy drive profile." : @"Choose the configured transmitter button." preferredStyle:UIAlertControllerStyleActionSheet];
  if (profiles) [sheet addAction:[UIAlertAction actionWithTitle:@"Default profile" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [[ovmsAppDelegate myRef] commandDoDriveProfile:-1]; }]];
  for (int index = 0; index < 3; index++) { [sheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:profiles ? @"Profile %d" : @"Button %d", index + 1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { if (profiles) [[ovmsAppDelegate myRef] commandDoDriveProfile:index]; else [[ovmsAppDelegate myRef] commandDoHomelink:index]; }]]; }
  [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]]; sheet.popoverPresentationController.sourceView=self.view; sheet.popoverPresentationController.sourceRect=CGRectMake(CGRectGetMidX(self.view.bounds),CGRectGetMidY(self.view.bounds),1,1); [self presentViewController:sheet animated:YES completion:nil];
  }

- (void)showDDT4AllControl
  {
  NSArray *titles=@[@"Automatic wipers off",@"Automatic wipers on",@"Switch to Wi-Fi",@"Switch to modem",@"Lock beep off",@"Lock beep on",@"Rear wiper off",@"Rear wiper on"];
  UIAlertController *sheet=[UIAlertController alertControllerWithTitle:@"Scenic DDT4all actions" message:@"Choose a vehicle configuration command. The module must support the xsq DDT4all interface." preferredStyle:UIAlertControllerStyleActionSheet];
  [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger index, BOOL *stop) { [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [[ovmsAppDelegate myRef] commandDoCommand:[NSString stringWithFormat:@"xsq ddt4all %lu",(unsigned long)index+2]]; }]]; }];
  [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]]; sheet.popoverPresentationController.sourceView=self.view; sheet.popoverPresentationController.sourceRect=CGRectMake(CGRectGetMidX(self.view.bounds),CGRectGetMidY(self.view.bounds),1,1); [self presentViewController:sheet animated:YES completion:nil];
  }

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
  {
  if ([[segue identifier] isEqualToString:@"ValetMode"])
    {
    if ([ovmsAppDelegate myRef].car_doors2 & 0x10)
      { // Valet is ON, let's offer to deactivate it
        [[segue destinationViewController] setInstructions:@"Enter PIN\nto deactivate valet mode"];
        [[segue destinationViewController] setFormtitle:@"Valet Mode"];
        [[segue destinationViewController] setFunction:@"Valet Off"];
        [[segue destinationViewController] setDelegate:self];
      }
    else
      { // Valet is OFF, let's offer to activate it
        [[segue destinationViewController] setInstructions:@"Enter PIN\nto activate valet mode"];
        [[segue destinationViewController] setFormtitle:@"Valet Mode"];
        [[segue destinationViewController] setFunction:@"Valet On"];
        [[segue destinationViewController] setDelegate:self];
      }
    }
  else if ([[segue identifier] isEqualToString:@"LockUnlock"])
    {
    if ([ovmsAppDelegate myRef].car_doors2 & 0x08)
      { // Car is locked, let's offer to unlock it
        [[segue destinationViewController] setInstructions:@"Enter PIN\nto unlock car"];
        [[segue destinationViewController] setFormtitle:@"Unlock Car"];
        [[segue destinationViewController] setFunction:@"Unlock Car"];
        [[segue destinationViewController] setDelegate:self];
      }
    else
      { // Car is unlocked, let's offer to lock it
        [[segue destinationViewController] setInstructions:@"Enter PIN\nto lock car"];
        [[segue destinationViewController] setFormtitle:@"Lock Car"];
        [[segue destinationViewController] setFunction:@"Lock Car"];
        [[segue destinationViewController] setDelegate:self];
      }
    }
  }

- (void)omvsControlPINEntryDelegateDidCancel:(NSString*)fn
  {
  }

- (void)omvsControlPINEntryDelegateDidSave:(NSString*)fn pin:(NSString*)pin
  {
  if ([fn isEqualToString:@"Valet On"])
    {
    [[ovmsAppDelegate myRef] commandDoActivateValet:pin];
    }
  else if ([fn isEqualToString:@"Valet Off"])
    {
    [[ovmsAppDelegate myRef] commandDoDeactivateValet:pin];
    }    
  else if ([fn isEqualToString:@"Lock Car"])
    {
    [[ovmsAppDelegate myRef] commandDoLockCar:pin];
    }
  else if ([fn isEqualToString:@"Unlock Car"])
    {
    [[ovmsAppDelegate myRef] commandDoUnlockCar:pin];
    }    
  }

- (IBAction)WakeupButton:(id)sender
  {
  // The wakeup button has been pressed - let's wakeup the car
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Wakeup Car"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Wakeup",nil];
  [actionSheet showInView:[self.view window]];
  }

- (IBAction)HomelinkButon:(id)sender
  {
  // The homelink button has been pressed - let's ask which one he wants
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Homelink"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"1",@"2",@"3",nil];
  [actionSheet showInView:[self.view window]];
  }

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index
  {
  if ([sender.title isEqualToString:@"Wakeup Car"])
    {
    if (index == [sender firstOtherButtonIndex])
      {
      [[ovmsAppDelegate myRef] commandDoWakeupCar];
      }
    }
  else if ([sender.title isEqualToString:@"Homelink"])
    {
    int button = (int)(index - [sender firstOtherButtonIndex]);
    if ((button>=0)&&(button<3))
      {
      [[ovmsAppDelegate myRef] commandDoHomelink:button];
      }
    }
  }

@end
