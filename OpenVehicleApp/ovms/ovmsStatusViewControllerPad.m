//
//  ovmsStatusViewControllerPad.m
//  ovms
//
//  Created by Mark Webb-Johnson on 10/12/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIKit/UIDevice.h"
#import "ovmsStatusViewControllerPad.h"

@implementation ovmsStatusViewControllerPad

@synthesize m_car_connection_image;
@synthesize m_car_connection_state;
@synthesize m_car_image;
@synthesize m_car_charge_state;
@synthesize m_car_charge_type;
@synthesize m_car_charge_mode;
@synthesize m_car_soc;
@synthesize m_battery_front;
@synthesize m_car_outlineimage;
@synthesize m_car_parking_image;
@synthesize m_car_parking_state;
@synthesize m_charger_plug;
@synthesize m_charger_button;
@synthesize m_car_range_ideal;
@synthesize m_car_range_estimated;
@synthesize m_car_charge_message;
@synthesize m_car_lights;
@synthesize m_battery_charging;

@synthesize m_car_lockunlock;
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
@synthesize m_car_valetonoff;
@synthesize m_car_weather;
@synthesize m_car_tpmsboxes;

@synthesize myMapView;
@synthesize m_car_location;
@synthesize m_groupcar_locations;
@synthesize m_lastregion;
@synthesize m_control_button;
@synthesize m_charger_slider;
@synthesize m_battery_button;
@synthesize m_wakeup_button;
@synthesize m_lock_button;
@synthesize m_valet_button;
@synthesize m_homelink_button;

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

- (void)viewDidLoad {
  [super viewDidLoad];
  self.isUseRange = YES;
    

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

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
  
  CGRect bvframe = m_car_temp_pem_l.frame;

  // This seems to pickup the orientation correctly, even if we haven't turned on notifications for it
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  
  if (orientation == UIInterfaceOrientationLandscapeLeft ||
      orientation == UIInterfaceOrientationLandscapeRight)
    {
    myMapView.frame = CGRectMake(20, bvframe.origin.y+bvframe.size.height+44,
                                 984, 635-(bvframe.origin.y+bvframe.size.height+44));
    }
  else
    {
    myMapView.frame = CGRectMake(20, 417, 728, 474);
    }

  [self animateLayer];

  self.m_car_location = nil;
  if (m_groupcar_locations == nil) m_groupcar_locations = [[NSMutableDictionary alloc] init];
  self.isAutotrack = YES;

  [[ovmsAppDelegate myRef] registerForUpdate:self];
    
  [self update];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
  
  // As we are about to disappear, remove all the car location objects
  
  // Remove all existing annotations
  for (int k=0; k < [myMapView.annotations count]; k++)
    { 
      if ([[myMapView.annotations objectAtIndex:k] isKindOfClass:[ovmsVehicleAnnotation class]])
        {
        [myMapView removeAnnotation:[myMapView.annotations objectAtIndex:k]];
        }
    }
  self.m_car_location = nil;
  if (m_groupcar_locations != nil)
    {
    [m_groupcar_locations removeAllObjects];
    m_groupcar_locations = nil;
    }
  
  [[ovmsAppDelegate myRef] deregisterFromUpdate:self];
}

