//
//  ovmsStatusViewController.m
//  ovms
//
//  Created by Mark Webb-Johnson on 16/11/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import "ovmsStatusViewController.h"
#import "JHNotificationManager.h"

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
@synthesize m_car_charge_remaining_soc;
@synthesize m_car_charge_remaining_range;

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
  
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;

  [self update];
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
  [self setM_car_charge_remaining_soc:nil];
  [self setM_car_charge_remaining_range:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
  
  [[ovmsAppDelegate myRef] registerForUpdate:self];

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
  int chargeremainingtimesoc = [ovmsAppDelegate myRef].car_minutestosoclimit;
  int chargeremainingtimerange = [ovmsAppDelegate myRef].car_minutestorangelimit;
  int chargesoclimit = [ovmsAppDelegate myRef].car_soclimit;
  int chargerangelimit = [ovmsAppDelegate myRef].car_rangelimit;
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
    
    if (chargeremainingtimesoc <= 0)
      {
      m_car_charge_remaining_soc.text = @"";
      }
    else if (chargeremainingtimesoc < 60)
      {
      m_car_charge_remaining_soc.text = [NSString stringWithFormat:@"%d%% %d mins",chargesoclimit ,chargeremainingtimesoc];
      }
    else
      {
      m_car_charge_remaining_soc.text = [NSString stringWithFormat:@"%d%% %02d:%02d",chargesoclimit ,
                                         chargeremainingtimesoc/60,
                                         chargeremainingtimesoc%60];
      }
    
    if (chargeremainingtimerange <= 0)
      {
      m_car_charge_remaining_range.text = @"";
      }
    else if (chargeremainingtimerange < 60)
      {
      m_car_charge_remaining_range.text = [NSString stringWithFormat:@"%dkm %d mins",chargerangelimit ,chargeremainingtimerange];
      }
    else
      {
        m_car_charge_remaining_range.text = [NSString stringWithFormat:@"%dkm %02d:%02d",chargerangelimit ,
                                         chargeremainingtimerange/60,
                                         chargeremainingtimerange%60];
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
    
  center = m_car_charge_remaining_soc.center;
        center.x = (m_battery_front.center.x+bounds.size.width/2 + 233+17)/2;
  m_car_charge_remaining_soc.center = center;
      
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
