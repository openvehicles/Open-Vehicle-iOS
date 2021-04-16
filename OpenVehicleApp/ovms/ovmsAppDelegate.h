//
//  ovmsAppDelegate.h
//  ovms
//
//  Created by Mark Webb-Johnson on 16/11/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CFNetwork/CFSocketStream.h>
#import "time.h"
#import "CoreLocation/CoreLocation.h"
#import "crypto_base64.h"
#import "crypto_md5.h"
#import "crypto_hmac.h"
#import "crypto_rc4.h"
#import "ovmsMessage.h"

#define TOKEN_SIZE 22

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@class GCDAsyncSocket;
@class Reachability;

@protocol ovmsUpdateDelegate
@optional
-(void) update;
-(void) groupUpdate:(NSArray*)result;
-(void) clearMessages;
-(void) addMessage:(OvmsMessage*)message;
@end

@protocol ovmsCommandDelegate
@required
- (void)commandResult:(NSArray*)result;
@end

@interface ovmsAppDelegate : UIResponder <UIApplicationDelegate>
{
  GCDAsyncSocket *asyncSocket;
  NSTimer *tim;
  NSTimer *timreconnect;
  NSInteger networkingCount;
  
  unsigned char token[TOKEN_SIZE+1];
  RC4_CTX rxCrypto;
  RC4_CTX txCrypto;

  NSString* pmToken;
  RC4_CTX pmCrypto;
  MD5_CTX pmDigest;
  
  NSMutableSet* update_delegates;
  id command_delegate;
  
  NSString* apns_deviceid;
  NSString* apns_pushkeytype;
  NSString* apns_devicetoken;
  
  NSString* sel_car;
  NSString* sel_label;
  NSString* sel_netpass;
  NSString* sel_userpass;
  NSString* sel_imagepath;
  NSMutableArray* sel_messages;

  time_t car_lastupdated;
  int car_connected;
  BOOL car_paranoid;
  BOOL car_online;
  
  CLLocationCoordinate2D car_location;
  int car_direction;
  int car_altitude;
  int car_gpslock;
  int car_stale_gps;
  int car_soc;
  NSString* car_units;
  int car_linevoltage;
  int car_chargecurrent;
  NSString* car_chargestate;
  NSString* car_chargemode;
  int car_idealrange;
  int car_estimatedrange;
  int car_chargelimit;
  int car_chargeduration;
  int car_chargeb4;
  int car_chargekwh;
  int car_chargesubstate;
  int car_chargestateN;
  int car_chargemodeN;
  int car_chargetype;

  int car_doors1;
  int car_doors2;
  int car_doors3;
  int car_stale_pemtemps;
  int car_stale_ambienttemps;
  int car_lockstate;
  NSString* car_vin;
  NSString* car_firmware;
  NSString* server_firmware;
  int car_write_enabled;
  NSString* car_type;
  int car_gsmlevel;
  NSString* car_cac;
    
  int car_minutestofull;
  int car_minutestorangelimit;
  int car_minutestosoclimit;
  int car_rangelimit;
  int car_soclimit;

  float car_aux_battery_voltage;
  
  int car_tpem;
  int car_tmotor;
  int car_tbattery;
  int car_trip;
  int car_odometer;
  int car_speed;
  int car_parktime;
  int car_ambient_temp;
  float car_tpms_fr_pressure;
  int car_tpms_fr_temp;
  float car_tpms_rr_pressure;
  int car_tpms_rr_temp;
  float car_tpms_fl_pressure;
  int car_tpms_fl_temp;
  float car_tpms_rl_pressure;
  int car_tpms_rl_temp;
  int car_stale_tpms;

  int car_ambient_weather;
  