- (void)viewDidUnload
{
    [self setM_car_connection_image:nil];
    [self setM_car_connection_state:nil];
    [self setM_car_image:nil];
    [self setM_car_charge_state:nil];
    [self setM_car_charge_type:nil];
    [self setM_car_soc:nil];
    [self setM_battery_front:nil];
    [self setM_car_lockunlock:nil];
    [self setM_car_door_ld:nil];
    [self setM_car_door_rd:nil];
    [self setM_car_door_hd:nil];
    [self setM_car_door_cp:nil];
    [self setM_car_door_tr:nil];
    [self setM_car_wheel_fr_pressure:nil];
    [self setM_car_wheel_fr_temp:nil];
    [self setM_car_wheel_rr_pressure:nil];
    [self setM_car_wheel_rr_temp:nil];
    [self setM_car_wheel_fl_pressure:nil];
    [self setM_car_wheel_fl_temp:nil];
    [self setM_car_wheel_rl_pressure:nil];
    [self setM_car_wheel_rl_temp:nil];
    [self setM_car_temp_pem:nil];
    [self setM_car_temp_motor:nil];
    [self setM_car_temp_battery:nil];
    [self setM_car_temp_pem_l:nil];
    [self setM_car_temp_motor_l:nil];
    [self setM_car_temp_battery_l:nil];

    [self setMyMapView:nil];
    [self setM_car_outlineimage:nil];
    [self setM_car_parking_image:nil];
    [self setM_car_parking_state:nil];
  
    [self setM_car_ambient_temp:nil];
    [self setM_car_charge_mode:nil];
    [self setM_battery_charging:nil];
    [self setM_charger_plug:nil];
    [self setM_charger_button:nil];
    [self setM_car_range_estimated:nil];
    [self setM_car_range_ideal:nil];
  [self setM_car_valetonoff:nil];
    [self setM_car_lights:nil];
    [self setM_car_charge_message:nil];
    [self setM_control_button:nil];
    [self setM_charger_slider:nil];
    [self setM_battery_button:nil];
    [self setM_wakeup_button:nil];
    [self setM_lock_button:nil];
    [self setM_valet_button:nil];
    [self setM_car_weather:nil];
    [self setM_car_tpmsboxes:nil];
    [self setM_homelink_button:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  CGRect bvframe = m_car_temp_pem_l.frame;
  
  if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
      toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
    myMapView.frame = CGRectMake(20, bvframe.origin.y+bvframe.size.height+44,
                                 984, 635-(bvframe.origin.y+bvframe.size.height+44));
    }
  else
    {
    myMapView.frame = CGRectMake(20, 417, 728, 474);
    }
}

-(void) update
  {
  [self updateStatus];
  [self updateLocation];
  [self updateCar];
  }

-(void) updateStatus
{
  NSString* units;
  if ([[ovmsAppDelegate myRef].car_units isEqualToString:@"K"])
    units = @"km";
  else
    units = @"m";
  
  int connected = [ovmsAppDelegate myRef].car_connected;
  time_t lastupdated = [ovmsAppDelegate myRef].car_lastupdated;
  int seconds = (time(0)-lastupdated);
  int minutes = (time(0)-lastupdated)/60;
  int hours = minutes/60;
  int days = minutes/(60*24);
  
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
    m_control_button.enabled=YES;
    m_battery_button.enabled=YES;
    [m_car_connection_image stopAnimating];
    m_car_connection_image.animationImages = nil;
    m_car_connection_image.image=[UIImage imageNamed:imagewanted];
    }
  else
    {
    m_control_button.enabled=NO;
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
  
  m_car_image.image=[UIImage imageNamed:[ovmsAppDelegate myRef].sel_imagepath];
  m_car_soc.text = [NSString stringWithFormat:@"%d%%",[ovmsAppDelegate myRef].car_soc];
  m_car_range_ideal.text = [ovmsAppDelegate myRef].car_idealrange_s;
  m_car_range_estimated.text = [ovmsAppDelegate myRef].car_estimatedrange_s;
  
  CGRect bounds = m_battery_front.bounds;
  CGPoint center = m_battery_front.center;
  CGFloat oldwidth = bounds.size.width;
  CGFloat newwidth = (((0.0+[ovmsAppDelegate myRef].car_soc)/100.0)*(233-17))+17;
  bounds.size.width = newwidth;
  center.x = center.x + ((newwidth - oldwidth)/2);
  m_battery_front.bounds = bounds;
  m_battery_front.center = center;
  bounds = m_battery_front.bounds;
  
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
          m_car_charge_mode.text = [NSString stringWithFormat:@"%@ %dA",
                                  [[ovmsAppDelegate myRef].car_chargemode uppercaseString],
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

-(void) updateCar
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
  else if ((car_stale_pemtemps == 0)||(([ovmsAppDelegate myRef].car_doors3 & 0x02)==0))
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
  else if ((car_stale_ambienttemps == 0)||(([ovmsAppDelegate myRef].car_doors3 & 0x02)==0))
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
    m_car_wheel_fr_pressure.text = [NSString stringWithFormat:@"%0.1f PSI",
                                    [ovmsAppDelegate myRef].car_tpms_fr_pressure];
    m_car_wheel_fr_temp.text = [ovmsAppDelegate myRef].car_tpms_fr_temp_s;
    }
  else
    {
    m_car_wheel_fr_pressure.text = @"";
    m_car_wheel_fr_temp.text = @"";
    }
  
  if ([ovmsAppDelegate myRef].car_tpms_rr_temp > 0)
    {
    m_car_wheel_rr_pressure.text = [NSString stringWithFormat:@"%0.1f PSI",
                                    [ovmsAppDelegate myRef].car_tpms_rr_pressure];
    m_car_wheel_rr_temp.text = [ovmsAppDelegate myRef].car_tpms_rr_temp_s;
    }
  else
    {
    m_car_wheel_rr_pressure.text = @"";
    m_car_wheel_rr_temp.text = @"";
    }
  
  if ([ovmsAppDelegate myRef].car_tpms_fl_temp > 0)
    {
    m_car_wheel_fl_pressure.text = [NSString stringWithFormat:@"%0.1f PSI",
                                    [ovmsAppDelegate myRef].car_tpms_fl_pressure];
    m_car_wheel_fl_temp.text = [ovmsAppDelegate myRef].car_tpms_fl_temp_s;
    }
  else
    {
    m_car_wheel_fl_pressure.text = @"";
    m_car_wheel_fl_temp.text = @"";
    }
  
  if ([ovmsAppDelegate myRef].car_tpms_rl_temp > 0)
    {
    m_car_wheel_rl_pressure.text = [NSString stringWithFormat:@"%0.1f PSI",
                                    [ovmsAppDelegate myRef].car_tpms_rl_pressure];
    m_car_wheel_rl_temp.text = [ovmsAppDelegate myRef].car_tpms_rl_temp_s;
    }
  else
    {
    m_car_wheel_rl_pressure.text = @"";
    m_car_wheel_rl_temp.text = @"";
    }
}

