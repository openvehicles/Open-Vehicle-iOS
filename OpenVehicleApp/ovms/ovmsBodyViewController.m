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
@synthesize m_car_temp_cabin_l;
@synthesize m_car_ambient_temp;
@synthesize m_car_cabin_temp;
@synthesize m_car_hvac_status;
@synthesize m_car_weather;
@synthesize m_car_tpmsboxes;
@synthesize m_lock_button;
@synthesize m_valet_button;
@synthesize m_wakeup_button;
@synthesize m_homelink_button;
@synthesize m_climatecontrol_button;
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
  
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
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
  [self setM_car_temp_cabin_l:nil];
  [self setM_car_outlineimage:nil];
  [self setM_car_ambient_temp:nil];
  [self setM_car_cabin_temp:nil];
  [self setM_car_hvac_status:nil];
  [self setM_car_valetonoff:nil];
  [self setM_car_lights:nil];
  [self setM_lock_button:nil];
  [self setM_valet_button:nil];
  [self setM_wakeup_button:nil];
  [self setM_car_weather:nil];
  [self setM_car_tpmsboxes:nil];
  [self setM_homelink_button:nil];
  [self setM_car_aux_battery:nil];
  [self setM_climatecontrol_button:nil];
}

- (void)viewWillAppear:(BOOL)animated
  {
  [super viewWillAppear:animated];
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;

  [[ovmsAppDelegate myRef] registerForUpdate:self];

  [self animateLayer];
  [self update];
  }

