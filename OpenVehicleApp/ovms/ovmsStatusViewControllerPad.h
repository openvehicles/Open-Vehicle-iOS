//
//  ovmsStatusViewControllerPad.h
//  ovms
//
//  Created by Mark Webb-Johnson on 10/12/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ovmsLocationViewController.h"
#import "ovmsAppDelegate.h"
#import "ovmsControlPINEntry.h"

#import "OCMSyncHelper.h"
#import "EntityName.h"
#import "ChargingAnnotation.h"
#import "NSObject+CDHelper.h"
#import "REVClusterAnnotationView.h"

#import "PopoverView.h"

#define IDENTIFIER_CLUSTER @"cluster"
#define IDENTIFIER_PIN @"pin"

#import <math.h>

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface ovmsStatusViewControllerPad : UIViewController <MKMapViewDelegate, ovmsUpdateDelegate, ovmsControlPINEntryDelegate, OCMSyncDelegate, PopoverViewDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *m_car_connection_image;
@property (strong, nonatomic) IBOutlet UILabel *m_car_connection_state;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_image;
@property (strong, nonatomic) IBOutlet UILabel *m_car_charge_state;
@property (strong, nonatomic) IBOutlet UILabel *m_car_charge_type;
@property (strong, nonatomic) IBOutlet UILabel *m_car_charge_mode;
@property (strong, nonatomic) IBOutlet UILabel *m_car_soc;
@property (strong, nonatomic) IBOutlet UIImageView *m_battery_front;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *m_battery_front_width;
@property (strong, nonatomic) IBOutlet UIImageView *m_battery_charging;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_outlineimage;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_parking_image;
@property (strong, nonatomic) IBOutlet UILabel *m_car_parking_state;
@property (strong, nonatomic) IBOutlet UIImageView *m_charger_plug;
@property (strong, nonatomic) IBOutlet UIImageView *m_charger_button;
@property (strong, nonatomic) IBOutlet UILabel *m_car_range_ideal;
@property (strong, nonatomic) IBOutlet UILabel *m_car_range_estimated;
@property (strong, nonatomic) IBOutlet UILabel *m_car_charge_message;
@property (strong, nonatomic) IBOutlet UILabel *m_car_charge_time;
@property (strong, nonatomic) IBOutlet UILabel *m_car_charge_kwh;
@property (strong, nonatomic) IBOutlet UILabel *m_car_charge_remaining;
@property (strong, nonatomic) IBOutlet UILabel *m_car_charge_remaining_soc;
@property (strong, nonatomic) IBOutlet UILabel *m_car_charge_remaining_range;

@property (strong, nonatomic) IBOutlet UILabel *m_car_aux_battery;

@property (strong, nonatomic) IBOutlet UIImageView *m_car_lockunlock;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_lights;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_door_ld;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_door_rd;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_door_hd;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_door_cp;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_door_tr;
@property (strong, nonatomic) IBOutlet UILabel *m_car_wheel_fr_pressure;
@property (strong, nonatomic) IBOutlet UILabel *m_car_wheel_fr_temp;
@property (strong, nonatomic) IBOutlet UILabel *m_car_wheel_rr_pressure;
@property (strong, nonatomic) IBOutlet UILabel *m_car_wheel_rr_temp;
@property (strong, nonatomic) IBOutlet UILabel *m_car_wheel_fl_pressure;
@property (strong, nonatomic) IBOutlet UILabel *m_car_wheel_fl_temp;
@property (strong, nonatomic) IBOutlet UILabel *m_car_wheel_rl_pressure;
@property (strong, nonatomic) IBOutlet UILabel *m_car_wheel_rl_temp;
@property (strong, nonatomic) IBOutlet UILabel *m_car_temp_pem;
@property (strong, nonatomic) IBOutlet UILabel *m_car_temp_motor;
@property (strong, nonatomic) IBOutlet UILabel *m_car_temp_battery;
@property (strong, nonatomic) IBOutlet UILabel *m_car_temp_pem_l;
@property (strong, nonatomic) IBOutlet UILabel *m_car_temp_motor_l;
@property (strong, nonatomic) IBOutlet UILabel *m_car_temp_battery_l;
@property (strong, nonatomic) IBOutlet UILabel *m_car_ambient_temp;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_valetonoff;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_weather;
@property (strong, nonatomic) IBOutlet UIImageView *m_car_tpmsboxes;

@property (strong, nonatomic) IBOutlet REVClusterMapView *myMapView;
@property (nonatomic, retain) VehicleAnnotation *m_car_location;
@property (strong, nonatomic) NSMutableDictionary* m_groupcar_locations;
@property (assign) BOOL isAutotrack;
@property (assign) BOOL isFiltredChargingStation;
@property (assign) BOOL isUseRange;
@property (assign) BOOL isProcessAnimations;
@property (assign) BOOL isLoadAll;

@property (assign) MKCoordinateRegion m_lastregion;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *m_control_button;
@property (strong, nonatomic) IBOutlet UISlider *m_charger_slider;
@property (strong, nonatomic) IBOutlet UIButton *m_battery_button;
@property (strong, nonatomic) IBOutlet UIButton *m_wakeup_button;
@property (strong, nonatomic) IBOutlet UIButton *m_lock_button;
@property (strong, nonatomic) IBOutlet UIButton *m_valet_button;
@property (strong, nonatomic) IBOutlet UIButton *m_homelink_button;

@property (strong, nonatomic) OCMSyncHelper *loader;
@property (strong, nonatomic, readonly) NSArray *locations;
@property (strong, nonatomic) UIPopoverController *popover;

- (IBAction)ChargeSliderTouch:(id)sender;
- (IBAction)ChargeSliderValue:(id)sender;
- (IBAction)WakeupButton:(id)sender;
- (IBAction)HomelinkButton:(id)sender;
- (IBAction)locationSnapped:(id)sender;

-(void) update;
-(void) groupUpdate:(NSArray*)result;

@end