- (void)loadData:(CLLocationCoordinate2D)location {
    if (!self.loader) {
        self.loader = [[OCMSyncHelper alloc] initWithDelegate:self];
    }
    double estimatedrange = self.isUseRange ? (double)[ovmsAppDelegate myRef].car_estimatedrange : 1000;
    
    NSString *connection_type_ids = [ovmsAppDelegate myRef].sel_connection_type_ids;
    if (self.isFiltredChargingStation && connection_type_ids.length) {
        [self.loader startSyncWhithCoordinate:location toDistance:estimatedrange connectiontypeid:connection_type_ids];
    } else {
        [self.loader startSyncWhithCoordinate:location toDistance:estimatedrange];
    }
}

- (void)didFinishSync {
    [self initAnnotations];
}

- (void)didFailWithError:(NSError *)error {
    [self initAnnotations];
}

- (void)initOverlays {
    double idealrange = [ovmsAppDelegate myRef].car_idealrange * 1000.0;
    double estimatedrange = [ovmsAppDelegate myRef].car_estimatedrange * 1000.0;
    
    [myMapView removeOverlays:myMapView.overlays];
    
    if ((idealrange + estimatedrange) > 0 && self.m_car_location && self.isUseRange) {
        [myMapView addOverlay:[MKCircle circleWithCenterCoordinate:[ovmsAppDelegate myRef].car_location radius:idealrange]];
        [myMapView addOverlay:[MKCircle circleWithCenterCoordinate:[ovmsAppDelegate myRef].car_location radius:estimatedrange]];
    }
}

- (void)initAnnotations {
    [myMapView removeAnnotations:myMapView.annotations];
    
    NSMutableArray *annotations = [NSMutableArray array];
    for (ChargingLocation *loc in self.locations) {
        [annotations addObject:[ChargingAnnotation pinWithChargingLocation:loc]];
    }
    [myMapView addAnnotations:annotations];
    
    if (m_car_location != nil) {
        [myMapView addAnnotation:m_car_location];
        [m_car_location redrawView];
    }

    [self initOverlays];
}

- (NSArray *)locations {
    NSFetchRequest *fr = [self fetchRequestWithEntityName:ENChargingLocation];
    
    if (self.isUseRange) {
        double estimatedrange = (double)[ovmsAppDelegate myRef].car_estimatedrange * 1000;
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(myMapView.centerCoordinate, estimatedrange, estimatedrange);
        
        double minLat = region.center.latitude - (region.span.latitudeDelta);
        double maxLat = region.center.latitude + (region.span.latitudeDelta);
        double minLong = region.center.longitude - (region.span.longitudeDelta);
        double maxLong = region.center.longitude + (region.span.longitudeDelta);
        
        NSPredicate *pr = [NSPredicate predicateWithFormat:@"addres_info.latitude > %f AND addres_info.latitude < %f AND addres_info.longitude > %f AND addres_info.longitude < %f",
                           minLat, maxLat, minLong, maxLong];
        fr.predicate = pr;
    }
    
    if (self.isFiltredChargingStation) {
        NSString *connection_type_ids = [ovmsAppDelegate myRef].sel_connection_type_ids;
        if (connection_type_ids.length) {
            NSMutableArray *ids = [NSMutableArray array];
            for (NSString *sid in [connection_type_ids componentsSeparatedByString:@","]) {
                [ids addObject:[NSNumber numberWithInt:[sid intValue]]];
            }
            
            NSPredicate *pr = [NSPredicate predicateWithFormat:@"ANY conections.connection_type.id IN %@", ids];
            
            if (fr.predicate) {
                fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[fr.predicate, pr]];
            } else {
                fr.predicate = pr;
            }
        }
    }
    return [self executeFetchRequest:fr];
}