- (void)viewDidAppear:(BOOL)animated
  {
  [super viewDidAppear:animated];
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
    m_climatecontrol_button.enabled=YES;
    }
  else
    {
    m_lock_button.enabled=NO;
    m_valet_button.enabled=NO;
    m_wakeup_button.enabled=NO;    
    m_homelink_button.enabled=NO;
    m_climatecontrol_button.enabled=NO;
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
    m_car_cabin_temp.hidden = YES;
    m_car_hvac_status.hidden = YES;
    m_car_temp_pem_l.textColor = [UIColor grayColor];
    m_car_temp_motor_l.textColor = [UIColor grayColor];
    m_car_temp_battery_l.textColor = [UIColor grayColor];
    m_car_temp_cabin_l.textColor = [UIColor grayColor];
    }
  else if (car_stale_pemtemps == 0)
    {
    // Stale PEM temperatures
    m_car_temp_pem.hidden = NO;
    m_car_temp_motor.hidden = NO;
    m_car_temp_battery.hidden = NO;
    m_car_cabin_temp.hidden = NO;
    m_car_hvac_status.hidden = NO;
    m_car_temp_pem.textColor = [UIColor grayColor];
    m_car_temp_pem_l.textColor = [UIColor grayColor];
    m_car_temp_motor.textColor = [UIColor grayColor];
    m_car_temp_motor_l.textColor = [UIColor grayColor];
    m_car_temp_battery.textColor = [UIColor grayColor];
    m_car_temp_battery_l.textColor = [UIColor grayColor];
    m_car_cabin_temp.textColor = [UIColor grayColor];
    m_car_temp_cabin_l.textColor = [UIColor grayColor];
    m_car_hvac_status.textColor = [UIColor grayColor];
    m_car_temp_pem.text = [ovmsAppDelegate myRef].car_tpem_s;
    m_car_temp_motor.text = [ovmsAppDelegate myRef].car_tmotor_s;
    m_car_temp_battery.text = [ovmsAppDelegate myRef].car_tbattery_s;
    m_car_cabin_temp.text = [ovmsAppDelegate myRef].car_cabin_temp_s;
    m_car_hvac_status.text = [ovmsAppDelegate myRef].car_hvac_s;
    }
  else
    {
    // OK PEM temperatures
    m_car_temp_pem.hidden = NO;
    m_car_temp_motor.hidden = NO;
    m_car_temp_battery.hidden = NO;
    m_car_cabin_temp.hidden = NO;
    m_car_hvac_status.hidden = NO;
    m_car_temp_pem.textColor = [UIColor whiteColor];
    m_car_temp_pem_l.textColor = [UIColor whiteColor];
    m_car_temp_motor.textColor = [UIColor whiteColor];
    m_car_temp_motor_l.textColor = [UIColor whiteColor];
    m_car_temp_battery.textColor = [UIColor whiteColor];
    m_car_temp_battery_l.textColor = [UIColor whiteColor];
    m_car_cabin_temp.textColor = [UIColor whiteColor];
    m_car_temp_cabin_l.textColor = [UIColor whiteColor];
    m_car_hvac_status.textColor = [UIColor whiteColor];
    m_car_temp_pem.text = [ovmsAppDelegate myRef].car_tpem_s;
    m_car_temp_motor.text = [ovmsAppDelegate myRef].car_tmotor_s;
    m_car_temp_battery.text = [ovmsAppDelegate myRef].car_tbattery_s;
    m_car_cabin_temp.text = [ovmsAppDelegate myRef].car_cabin_temp_s;
    m_car_hvac_status.text = [ovmsAppDelegate myRef].car_hvac_s;
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
  
  if ([ovmsAppDelegate myRef].car_tpms_fr_temp > 0)
    {
    m_car_wheel_fr_pressure.text = [ovmsAppDelegate myRef].car_tpms_fr_pressure_s;
    m_car_wheel_fr_temp.text = [ovmsAppDelegate myRef].car_tpms_fr_temp_s;
    }
  else
    {
    m_car_wheel_fr_temp.text = @"";
    }
  if ([ovmsAppDelegate myRef].car_tpms_fr_pressure > 0)
    {
    m_car_wheel_fr_pressure.text = [NSString stringWithFormat:@"%0.1f PSI",
                                    [ovmsAppDelegate myRef].car_tpms_fr_pressure];
    }
  else
    {
    m_car_wheel_fr_pressure.text = @"";
    }

  if ([ovmsAppDelegate myRef].car_tpms_rr_temp > 0)
    {
    m_car_wheel_rr_pressure.text = [ovmsAppDelegate myRef].car_tpms_rr_pressure_s;
    m_car_wheel_rr_temp.text = [ovmsAppDelegate myRef].car_tpms_rr_temp_s;
    }
  else
    {
    m_car_wheel_rr_temp.text = @"";
    }
  if ([ovmsAppDelegate myRef].car_tpms_rr_pressure > 0)
    {
    m_car_wheel_rr_pressure.text = [NSString stringWithFormat:@"%0.1f PSI",
                                    [ovmsAppDelegate myRef].car_tpms_rr_pressure];
    }
  else
    {
    m_car_wheel_rr_pressure.text = @"";
    }

  if ([ovmsAppDelegate myRef].car_tpms_fl_temp > 0)
    {
    m_car_wheel_fl_pressure.text = [ovmsAppDelegate myRef].car_tpms_fl_pressure_s;
    m_car_wheel_fl_temp.text = [ovmsAppDelegate myRef].car_tpms_fl_temp_s;
    }
  else
    {
    m_car_wheel_fl_temp.text = @"";
    }
  if ([ovmsAppDelegate myRef].car_tpms_fl_pressure > 0)
    {
    m_car_wheel_fl_pressure.text = [NSString stringWithFormat:@"%0.1f PSI",
                                    [ovmsAppDelegate myRef].car_tpms_fl_pressure];
    }
  else
    {
    m_car_wheel_fl_pressure.text = @"";
    }
  
  if ([ovmsAppDelegate myRef].car_tpms_rl_temp > 0)
    {
    m_car_wheel_rl_pressure.text = [ovmsAppDelegate myRef].car_tpms_rl_pressure_s;
    m_car_wheel_rl_temp.text = [ovmsAppDelegate myRef].car_tpms_rl_temp_s;
    }
  else
    {
    m_car_wheel_rl_temp.text = @"";
    }
  if ([ovmsAppDelegate myRef].car_tpms_rl_pressure > 0)
    {
    m_car_wheel_rl_pressure.text = [NSString stringWithFormat:@"%0.1f PSI",
                                    [ovmsAppDelegate myRef].car_tpms_rl_pressure];
    }
  else
    {
    m_car_wheel_rl_pressure.text = @"";
    }
    
    m_car_aux_battery.text = [NSString stringWithFormat:@"%0.1fV",
                                [ovmsAppDelegate myRef].car_aux_battery_voltage];
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

- (IBAction)ClimateControlButton:(id)sender
{
    // The climate control button has been pressed - let's heat/cool the car
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Climate Control"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Stop",@"Start",nil];
    [actionSheet showInView:[self.view window]];
}


- (IBAction)HomelinkButton:(id)sender
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
  else if ([sender.title isEqualToString:@"Climate Control"])
    {
    int button = (int)(index - [sender firstOtherButtonIndex]);
    if ((button>=0)&&(button<2))
      {
      [[ovmsAppDelegate myRef] commandDoClimateControl:button];
      }
    }
  }

@end