  NSString* car_idealrange_s;
  NSString* car_estimatedrange_s;
  NSString* car_tpem_s;
  NSString* car_tmotor_s;
  NSString* car_tbattery_s;
  NSString* car_trip_s;
  NSString* car_odometer_s;
  NSString* car_speed_s;
  NSString* car_ambient_temp_s;
  NSString* car_tpms_fr_pressure_s;
  NSString* car_tpms_rr_pressure_s;
  NSString* car_tpms_fl_pressure_s;
  NSString* car_tpms_rl_pressure_s;
  NSString* car_tpms_fr_temp_s;
  NSString* car_tpms_rr_temp_s;
  NSString* car_tpms_fl_temp_s;
  NSString* car_tpms_rl_temp_s;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSString* sel_car;
@property (strong, nonatomic) NSString* sel_label;
@property (strong, nonatomic) NSString* sel_connection_type_ids;
@property (strong, nonatomic) NSString* sel_netpass;
@property (strong, nonatomic) NSString* sel_userpass;
@property (strong, nonatomic) NSString* sel_imagepath;
@property (strong, nonatomic) NSMutableArray* sel_messages;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSMutableSet* update_delegates;

@property (assign) time_t car_lastupdated;
@property (assign) int car_connected;
@property (assign) BOOL car_paranoid;
@property (assign) BOOL car_online;

@property (assign) CLLocationCoordinate2D car_location;
@property (assign) int car_direction;
@property (assign) int car_altitude;
@property (assign) int car_gpslock;
@property (assign) int car_stale_gps;

@property (assign) int car_soc;
@property (strong, nonatomic) NSString* car_units;
@property (assign) int car_linevoltage;
@property (assign) int car_chargecurrent;
@property (strong, nonatomic) NSString* car_chargestate;
@property (strong, nonatomic) NSString* car_chargemode;
@property (assign) int car_idealrange;
@property (assign) int car_estimatedrange;
@property (assign) int car_chargelimit;
@property (assign) int car_chargeduration;
@property (assign) int car_chargeb4;
@property (assign) int car_chargekwh;
@property (assign) int car_chargesubstate;
@property (assign) int car_chargestateN;
@property (assign) int car_chargemodeN;
@property (assign) int car_chargetype;

@property (assign) int car_minutestofull;
@property (assign) int car_minutestorangelimit;
@property (assign) int car_minutestosoclimit;
@property (assign) int car_rangelimit;        
@property (assign) int car_soclimit;

@property (assign) int car_doors1;
@property (assign) int car_doors2;
@property (assign) int car_doors3;
@property (assign) int car_stale_pemtemps;
@property (assign) int car_stale_ambienttemps;

@property (assign) int car_lockstate;
@property (strong, nonatomic) NSString* car_vin;
@property (strong, nonatomic) NSString* car_firmware;
@property (strong, nonatomic) NSString* server_firmware;
@property (assign) int car_write_enabled;
@property (strong, nonatomic) NSString* car_type;
@property (assign) int car_gsmlevel;
@property (strong, nonatomic) NSString* car_cac;
@property (assign) int car_tpem;
@property (assign) int car_tmotor;
@property (assign) int car_tbattery;
@property (assign) int car_trip;
@property (assign) int car_odometer;
@property (assign) int car_speed;
@property (assign) int car_parktime;
@property (assign) int car_ambient_temp;
@property (assign) float car_tpms_fr_pressure;
@property (assign) int car_tpms_fr_temp;
@property (assign) float car_tpms_rr_pressure;
@property (assign) int car_tpms_rr_temp;
@property (assign) float car_tpms_fl_pressure;
@property (assign) int car_tpms_fl_temp;
@property (assign) float car_tpms_rl_pressure;
@property (assign) int car_tpms_rl_temp;
@property (assign) int car_stale_tpms;

@property (assign) int car_ambient_weather;

@property (assign) float car_aux_battery_voltage;

@property (strong, nonatomic) NSString* car_idealrange_s;
@property (strong, nonatomic) NSString* car_estimatedrange_s;
@property (strong, nonatomic) NSString* car_trip_s;
@property (strong, nonatomic) NSString* car_odometer_s;
@property (strong, nonatomic) NSString* car_speed_s;

@property (strong, nonatomic) NSString* car_tpem_s;
@property (strong, nonatomic) NSString* car_tmotor_s;
@property (strong, nonatomic) NSString* car_tbattery_s;
@property (strong, nonatomic) NSString* car_ambient_temp_s;
@property (strong, nonatomic) NSString* car_tpms_fr_pressure_s;
@property (strong, nonatomic) NSString* car_tpms_rr_pressure_s;
@property (strong, nonatomic) NSString* car_tpms_fl_pressure_s;
@property (strong, nonatomic) NSString* car_tpms_rl_pressure_s;
@property (strong, nonatomic) NSString* car_tpms_fr_temp_s;
@property (strong, nonatomic) NSString* car_tpms_rr_temp_s;
@property (strong, nonatomic) NSString* car_tpms_fl_temp_s;
@property (strong, nonatomic) NSString* car_tpms_rl_temp_s;

+ (ovmsAppDelegate *) myRef;
+ (BOOL)doesSystemVersionMeetRequirement:(NSString *)minRequirement;
+ (void)routeFrom:(CLLocationCoordinate2D)from To:(CLLocationCoordinate2D)to;

- (void)saveContext;
- (void)saveContext:(NSManagedObjectContext *) objectContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)didStartNetworking;
- (void)didStopNetworking;
- (void)serverConnect;
- (void)serverDisconnect;
- (void)serverClearState;
- (void)handleCommand:(char)code command:(NSString*)cmd;
- (void)switchCar:(NSString*)car;
- (void)subscribeGroups;

- (NSString*)convertDistanceUnits:(int)distance;
- (NSString*)convertSpeedUnits:(int)speed;
- (NSString*)convertTemperatureUnits:(int)temp;
- (NSString*)convertPressureUnits:(float)pressure;

- (void)registerForUpdate:(id)target;
- (void)deregisterFromUpdate:(id)target;

- (void)clearMessages;
- (void)addMessage:(OvmsMessage*)message;
- (void)addMessage:(NSString*)text incoming:(BOOL)incoming;

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

- (void)onTick:(NSTimer *)timer;
- (void)onTickReconnect:(NSTimer *)timer;

- (BOOL)commandIsFree;
- (void)commandRegister:(NSString*)command callback:(id)cb;
- (void)commandIssue:(NSString*)command;
- (void)commandResponse:(NSString*)response;
- (void)commandCancel;

- (void)commandDoRequestFeatureList;
- (void)commandDoSetFeature:(int)feature value:(NSString*)value;
- (void)commandDoRequestParameterList;
- (void)commandDoSetParameter:(int)param value:(NSString*)value;
- (void)commandDoReboot;
- (void)commandDoCommand:(NSString*)command;
- (void)commandDoSetChargeMode:(int)mode;
- (void)commandDoStartCharge;
- (void)commandDoStopCharge;
- (void)commandDoSetChargeCurrent:(int)current;
- (void)commandDoSetChargeModecurrent:(int)mode current:(int)current;
- (void)commandDoWakeupCar;
- (void)commandDoWakeupTempSubsystem;
- (void)commandDoLockCar:(NSString*)pin;
- (void)commandDoActivateValet:(NSString*)pin;
- (void)commandDoUnlockCar:(NSString*)pin;
- (void)commandDoDeactivateValet:(NSString*)pin;
- (void)commandDoUSSD:(NSString*)ussd;
- (void)commandDoRequestGPRSData;
- (void)commandDoHomelink:(int)button;

@end