-(void)updateLocation {
    // The car has reported updated information, and we may need to reflect that
    CLLocationCoordinate2D location = [ovmsAppDelegate myRef].car_location;
    
    MKCoordinateRegion region = myMapView.region;
    if ( (region.center.latitude != location.latitude)&&
        (region.center.longitude != location.longitude) ) {
        
        [self loadData:location];
        
        if (self.m_car_location) {
            NSLog(@"beginAnimations");
            
            [UIView beginAnimations:@"ovmsVehicleAnnotationAnimation" context:nil];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:2.0];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            [self.m_car_location setDirection:[ovmsAppDelegate myRef].car_direction % 360];
            [self.m_car_location setSpeed:[ovmsAppDelegate myRef].car_speed_s];
            [self.m_car_location setCoordinate: location];
            
            if (self.isAutotrack) {
                region.center = location;
                [myMapView setRegion:region animated:NO];
            }

            [UIView commitAnimations];
        } else {
            NSLog(@"ovmsVehicleAnnotation");
            
            // Remove all existing annotations
            NSMutableArray *annotations = [NSMutableArray array];
            for (id annotation in myMapView.annotations) {
                if (![annotation isKindOfClass:[ovmsVehicleAnnotation class]]) continue;
                [annotations addObject:annotation];
            }
            [myMapView removeAnnotations:annotations];
            
            // Create the vehicle annotation
            ovmsVehicleAnnotation *pa = [[ovmsVehicleAnnotation alloc] initWithCoordinate:location];
            [pa setTitle:[ovmsAppDelegate myRef].sel_car];
            [pa setSubtitle:[ovmsAppDelegate myRef].car_speed_s];
            [pa setImagefile:[ovmsAppDelegate myRef].sel_imagepath];
            [pa setDirection:([ovmsAppDelegate myRef].car_direction) % 360];
            [pa setSpeed:[ovmsAppDelegate myRef].car_speed_s];
            [myMapView addAnnotation:pa];
            self.m_car_location = pa;
            
            // Setup the map to surround the vehicle
            MKCoordinateSpan span;
            span.latitudeDelta = 0.01;
            span.longitudeDelta = 0.01;
            region.span = span;
            region.center = location;
            
//            double estimatedrange = (double)[ovmsAppDelegate myRef].car_estimatedrange * 1000.0;
//            region = MKCoordinateRegionMakeWithDistance(location, estimatedrange, estimatedrange);
            
            [myMapView setRegion:region animated:YES];
            [myMapView regionThatFits:region]; 
        }
    }
}

-(void) groupUpdate:(NSArray*)result
{
  if (m_groupcar_locations == nil) return;
  
  if ([result count]>=10)
    {
    NSString *vehicleid = [result objectAtIndex:0];
    //NSString *groupid = [result objectAtIndex:1];
    //int soc = [[result objectAtIndex:2] intValue];
    int speed = [[result objectAtIndex:3] intValue];
    int direction = [[result objectAtIndex:4] intValue];
    //int altitude = [[result objectAtIndex:5] intValue];
    int gpslock = [[result objectAtIndex:6] intValue];
    int stalegps = [[result objectAtIndex:7] intValue];
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(
                                                                 [[result objectAtIndex:8] doubleValue], 
                                                                 [[result objectAtIndex:9] doubleValue]);
    
    if ((gpslock < 1)||(stalegps<1)) return; // No GPS lock or data
    if ([vehicleid isEqualToString:[ovmsAppDelegate myRef].sel_car]) return; // Not the selected car 
    
    NSLog(@"groupUpdate for %@", vehicleid);
    ovmsVehicleAnnotation *pa = [m_groupcar_locations objectForKey:vehicleid];
    if (pa != nil)
      {
      // Update an existing car
      [pa setCoordinate:location];
      [pa setTitle:vehicleid];
      [pa setSubtitle:[ovmsAppDelegate myRef].car_speed_s];
      [pa setImagefile:@"connection_good.png"];
      [pa setDirection:direction];
      [pa setSpeed:[[ovmsAppDelegate myRef] convertSpeedUnits:speed]];
      }
    else
      {
      // Create a new car
      pa = [[ovmsVehicleAnnotation alloc] initWithCoordinate:location];
      [pa setGroupCar:YES];
      [pa setTitle:vehicleid];
      [pa setSubtitle:[ovmsAppDelegate myRef].car_speed_s];
      [pa setImagefile:@"car_default.png"];
      [pa setDirection:direction%360];
      [pa setSpeed:[[ovmsAppDelegate myRef] convertSpeedUnits:speed]];
      [m_groupcar_locations setObject:pa forKey:vehicleid];
      [myMapView addAnnotation:pa];
      NSLog(@"groupCarCreated %@ count=%d", vehicleid,[[myMapView annotations] count]);
      }
    }  
}

- (IBAction)ChargeSliderTouch:(id)sender {
  if (([[ovmsAppDelegate myRef].car_chargestate isEqualToString:@"done"])||
      ([[ovmsAppDelegate myRef].car_chargestate isEqualToString:@"stopped"]))
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

- (IBAction)ChargeSliderValue:(id)sender {
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"ValetMode"])
    {
    if ([ovmsAppDelegate myRef].car_doors2 & 0x10)
      { // Valet is ON, let's offer to deactivate it
        [[segue destinationViewController] setInstructions:@"Enter PIN\nto deactivate valet mode"];
        [[segue destinationViewController] setHeading:@"Valet Mode"];
        [[segue destinationViewController] setFunction:@"Valet Off"];
        [[segue destinationViewController] setDelegate:self];
      }
    else
      { // Valet is OFF, let's offer to activate it
        [[segue destinationViewController] setInstructions:@"Enter PIN\nto activate valet mode"];
        [[segue destinationViewController] setHeading:@"Valet Mode"];
        [[segue destinationViewController] setFunction:@"Valet On"];
        [[segue destinationViewController] setDelegate:self];
      }
    }
  else if ([[segue identifier] isEqualToString:@"LockUnlock"])
    {
    if ([ovmsAppDelegate myRef].car_doors2 & 0x08)
      { // Car is locked, let's offer to unlock it
        [[segue destinationViewController] setInstructions:@"Enter PIN\nto unlock car"];
        [[segue destinationViewController] setHeading:@"Unlock Car"];
        [[segue destinationViewController] setFunction:@"Unlock Car"];
        [[segue destinationViewController] setDelegate:self];
      }
    else
      { // Car is unlocked, let's offer to lock it
        [[segue destinationViewController] setInstructions:@"Enter PIN\nto lock car"];
        [[segue destinationViewController] setHeading:@"Lock Car"];
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

- (IBAction)locationSnapped:(id)sender {
    NSArray *options = @[
                         self.isAutotrack ? NSLocalizedString(@"Turn OFF autotrack", nil) : NSLocalizedString(@"Turn ON autotrack", nil),
                         self.isFiltredChargingStation ? NSLocalizedString(@"All charging stations", nil) : NSLocalizedString(@"Filtered charging stations", nil),
                         self.isUseRange ? NSLocalizedString(@"Ignore range", nil) : NSLocalizedString(@"Use range", nil)
                         ];
    
    [PopoverView showPopoverAtPoint:CGPointMake(10, 0)
                             inView:self.view
                          withTitle:NSLocalizedString(@"Options", nil)
                    withStringArray:options
                           delegate:self];
}

#pragma mark - PopoverViewDelegate Methods
- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index {
    switch (index) {
        case 0: {
            self.isAutotrack = !self.isAutotrack;
            if (self.isAutotrack && m_car_location) {
                [myMapView setCenterCoordinate:m_car_location.coordinate animated:YES];
                if (self.m_car_location) [self loadData:[ovmsAppDelegate myRef].car_location];
            }
            break;
        }
        case 1: {
            if (![ovmsAppDelegate myRef].sel_connection_type_ids.length) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil)
                                                                message:NSLocalizedString(@"The selected car has no setup of charger type. Please go to settings car and setup the charger types.", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                self.isFiltredChargingStation = !self.isFiltredChargingStation;
                if (self.m_car_location) [self loadData:[ovmsAppDelegate myRef].car_location];
            }
            break;
        }
        case 2: {
            self.isUseRange = !self.isUseRange;
            if (self.m_car_location) [self loadData:[ovmsAppDelegate myRef].car_location];
            break;
        }
    }
    
    [popoverView showSuccess];
    [popoverView performSelector:@selector(dismiss) withObject:nil afterDelay:0.5f];
}

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(int)index
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
    int button = index - [sender firstOtherButtonIndex];
    if ((button>=0)&&(button<3))
      {
      [[ovmsAppDelegate myRef] commandDoHomelink:button];
      }
    }
  }

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    // Provide a custom view for the ovmsVehicleAnnotation
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    static NSString *ovmsAnnotationIdentifier=@"OVMSAnnotationIdentifier";
    if([annotation isKindOfClass:[ovmsVehicleAnnotation class]]) {
        MKAnnotationView *annotationView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ovmsAnnotationIdentifier];
        
        //Here's where the magic happens
        ovmsVehicleAnnotation *pa = (ovmsVehicleAnnotation*)annotation;
        NSLog(@"setupView for %@", pa.title);
        [pa setupView:annotationView mapView:myMapView];
        return annotationView;
    }
    
    
    ChargingAnnotation *pin = (ChargingAnnotation *)annotation;
    MKAnnotationView *annView;
    
    if ([pin nodeCount] > 0 ){
        annView = (REVClusterAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:IDENTIFIER_CLUSTER];
        
        if (!annView) {
            annView = (REVClusterAnnotationView*) [[REVClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:IDENTIFIER_CLUSTER];
        }
        
        if ([pin nodeCount] < 10) {
            annView.image = [UIImage imageNamed:@"cluster0.png"];
        } else {
            if ([pin nodeCount] < 100) {
                annView.image = [UIImage imageNamed:@"cluster1.png"];
            } else {
                annView.image = [UIImage imageNamed:@"cluster2.png"];
            }
        }
        
        [(REVClusterAnnotationView*)annView setClusterText: [NSString stringWithFormat:@"%i",[pin nodeCount]]];
        annView.canShowCallout = NO;
    } else {
        annView = [mapView dequeueReusableAnnotationViewWithIdentifier:IDENTIFIER_PIN];
        if (!annView) {
            annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:IDENTIFIER_PIN];
        }
        
        annView.image = [UIImage imageNamed:[NSString stringWithFormat:@"level%d.png", pin.level]];
        annView.canShowCallout = YES;
        annView.centerOffset = CGPointMake(0.0, -25.0);
    }
    return annView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view isKindOfClass:[REVClusterAnnotationView class]]) {
        CLLocationCoordinate2D centerCoordinate = [(REVClusterPin *)view.annotation coordinate];
        MKCoordinateSpan newSpan = MKCoordinateSpanMake(mapView.region.span.latitudeDelta / 2.0, mapView.region.span.longitudeDelta / 2.0);
        [mapView setRegion:MKCoordinateRegionMake(centerCoordinate, newSpan) animated:YES];
        
        return;
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    NSLog(@"regionWillChangeAnimated");
    m_lastregion = mapView.region;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MKCoordinateRegion newRegion = mapView.region;
    
    if (((m_lastregion.span.latitudeDelta / newRegion.span.latitudeDelta) > 1.5)||
        ((m_lastregion.span.latitudeDelta / newRegion.span.latitudeDelta) < 0.75)) {
        NSLog(@"regionDidChangeAnimated");
        
        
        // Kludgy redraw of all annotations, by removing then replacing the annotations...
        for (int k=0; k < [myMapView.annotations count]; k++) {
            ovmsVehicleAnnotation *pa = [myMapView.annotations objectAtIndex:k];
            if ([pa isKindOfClass:[ovmsVehicleAnnotation class]]) {
                [myMapView removeAnnotation:[myMapView.annotations objectAtIndex:k]];
            }
        }
        
        if (m_car_location != nil) {
            [myMapView addAnnotation:m_car_location];
            [m_car_location redrawView];
        }
        
        NSEnumerator *enumerator = [m_groupcar_locations objectEnumerator];
        ovmsVehicleAnnotation *pa;
        while ((pa = [enumerator nextObject])) {
            [myMapView addAnnotation:pa];
            [pa redrawView];
        }
    }
}

- (void) mapView:(MKMapView *)aMapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *view in views) {
        if ([[view annotation] isKindOfClass:[ovmsVehicleAnnotation class]]) {
            [[view superview] bringSubviewToFront:view];
        } else {
            [[view superview] sendSubviewToBack:view];
        }
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay {
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    circleView.lineWidth = 3;
    
    if ([mapView.overlays indexOfObject:overlay]) {
        circleView.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.4];
    } else {
        circleView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
    }
    
    return circleView;
}


@end
