//
//  ovmsAppDelegate.m
//  ovms
//
//  Created by Mark Webb-Johnson on 16/11/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import <TargetConditionals.h>
#import "ovmsAppDelegate.h"
#import "GCDAsyncSocket.h"
#import "JHNotificationManager.h"
#import "Reachability.h"
#import "Cars.h"

@implementation ovmsAppDelegate

@synthesize window = _window;

@synthesize sel_car;
@synthesize sel_label;
@synthesize sel_netpass;
@synthesize sel_userpass;
@synthesize sel_imagepath;
@synthesize sel_messages;

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

@synthesize update_delegates;

@synthesize car_lastupdated;
@synthesize car_connected;
@synthesize car_paranoid;
@synthesize car_online;

@synthesize car_location;
@synthesize car_direction;
@synthesize car_altitude;
@synthesize car_gpslock;
@synthesize car_stale_gps;

@synthesize car_soc;
@synthesize car_units;
@synthesize car_linevoltage;
@synthesize car_chargecurrent;
@synthesize car_chargestate;
@synthesize car_chargemode;
@synthesize car_idealrange;
@synthesize car_estimatedrange;
@synthesize car_chargelimit;
@synthesize car_chargeduration;
@synthesize car_chargeb4;
@synthesize car_chargekwh;
@synthesize car_chargesubstate;
@synthesize car_chargestateN;
@synthesize car_chargemodeN;
@synthesize car_chargetype;

@synthesize car_minutestofull;
@synthesize car_minutestorangelimit;
@synthesize car_minutestosoclimit;
@synthesize car_rangelimit;
@synthesize car_soclimit;

@synthesize car_doors1;
@synthesize car_doors2;
@synthesize car_doors3;
@synthesize car_stale_pemtemps;
@synthesize car_stale_ambienttemps;
@synthesize car_lockstate;
@synthesize car_vin;
@synthesize car_firmware;
@synthesize server_firmware;
@synthesize car_write_enabled;
@synthesize car_type;
@synthesize car_gsmlevel;
@synthesize car_cac;
@synthesize car_tpem;
@synthesize car_tmotor;
@synthesize car_tbattery;
@synthesize car_trip;
@synthesize car_odometer;
@synthesize car_speed;
@synthesize car_parktime;
@synthesize car_ambient_temp;
@synthesize car_tpms_fr_pressure;
@synthesize car_tpms_fr_temp;
@synthesize car_tpms_rr_pressure;
@synthesize car_tpms_rr_temp;
@synthesize car_tpms_fl_pressure;
@synthesize car_tpms_fl_temp;
@synthesize car_tpms_rl_pressure;
@synthesize car_tpms_rl_temp;
@synthesize car_stale_tpms;

@synthesize car_ambient_weather;

@synthesize car_idealrange_s;
@synthesize car_estimatedrange_s;
@synthesize car_tpem_s;
@synthesize car_tmotor_s;
@synthesize car_tbattery_s;
@synthesize car_trip_s;
@synthesize car_odometer_s;
@synthesize car_speed_s;
@synthesize car_ambient_temp_s;
@synthesize car_tpms_fr_pressure_s;
@synthesize car_tpms_rr_pressure_s;
@synthesize car_tpms_fl_pressure_s;
@synthesize car_tpms_rl_pressure_s;
@synthesize car_tpms_fr_temp_s;
@synthesize car_tpms_rr_temp_s;
@synthesize car_tpms_fl_temp_s;
@synthesize car_tpms_rl_temp_s;

@synthesize car_aux_battery_voltage;

+ (ovmsAppDelegate *) myRef
{
  //return self;
  return (ovmsAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Set the application defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSDictionary *appDefaults = [NSDictionary
                               dictionaryWithObjectsAndKeys:@"tmc.openvehicles.com", @"ovmsServer",
                                                            @"6867", @"ovmsPort",
                                                            @"1", @"ovmsShareColour",
                                                            @"1", @"ovmsOpenChargeMap",
                                                            @"-", @"ovmsTemperatures",
                                                            @"-", @"ovmsDistances",
                                                            @"-", @"ovmsPressures",
                                                            @"DEMO", @"selCar",
                                                            @"Demonstration Car", @"selLabel",
                                                            @"DEMO", @"selNetPass",
                                                            @"DEMO", @"selUserPass",
                                                            @"car_roadster_lightninggreen.png", @"selImagePath",
                                                            @"", @"apnsDeviceid",
                                                            @"", @"locationGroups",
                                                            @"", @"cacheWeatherCar",
                                                            @"", @"cacheWeatherTemp",
                                                            @"", @"cacheWeatherTimeout",
                                                            nil];
  [defaults registerDefaults:appDefaults];
  [defaults synchronize];

  apns_deviceid = [defaults stringForKey:@"apnsDeviceid"];
  apns_devicetoken = @"";
  #ifdef DEBUG
  apns_pushkeytype = @"sandbox";
  #else
  apns_pushkeytype = @"production";
  #endif
  
  if ([apns_deviceid length] == 0)
    {
    CFUUIDRef     myUUID;
    CFStringRef   myUUIDString;
  
    myUUID = CFUUIDCreate(kCFAllocatorDefault);
    myUUIDString = CFUUIDCreateString(kCFAllocatorDefault, myUUID);
  
    apns_deviceid = (__bridge_transfer NSString*)myUUIDString;
    }

  sel_car = [defaults stringForKey:@"selCar"];
  sel_label = [defaults stringForKey:@"selLabel"];
  self.sel_connection_type_ids = [defaults stringForKey:@"selConnectionTypeIds"];
  sel_netpass = [defaults stringForKey:@"selNetPass"];
  sel_userpass = [defaults stringForKey:@"selUserPass"];
  sel_imagepath = [defaults stringForKey:@"selImagePath"];
  
  NSManagedObjectContext *context = [self managedObjectContext];
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  [request setEntity: [NSEntityDescription entityForName:@"Cars" inManagedObjectContext: context]];
  NSError *error = nil;
  NSUInteger count = [context countForFetchRequest: request error: &error];
  if (count == 0)
    {
    Cars *car = [NSEntityDescription
                  insertNewObjectForEntityForName:@"Cars" 
                  inManagedObjectContext:context];
    car.vehicleid = @"DEMO";
    car.label = @"Demonstration Car";
    car.netpass = @"DEMO";
    car.userpass = @"DEMO";
    car.imagepath = @"car_roadster_lightninggreen.png";
    if (![context save:&error])
      {
      NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
      }
    }
  
  // Let the device know we want to receive push notifications
#if TARGET_IPHONE_SIMULATOR
  // Nothing to do on the simulator, as APNS not supported by Apple
  NSLog(@"No PUSH notifications on simultor, apns_deviceid: %@", apns_deviceid);
#else
  NSLog(@"Registering for PUSH notifications apns_deviceid: %@", apns_deviceid);
    //-- Set Notification
   if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
   {
       // iOS 8 Notifications
       [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil]];
       [application registerForRemoteNotifications];
   }
   else
   {
       // iOS < 8 Notifications
       [application registerForRemoteNotificationTypes:
        (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
   }
#endif // TARGET_IPHONE_SIMULATOR

  if (SYSTEM_VERSION_LESS_THAN(@"7.0"))
    {
    // Nasty kludge for iOS <7.0 to seet tint colour to black
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
    [[UITabBar appearance] setTintColor:[UIColor blackColor]];
    }
    
  return YES;
}
	
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
  const unsigned *tokenBytes = [deviceToken bytes];
  apns_devicetoken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                        ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                        ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                        ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
  NSLog(@"My token is: %@", apns_devicetoken);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
  
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
  NSString *message = nil;
  NSDictionary* aps = [userInfo objectForKey:@"aps"];
  if (aps == nil) return;
  
  id alert = [aps objectForKey:@"alert"];
  if ([alert isKindOfClass:[NSString class]])
    {
    message = alert;
    }
  else if ([alert isKindOfClass:[NSDictionary class]])
    {
    message = [alert objectForKey:@"body"];
    }
  
  [JHNotificationManager notificationWithMessage:message];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:apns_deviceid forKey:@"apnsDeviceid"];
  [defaults setObject:sel_car forKey:@"selCar"];
  [defaults setObject:sel_label forKey:@"selLabel"];
  [defaults setObject:self.sel_connection_type_ids forKey:@"selConnectionTypeIds"];
  [defaults setObject:sel_netpass forKey:@"selNetPass"];
  [defaults setObject:sel_userpass forKey:@"selUserPass"];
  [defaults setObject:sel_imagepath forKey:@"selImagePath"];
  [defaults synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
  [self serverDisconnect];
  [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */    
    car_ambient_weather = -1;
    [self serverConnect];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
    */
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:apns_deviceid forKey:@"apnsDeviceid"];
  [defaults setObject:sel_car forKey:@"selCar"];
  [defaults setObject:sel_label forKey:@"selLabel"];
  [defaults setObject:self.sel_connection_type_ids forKey:@"selConnectionTypeIds"];
  [defaults setObject:sel_netpass forKey:@"selNetPass"];
  [defaults setObject:sel_userpass forKey:@"selUserPass"];
  [defaults setObject:sel_imagepath forKey:@"selImagePath"];
  [defaults synchronize];

  [self serverDisconnect];
  [self saveContext];
}

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)saveContext {
  NSError *error = nil;
  NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
  if (managedObjectContext != nil)
    {
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
      {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
      } 
    } else {
        NSLog(@"managedObjectContext is nil");
    }
}

- (void)saveContext:(NSManagedObjectContext *) objectContext {
    NSError *error = nil;
    if (objectContext != nil)
    {
        if ([objectContext hasChanges] && ![objectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    } else {
        NSLog(@"objectContext is nil");
    }
}


- (void)switchCar:(NSString*)car
{
  // We need to get the car record
  NSString* oldcar = sel_car;
  NSString* oldnewpass = sel_netpass;
  
  NSManagedObjectContext *context = [self managedObjectContext];
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  [request setEntity: [NSEntityDescription entityForName:@"Cars" inManagedObjectContext: context]];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"vehicleid == %@", car];
  [request setPredicate:predicate];
  NSError *error = nil;
  NSArray *array = [context executeFetchRequest:request error:&error];
  if (array != nil)
    {
    if ([array count]>0)
      {
      Cars* car = [array objectAtIndex:0];
      sel_car = car.vehicleid;
      sel_label = car.label;
      self.sel_connection_type_ids = car.connection_type_ids;
      sel_userpass = car.userpass;
      sel_netpass = car.netpass;
      sel_imagepath = car.imagepath;
      if ((![oldcar isEqualToString:sel_car])||(![oldnewpass isEqualToString:sel_netpass]))
        {
        [self clearMessages];
        [self serverDisconnect];
        [self serverConnect];
        }
      }
    }
}

- (void)subscribeGroups
  {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *defaultsLG = [defaults stringForKey:@"locationGroups"];
  if ([defaultsLG length]>0)
    {
    NSEnumerator *enumerator = [[defaultsLG componentsSeparatedByString:@" "] objectEnumerator];
    id target;    
    while ((target = [enumerator nextObject]))
      {
      NSArray *gp = [target componentsSeparatedByString:@","];
      NSString *groupname = [gp objectAtIndex:0];
      BOOL groupenabled = FALSE;
      if ([gp count]>=2) groupenabled = [[gp objectAtIndex:1] intValue];
      if (groupenabled)
        {
        char buf[1024];
        char output[1024];
        NSString* cmd = [NSString stringWithFormat:@"MP-0 G%@",groupname];
        strcpy(buf, [cmd UTF8String]);
        int len = (int)strlen(buf);
        RC4_crypt(&txCrypto, (uint8_t*)buf, (uint8_t*)buf, len);
        base64encode((uint8_t*)buf, len, (uint8_t*)output);
        NSString *pushStr = [NSString stringWithFormat:@"%s\r\n",output];
        NSData *pushData = [pushStr dataUsingEncoding:NSUTF8StringEncoding];
        [asyncSocket writeData:pushData withTimeout:-1 tag:0];
        }
      }
    }
  }

- (void)didStartNetworking
{
  networkingCount = 1;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didStopNetworking
{
  networkingCount = 0;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)serverConnect
{
  unsigned char digest[MD5_SIZE];
  unsigned char edigest[MD5_SIZE*2];
  
  Reachability* internetReach = [Reachability reachabilityForInternetConnection];
  NetworkStatus netStatus = [internetReach currentReachabilityStatus];
  if (netStatus == NotReachable)
    {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Connection Error"
                                 message:@"You have a connection failure. OVMS requires a wi-fi or cell network to get an Internet connection."
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okButton = [UIAlertAction
                               actionWithTitle:@"Ok"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle your yes please button action here
                               }];
    [alert addAction:okButton];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    return;
    }
  
  if (asyncSocket == NULL)
    {
    self.car_lastupdated = 0;
    self.car_connected = 0;
    self.car_online = NO;
    self.car_paranoid = FALSE;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* ovmsServer = [defaults stringForKey:@"ovmsServer"];
    BOOL ovmsShareColour = [defaults integerForKey:@"ovmsShareColour"];
    NSString* ovmsSelImagePath = [defaults stringForKey:@"selImagePath"];
    int ovmsPort = (int)[defaults integerForKey:@"ovmsPort"];
    const char *password = [sel_netpass UTF8String];
    const char *vehicleid = [sel_car UTF8String];
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    NSError *error = nil;
    if (![asyncSocket connectToHost:ovmsServer onPort:ovmsPort error:&error])
      {
      // Croak on the error
      return;
      
      }
    [asyncSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
    
    // Make a (semi-)random client token
    sranddev();
    for (int k=0;k<TOKEN_SIZE;k++)
      {
      token[k] = cb64[rand()%64];
      }
    token[TOKEN_SIZE] = 0;
    
    hmac_md5(token, TOKEN_SIZE, (const uint8_t*)password, (int)strlen(password), digest);
    base64encode(digest, MD5_SIZE, edigest);
    NSString *welcomeStr;
    if (ovmsShareColour)
      welcomeStr = [NSString stringWithFormat:@"MP-A 0 %s %s %s %@\r\n",token,edigest,vehicleid,ovmsSelImagePath];
    else
      welcomeStr = [NSString stringWithFormat:@"MP-A 0 %s %s %s\r\n",token,edigest,vehicleid];
    NSData *welcomeData = [welcomeStr dataUsingEncoding:NSUTF8StringEncoding];
    [asyncSocket writeData:welcomeData withTimeout:-1 tag:0];    
    [self didStartNetworking];
    }
  }

- (void)serverDisconnect
{
  if (asyncSocket != NULL)
    {
    self.car_lastupdated = 0;
    self.car_connected = 0;
    self.car_online = NO;
    [self serverClearState];
    [asyncSocket setDelegate:nil delegateQueue:NULL];
    [asyncSocket disconnect];
    [self didStopNetworking];
    asyncSocket = NULL;
    }
}

- (void)serverClearState
{
  //TODO
  car_location.latitude = 0;
  car_location.longitude = 0;
  car_direction = 0;
  car_altitude = 0;
  car_gpslock = 0;
  car_stale_gps = -1;
  
  car_soc = 0;
  car_units = @"";
  car_linevoltage = 0;
  car_chargecurrent = 0;
  car_chargestate = @"";
  car_chargemode = @"";
  car_idealrange = 0;
  car_estimatedrange = 0;
  car_chargelimit = 0;
  car_chargeduration = 0;
  car_chargeb4 = 0;
  car_chargekwh = 0;
  car_chargesubstate = 0;
  car_chargestateN = 0;
  car_chargemodeN = 0;
  car_chargetype = 0;
    
  car_minutestofull = -1;
  car_minutestorangelimit = -1;
  car_minutestosoclimit = -1;
  car_rangelimit = -1;
  car_soclimit = -1;
    
  car_doors1 = 0;
  car_doors2 = 0;
  car_doors3 = 0;
  car_stale_pemtemps = -1;
  car_stale_ambienttemps = -1;
  car_lockstate = 0;
  car_vin = @"";
  car_firmware = @"";
  server_firmware = @"";
  car_write_enabled = 0;
  car_type = @"";
  car_cac = @"";

  car_gsmlevel = 0;
  car_tpem = 0;
  car_tmotor = 0;
  car_tbattery = 0;
  car_ambient_temp = -127;
  car_trip = 0;
  car_odometer = 0;
  car_speed = 0;
  car_tpms_fr_pressure = 0;
  car_tpms_fr_temp = 0;
  car_tpms_rr_pressure = 0;
  car_tpms_rr_temp = 0;
  car_tpms_fl_pressure = 0;
  car_tpms_fl_temp = 0;
  car_tpms_rl_pressure = 0;
  car_tpms_rl_temp = 0;
  car_stale_tpms = -1;
  
  car_ambient_weather = -1;

  car_idealrange_s = @"";
  car_estimatedrange_s = @"";
  car_tpem_s = @"";
  car_tmotor_s = @"";
  car_tbattery_s = @"";
  car_trip_s = @"";
  car_odometer_s = @"";
  car_speed_s = @"";
  car_ambient_temp_s = @"";
  car_tpms_fr_pressure_s = @"";
  car_tpms_rr_pressure_s = @"";
  car_tpms_fl_pressure_s = @"";
  car_tpms_rl_pressure_s = @"";
  car_tpms_fr_temp_s = @"";
  car_tpms_rr_temp_s = @"";
  car_tpms_fl_temp_s = @"";
  car_tpms_rl_temp_s = @"";

  [self notifyUpdates];

  if (tim)
    {
    [tim invalidate];
    tim = NULL;
    }
}

- (void)handleCommand:(char)code command:(NSString*)cmd
  {  
  if (code == 'E')
    {
    // We have a paranoid mode message
    if (cmd == nil) return;
    const char *pm = [cmd UTF8String];
    if (pm == nil) return;
    self.car_paranoid = TRUE;
    if (*pm == 'T')
      {
      // Set the paranoid token
      pmToken =  [[NSString alloc] initWithCString:pm+1 encoding:NSUTF8StringEncoding];
      const char *password = [sel_userpass UTF8String];
      hmac_md5((uint8_t*)pm+1, (int)strlen(pm+1), (const uint8_t*)password, (int)strlen(password), (uint8_t*)&pmDigest);
      return;
      }
    else if (*pm == 'M')
      {
      // Decrypt the paranoid message
      char buf[[cmd length]*2 + 16];
      int len;

      code = pm[1];
      len = base64decode((uint8_t*)pm+2, (uint8_t*)buf);
      RC4_setup(&pmCrypto, (uint8_t*)&pmDigest, MD5_SIZE);
      for (int k=0;k<1024;k++)
        {
        uint8_t x = 0;
        RC4_crypt(&pmCrypto, &x, &x, 1);
        }
      RC4_crypt(&pmCrypto, (uint8_t*)buf, (uint8_t*)buf, len);
      cmd = [[NSString alloc] initWithCString:buf encoding:NSUTF8StringEncoding];
      }
    }

  switch(code)
    {
    case 'c': // Command response
      {
      [self commandResponse:cmd];
      }
      break;
    case 'Z': // Number of connected cars
      {
      self.car_connected = [cmd intValue];
      if (self.car_connected==0) self.car_online=NO;
      }
      break;
    case 'P': // PUSH notification
      {
      NSString* message = [cmd substringFromIndex:1];
      [JHNotificationManager notificationWithMessage:message];
      [self addMessage:message incoming:YES];
      }
      break;
    case 'S': // STATUS
      {
      NSArray *lparts = [cmd componentsSeparatedByString:@","];
      if ([lparts count]>=8)
        {
        car_soc = [[lparts objectAtIndex:0] intValue];
        car_units = [lparts objectAtIndex:1];
        car_linevoltage = [[lparts objectAtIndex:2] intValue];
        car_chargecurrent = [[lparts objectAtIndex:3] intValue];
        car_chargestate = [lparts objectAtIndex:4];
        car_chargemode = [lparts objectAtIndex:5];
        car_idealrange = [[lparts objectAtIndex:6] intValue];
        car_estimatedrange = [[lparts objectAtIndex:7] intValue];
        car_idealrange_s = [self convertDistanceUnits:car_idealrange];
        car_estimatedrange_s = [self convertDistanceUnits:car_estimatedrange];
        }
      if ([lparts count]>=15)
        {
        car_chargelimit = [[lparts objectAtIndex:8] intValue];
        car_chargeduration = [[lparts objectAtIndex:9] intValue];
        car_chargeb4 = [[lparts objectAtIndex:10] intValue];
        car_chargekwh = [[lparts objectAtIndex:11] intValue] / 10;
        car_chargesubstate = [[lparts objectAtIndex:12] intValue];
        car_chargestateN = [[lparts objectAtIndex:13] intValue];
        car_chargemodeN = [[lparts objectAtIndex:14] intValue];
        }
      if ([lparts count]>=19)
        {
        car_cac = [lparts objectAtIndex:18];
        }
      if ([lparts count]>=23)
        {
        car_minutestofull = [[lparts objectAtIndex:19] intValue];
        car_rangelimit = [[lparts objectAtIndex:21] intValue];
        car_soclimit = [[lparts objectAtIndex:22] intValue];
        }
      if([lparts count]>=31)
        {
        car_minutestorangelimit = [[lparts objectAtIndex:27] intValue];
        car_minutestosoclimit = [[lparts objectAtIndex:28] intValue];
        car_chargetype = [[lparts objectAtIndex:30] intValue];
        }
      }
      break;
    case 'T': // TIME
      {
      int tick = [cmd intValue];
      if ((car_connected>0)&&(tick==0)) car_online=YES;
      self.car_lastupdated = time(0) - tick;
      }
      break;
    case 'L': // LOCATION
      {
      NSArray *lparts = [cmd componentsSeparatedByString:@","];
      if ([lparts count]>=2)
        {
        car_location.latitude = [[lparts objectAtIndex:0] doubleValue];
        car_location.longitude = [[lparts objectAtIndex:1] doubleValue];
        }
      if ([lparts count]>=6)
        {
        car_direction = [[lparts objectAtIndex:2] intValue];
        car_altitude = [[lparts objectAtIndex:3] intValue];
        car_gpslock = [[lparts objectAtIndex:4] intValue];
        car_stale_gps = [[lparts objectAtIndex:5] intValue];
        }
      if (car_ambient_weather < 0)
        {
        // We may need to launch an async request to get the weather at the car's location
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *defaultsWC = [defaults stringForKey:@"cacheWeatherCar"];
        NSString *defaultsWP = [defaults stringForKey:@"cacheWeatherTemp"];
        NSString *defaultsWT = [defaults stringForKey:@"cacheWeatherTimeout"];
        time_t timeout = 0;
        if ([defaultsWT length]>0)
          timeout = [defaultsWT intValue];
        if (([defaultsWC length]==0)||
            (![defaultsWC isEqualToString:sel_car])||
            (time(0)>timeout))
          {
          // There is no valid cached value, so we need to get it
          car_ambient_weather = 0; // "0" means request pending...
          NSString *reqString = [NSString stringWithFormat:
                                 @"http://api.worldweatheronline.com/free/v1/weather.ashx?q=%0.3f,%0.3f&format=csv&num_of_days=2&key=vmsb5smatuw7t43kqvy77fza",
                                 car_location.latitude, car_location.longitude];
          NSURL *theURL =  [[NSURL alloc]initWithString:reqString];
          NSURLRequest *theRequest=[NSURLRequest requestWithURL:theURL
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                timeoutInterval:60.0];
          [NSURLConnection connectionWithRequest:theRequest delegate:self];
          }
        else
          {
          car_ambient_weather = [defaultsWP intValue];
          }
        }
      }
      break;
    case 'F': // CAR FIRMWARE
      {
      NSArray *lparts = [cmd componentsSeparatedByString:@","];
      if ([lparts count]>=3)
        {
        car_firmware = [lparts objectAtIndex:0];
        car_vin = [lparts objectAtIndex:1];
        car_gsmlevel = [[lparts objectAtIndex:2] intValue];
        }
      if ([lparts count]>=5)
        {
        car_write_enabled = [[lparts objectAtIndex:3] intValue];
        car_type = [lparts objectAtIndex:4];
        }
      }
      break;
    case 'f': // SERVER FIRMWARE
      {
      NSArray *lparts = [cmd componentsSeparatedByString:@","];
      if ([lparts count]>=1)
        {
        server_firmware = [lparts objectAtIndex:0];
        }
      }
      break;
    case 'g': // GROUP UPDATE
      {
      NSArray *lparts = [cmd componentsSeparatedByString:@","];
      [self notifyGroupUpdates:lparts];
      }
      break;
    case 'D': // CAR ENVIRONMENT
      {
      NSArray *lparts = [cmd componentsSeparatedByString:@","];
      if ([lparts count]>=9)
        {
        car_doors1 = [[lparts objectAtIndex:0] intValue];
        car_doors2 = [[lparts objectAtIndex:1] intValue];
        car_lockstate = [[lparts objectAtIndex:2] intValue];
        car_tpem = [[lparts objectAtIndex:3] intValue];
        car_tmotor = [[lparts objectAtIndex:4] intValue];
        car_tbattery = [[lparts objectAtIndex:5] intValue];
        car_trip = [[lparts objectAtIndex:6] intValue];
        car_odometer = [[lparts objectAtIndex:7] intValue] / 10;
        car_speed = [[lparts objectAtIndex:8] intValue];
        car_tpem_s = [self convertTemperatureUnits:car_tpem];
        car_tmotor_s = [self convertTemperatureUnits:car_tmotor];
        car_tbattery_s = [self convertTemperatureUnits:car_tbattery];
        car_trip_s = [self convertDistanceUnits:car_trip];
        car_odometer_s = [self convertDistanceUnits:car_odometer];
        car_speed_s = [self convertSpeedUnits:car_speed];

        if ([lparts count] >= 10)
          car_parktime = [[lparts objectAtIndex:9] intValue];
        else
          car_parktime = 0;
        if ([lparts count] >= 11)
          car_ambient_temp = [[lparts objectAtIndex:10] intValue];
        else
          car_ambient_temp = -127;
        car_ambient_temp_s = [self convertTemperatureUnits:car_ambient_temp];

        if ([lparts count] >= 14)
          {
          car_doors3 = [[lparts objectAtIndex:11] intValue];
          car_stale_pemtemps = [[lparts objectAtIndex:12] intValue];
          car_stale_ambienttemps = [[lparts objectAtIndex:13] intValue];
          }
        else
          {
          car_stale_pemtemps = 1;
          car_stale_ambienttemps = 1;
          }
        if ([lparts count] >= 15)
          {
            car_aux_battery_voltage = [[lparts objectAtIndex:14] floatValue];
          }
        }
      }
      break;
    case 'W': // CAR TPMS
      {
      NSArray *lparts = [cmd componentsSeparatedByString:@","];
      if ([lparts count]>=8)
        {
        car_tpms_fr_pressure = [[lparts objectAtIndex:0] floatValue];
        car_tpms_fr_pressure_s = [self convertPressureUnits:car_tpms_fr_pressure];
        car_tpms_fr_temp = [[lparts objectAtIndex:1] intValue];
        car_tpms_fr_temp_s = [self convertTemperatureUnits:car_tpms_fr_temp];
        car_tpms_rr_pressure = [[lparts objectAtIndex:2] floatValue];
        car_tpms_rr_pressure_s = [self convertPressureUnits:car_tpms_rr_pressure];
        car_tpms_rr_temp = [[lparts objectAtIndex:3] intValue];
        car_tpms_rr_temp_s = [self convertTemperatureUnits:car_tpms_rr_temp];
        car_tpms_fl_pressure = [[lparts objectAtIndex:4] floatValue];
        car_tpms_fl_pressure_s = [self convertPressureUnits:car_tpms_fl_pressure];
        car_tpms_fl_temp = [[lparts objectAtIndex:5] intValue];
        car_tpms_fl_temp_s = [self convertTemperatureUnits:car_tpms_fl_temp];
        car_tpms_rl_pressure = [[lparts objectAtIndex:6] floatValue];
        car_tpms_rl_pressure_s = [self convertPressureUnits:car_tpms_rl_pressure];
        car_tpms_rl_temp = [[lparts objectAtIndex:7] intValue];
        car_tpms_rl_temp_s = [self convertTemperatureUnits:car_tpms_rl_temp];
        }
      if ([lparts count]>=9)
        {
        car_stale_tpms = [[lparts objectAtIndex:8] intValue];
        }
      else
        car_stale_tpms = 1;
      }
      break;
    }

  [self notifyUpdates];
  }

- (NSString*)convertDistanceUnits:(int)distance
  {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *defaultsD = [defaults stringForKey:@"ovmsDistances"];

  if ([self.car_units length] == 0) return @"";

  if (([defaultsD isEqualToString:@"-"])||([defaultsD isEqualToString:self.car_units]))
    {
    // Go with the car preference
    NSString *fu;
    if ([self.car_units isEqualToString:@"K"])
      fu = @"km";
    else
      fu = @"m";
    return [NSString stringWithFormat:@"%d%@",distance,fu];
    }
  else if ([defaultsD isEqualToString:@"K"])
    {
    // Car is in miles, but we want kilometers
    return [NSString stringWithFormat:@"%d%s",(distance*8)/5,"km"];
    }
  else
    {
    // Car is in kilometers, but we want miles
    return [NSString stringWithFormat:@"%d%s",(distance*5)/8,"m"];
    }
  }

- (NSString*)convertSpeedUnits:(int)speed
  {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *defaultsD = [defaults stringForKey:@"ovmsDistances"];
  
  if ([self.car_units length] == 0) return @"";

  if (([defaultsD isEqualToString:@"-"])||([defaultsD isEqualToString:self.car_units]))
    {
    // Go with the car preference
    NSString *fu;
    if ([self.car_units isEqualToString:@"K"])
      fu = @"kph";
    else
      fu = @"mph";
    return [NSString stringWithFormat:@"%d%@",speed,fu];
    }
  else if ([defaultsD isEqualToString:@"K"])
    {
    // Car is in miles, but we want kilometers
    return [NSString stringWithFormat:@"%d%s",(speed*8)/5,"kph"];
    }
  else
    {
    // Car is in kilometers, but we want miles
    return [NSString stringWithFormat:@"%d%s",(speed*5)/8,"mph"];
    }
  }

- (NSString*)convertTemperatureUnits:(int)temp
  {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *defaultsT = [defaults stringForKey:@"ovmsTemperatures"];
  
  if ([self.car_units length] == 0) return @"";
  
  if (([defaultsT isEqualToString:@"-"])||([defaultsT isEqualToString:self.car_units]))
    {
    // Go with the car preference
    if ([self.car_units isEqualToString:@"K"])
      return [NSString stringWithFormat:@"%d°C",temp];
    else
      return [NSString stringWithFormat:@"%d°F",9*temp/5+32];
    }
  else if ([defaultsT isEqualToString:@"K"])
    {
    // Car is in fahrenheit, but we want celcius
    // N.B. Already in celcius, so no conversion necessary
    return [NSString stringWithFormat:@"%d°C",temp];
    }
  else
    {
    // Car is in celcius, but we want fahrenheit
    return [NSString stringWithFormat:@"%d°F",9*temp/5+32];
    }
  }

- (NSString*)convertPressureUnits:(float)pressure
{
NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
NSString *defaultsD = [defaults stringForKey:@"ovmsPressures"];

if (([defaultsD isEqualToString:@"-"])||([defaultsD isEqualToString:@"PSI"]))
  {
  // PSI
  return [NSString stringWithFormat:@"%0.1f%s",pressure," PSI"];
  }
else if ([defaultsD isEqualToString:@"kPa"])
  {
  // kPa
  return [NSString stringWithFormat:@"%0.0f%s",(pressure * 6.89476)," kPa"];
  }
else
  {
  // BAR
  return [NSString stringWithFormat:@"%0.1f%s",(pressure * 0.0689476)," BAR"];
  }
}

- (void)registerForUpdate:(id)target
  {
  if (update_delegates == nil)
    update_delegates = [[NSMutableSet alloc] init];
  
  [update_delegates addObject:target];
  }

- (void)deregisterFromUpdate:(id)target
  {
  [update_delegates removeObject:target];
  }

- (void)notifyUpdates
  {
  if (update_delegates == nil) return;
  
  NSEnumerator *enumerator = [update_delegates objectEnumerator];
  id target;
  
  while ((target = [enumerator nextObject]))
    {
    if (([target conformsToProtocol:@protocol(ovmsUpdateDelegate)])&&
        ([target respondsToSelector:@selector(update)]))
      [target update];
    }
  }

- (void)notifyGroupUpdates:(NSArray*)result
  {
  if (update_delegates == nil) return;
  
  NSEnumerator *enumerator = [update_delegates objectEnumerator];
  id target;
  
  while ((target = [enumerator nextObject]))
    {
    if (([target conformsToProtocol:@protocol(ovmsUpdateDelegate)])&&
        ([target respondsToSelector:@selector(groupUpdate:)]))
      [target groupUpdate:result];
    }
  }

- (void)clearMessages
  {
  if (sel_messages == nil)
    sel_messages = [[NSMutableArray alloc] init];
  [sel_messages removeAllObjects];

  NSEnumerator *enumerator = [update_delegates objectEnumerator];
  id target;
      
  while ((target = [enumerator nextObject]))
    {
    if (([target conformsToProtocol:@protocol(ovmsUpdateDelegate)])&&
        ([target respondsToSelector:@selector(clearMessages)]))
      [target clearMessages];
    }
  }

- (void)addMessage:(OvmsMessage*)message
  {
  if (sel_messages == nil)
    sel_messages = [[NSMutableArray alloc] init];

  [sel_messages addObject:message];

  NSEnumerator *enumerator = [update_delegates objectEnumerator];
  id target;
    
  while ((target = [enumerator nextObject]))
    {
    if (([target conformsToProtocol:@protocol(ovmsUpdateDelegate)])&&
        ([target respondsToSelector:@selector(addMessage:)]))
      [target addMessage:message];
    }
  }

- (void)addMessage:(NSString*)text incoming:(BOOL)incoming
  {
  OvmsMessage *message = [OvmsMessage alloc];
  message.text = text;
  if (incoming)
    {
    message.senderId = @"car";
    message.outgoing = NO;
    }
  else
    {
    message.senderId = @"app";
    message.outgoing = YES;
    }
  message.date = [NSDate date];
  message.deliveryStatus = OvmsMessageDeliveryStatusDelivering;
  [self addMessage:message];
  }

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
  {
  NSString *reply = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSArray *wla = [reply componentsSeparatedByString:@"\n"];
  for (NSString *wl in wla)
    {
    if ((car_ambient_weather<=0)&&
        ([wl length] > 0)&&
        ([wl characterAtIndex:0] != '#'))
      {
      // We can assume this is the first line of the good response
      NSArray *rt = [wl componentsSeparatedByString:@","];
      if ([rt count]>2)
        {
        car_ambient_weather = [[rt objectAtIndex:2] intValue];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:sel_car forKey:@"cacheWeatherCar"];
        [defaults setObject:[rt objectAtIndex:2] forKey:@"cacheWeatherTemp"];
        [defaults setObject:[NSString stringWithFormat:@"%ld",time(0)+(15*60)] forKey:@"cacheWeatherTimeout"];
        [defaults synchronize];
        }
      }
    }
  [self notifyUpdates];
  }

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
  {
  car_ambient_weather = -2;
  [self notifyUpdates];
  }


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
  // Here we do the stuff after the connection to the host
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
  const char *password = [sel_netpass UTF8String];
  unsigned char digest[MD5_SIZE];
  unsigned char edigest[(MD5_SIZE*2)+2];

  [self didStopNetworking];
  
  NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if (tag==0)
    { // Welcome message
    NSArray *rparts = [response componentsSeparatedByString:@" "];
    if ([rparts count]<4)
      {
      [self serverDisconnect];
      NSLog(@"Whoops, server welcome message too short: %@", response);
      timreconnect = [NSTimer scheduledTimerWithTimeInterval: 10.0
                                             target: self
                                           selector: @selector(onTickReconnect:)
                                           userInfo: nil
                                            repeats: NO];
      return; // Invalid server response
      }
    NSString *stoken = [rparts objectAtIndex:2];
    NSString *etoken = [rparts objectAtIndex:3];
    const char *cstoken = [stoken UTF8String];
      if ((stoken==NULL)||(etoken==NULL))
      {
      [self serverDisconnect];
      NSLog(@"Whoops, server had wrong token: %@", response);
      timreconnect = [NSTimer scheduledTimerWithTimeInterval: 10.0
                                                      target: self
                                                    selector: @selector(onTickReconnect:)
                                                    userInfo: nil
                                                     repeats: NO];
      return;
      }
    // Check for token-replay attack
    if (strcmp((char*)token,cstoken)==0)
      {
      [self serverDisconnect];
      NSLog(@"Whoops, token replay attack: %@", response);
      timreconnect = [NSTimer scheduledTimerWithTimeInterval: 10.0
                                                      target: self
                                                    selector: @selector(onTickReconnect:)
                                                    userInfo: nil
                                                     repeats: NO];
      return; // Server is using our token!
      }
      
    // Validate server token
    hmac_md5((const uint8_t*)cstoken, (int)strlen(cstoken), (const uint8_t*)password, (int)strlen(password), digest);
    base64encode(digest, MD5_SIZE, edigest);
    if (strncmp([etoken UTF8String],(const char*)edigest,strlen((const char*)edigest))!=0)
      {
      [self serverDisconnect];
      NSLog(@"Whoops, server token is invalid: %@", response);
      timreconnect = [NSTimer scheduledTimerWithTimeInterval: 10.0
                                                      target: self
                                                    selector: @selector(onTickReconnect:)
                                                    userInfo: nil
                                                     repeats: NO];
      return; // Invalid server digest
      }
      
    // Ok, at this point, our token is ok
    int keylen = (int)(strlen((const char*)token)+strlen(cstoken)+1);
    char key[keylen];
    strcpy(key,cstoken);
    strcat(key,(const char*)token);
    hmac_md5((const uint8_t*)key, (int)strlen(key), (const uint8_t*)password, (int)strlen(password), digest);
      
    // Setup, and prime the rx and tx cryptos
    RC4_setup(&rxCrypto, digest, MD5_SIZE);
    for (int k=0;k<1024;k++)
      {
      uint8_t x = 0;
      RC4_crypt(&rxCrypto, &x, &x, 1);
      }
    RC4_setup(&txCrypto, digest, MD5_SIZE);
    for (int k=0;k<1024;k++)
      {
      uint8_t x = 0;
      RC4_crypt(&txCrypto, &x, &x, 1);
      }
    [asyncSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:1];

    tim = [NSTimer scheduledTimerWithTimeInterval: 180.0
                                           target: self
                                         selector: @selector(onTick:)
                                         userInfo: nil
                                          repeats: YES];

    if ([apns_devicetoken length] > 0)
      {
      // Subscribe to push notifications
      char buf[1024];
      char output[1024];
      NSString* pns = [NSString stringWithFormat:@"MP-0 p%@,apns,%@,%@,%@,%@",
                       apns_deviceid, apns_pushkeytype, sel_car, sel_netpass, apns_devicetoken];
      strcpy(buf, [pns UTF8String]);
      int len = (int)strlen(buf);
      RC4_crypt(&txCrypto, (uint8_t*)buf, (uint8_t*)buf, len);
      base64encode((uint8_t*)buf, len, (uint8_t*)output);
      NSString *pushStr = [NSString stringWithFormat:@"%s\r\n",output];
      NSData *pushData = [pushStr dataUsingEncoding:NSUTF8StringEncoding];
      [asyncSocket writeData:pushData withTimeout:-1 tag:0];    
      }
    
    [self subscribeGroups];
    }
  else if (tag==1)
    { // Normal encrypted data packet
    char buf[[response length]*2 + 16];
    int len = base64decode((uint8_t*)[response UTF8String], (uint8_t*)buf);
    RC4_crypt(&rxCrypto, (uint8_t*)buf, (uint8_t*)buf, len);
      if ((buf[0]=='M')&&(buf[1]=='P')&&(buf[2]=='-')&&(buf[3]=='0'))
        {
        NSString *cmd = [[NSString alloc] initWithCString:buf+6 encoding:NSUTF8StringEncoding];
        [self handleCommand:buf[5] command:cmd];
        }
    [asyncSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:1];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
  [[ovmsAppDelegate myRef] serverClearState];
}

-(void)onTick:(NSTimer *)timer
  {
  char buf[1024];
  char output[1024];
  strcpy(buf, "MP-0 A");
  int len = (int)strlen(buf);
  RC4_crypt(&txCrypto, (uint8_t*)buf, (uint8_t*)buf, len);
  base64encode((uint8_t*)buf, len, (uint8_t*)output);
  NSString *pushStr = [NSString stringWithFormat:@"%s\r\n",output];
  NSData *pushData = [pushStr dataUsingEncoding:NSUTF8StringEncoding];
  [asyncSocket writeData:pushData withTimeout:-1 tag:0];
  }

- (void)onTickReconnect:(NSTimer *)timer
  {
  if (asyncSocket != nil) return; // Return if already connected

  [self serverConnect];
  }

- (BOOL)commandIsFree
{
  return (command_delegate==nil);
}

- (void)commandRegister:(NSString*)command callback:(id)cb
  {
  if (command_delegate != nil) return; // Cancel any pending delegate
  
  command_delegate = cb;
  
  [self commandIssue:command];
  }

- (void)commandIssue:(NSString*)command
  {
  char buf[1024];
  char output[1024];
  NSString* cmd = [NSString stringWithFormat:@"MP-0 C%@",command];
  strcpy(buf, [cmd UTF8String]);
  int len = (int)strlen(buf);
  RC4_crypt(&txCrypto, (uint8_t*)buf, (uint8_t*)buf, len);
  base64encode((uint8_t*)buf, len, (uint8_t*)output);
  NSString *pushStr = [NSString stringWithFormat:@"%s\r\n",output];
  NSData *pushData = [pushStr dataUsingEncoding:NSUTF8StringEncoding];
  [asyncSocket writeData:pushData withTimeout:-1 tag:0];
  [self didStartNetworking];
  }

- (void)commandResponse:(NSString*)response
  {
  NSArray *result = [response componentsSeparatedByString:@","];
  if ((command_delegate != nil)&&([command_delegate conformsToProtocol:@protocol(ovmsCommandDelegate)]))
    {
    [command_delegate commandResult:result];
    }

  if ([result count]>1)
    {
    int command = [[result objectAtIndex:0] intValue];
    int rcode = [[result objectAtIndex:1] intValue];
    switch (rcode)
      {
      case 0: // ok
        switch (command)
          {
          case 1:
          case 3:
          case 30:
            if ((command_delegate != nil)&&([command_delegate conformsToProtocol:@protocol(ovmsCommandDelegate)]))
              {
              }
            else
              [self didStopNetworking];
            break;
          case 5:
            [JHNotificationManager notificationWithMessage:@"Car Module Reboot..."];
            [self didStopNetworking];
            break;
          case 7:
            {
            NSString* msgtext = [response substringFromIndex:4];
            [self addMessage:msgtext incoming:YES];
            }
            break;
          case 10:
            [JHNotificationManager notificationWithMessage:@"Set Charge Mode"];
            [self didStopNetworking];
            break;
          case 11:
            [JHNotificationManager notificationWithMessage:@"Started Charge"];
            [self didStopNetworking];
            break;
          case 12:
            [JHNotificationManager notificationWithMessage:@"Stopped Charge"];
            [self didStopNetworking];
            break;
          case 15:
            [JHNotificationManager notificationWithMessage:@"Set Charge Current"];
            [self didStopNetworking];
            break;
          case 18:
            [JHNotificationManager notificationWithMessage:@"Car woken up"];
            [self didStopNetworking];
            break;
          case 19:
            [JHNotificationManager notificationWithMessage:@"Temperature subsystem woken up"];
            [self didStopNetworking];
            break;
          case 20:
            [JHNotificationManager notificationWithMessage:@"Car Locked"];
            [self didStopNetworking];
            break;
          case 21:
            [JHNotificationManager notificationWithMessage:@"Valet Mode Activated"];
            [self didStopNetworking];
            break;
          case 22:
            [JHNotificationManager notificationWithMessage:@"Car Unlocked"];
            [self didStopNetworking];
            break;
          case 23:
            [JHNotificationManager notificationWithMessage:@"Valet Mode Deactivated"];
            [self didStopNetworking];
            break;
          case 24:
            [JHNotificationManager notificationWithMessage:@"Homelink Command Issued"];
            [self didStopNetworking];
            break;
          case 41:
            [JHNotificationManager notificationWithMessage:@"MMI/USSD Code Sent"];
            [self didStopNetworking];
            break;
          default:
            [self didStopNetworking];
          }
        break;
      case 1: // failed
        if ([result count]>=3)
          {
          [JHNotificationManager
           notificationWithMessage:
           [NSString stringWithFormat:@"Failed: %@",[result objectAtIndex:2]]];
          }
        else
          {
          [JHNotificationManager notificationWithMessage:@"Failed"];
          }
        [self didStopNetworking];
        break;
      case 2: // unsupported
        [JHNotificationManager notificationWithMessage:@"Unsupported operation"];
        [self didStopNetworking];
        break;
      case 3: // unimplemented
        [JHNotificationManager notificationWithMessage:@"Unimplemented operation"];
        [self didStopNetworking];
        break;
      default:
        [JHNotificationManager
         notificationWithMessage:
         [NSString stringWithFormat:@"Error: %@",[result objectAtIndex:2]]];
        [self didStopNetworking];
        break;
      }
    }
  else
    [self didStopNetworking];
  }

- (void)commandCancel
  {
  command_delegate = nil;
  [self didStopNetworking];
  }

- (void)commandDoRequestFeatureList
  {
  [self commandIssue:@"1"];
  }

- (void)commandDoSetFeature:(int)feature value:(NSString*)value
  {
  [self commandIssue:[NSString stringWithFormat:@"2,%d,%@",feature,value]];
  }

- (void)commandDoRequestParameterList
  {
  [self commandIssue:@"3"];
  }

- (void)commandDoSetParameter:(int)param value:(NSString*)value
  {
  [self commandIssue:[NSString stringWithFormat:@"4,%d,%@",param,value]];
  }

- (void)commandDoReboot
  {
  [JHNotificationManager notificationWithMessage:@"Rebooting Car Module..."];
  [self commandIssue:@"5"];
  }

- (void)commandDoCommand:(NSString*)command
  {
  [self commandIssue:[NSString stringWithFormat:@"7,%@",command]];
  }

- (void)commandDoSetChargeMode:(int)mode
  {
  [JHNotificationManager notificationWithMessage:@"Setting Charge Mode..."];
  [self commandIssue:[NSString stringWithFormat:@"10,%d",mode]];
  }

- (void)commandDoStartCharge
  {
  [JHNotificationManager notificationWithMessage:@"Starting Charge..."];
  [self commandIssue:@"11"];
  self.car_linevoltage = 0;
  self.car_chargecurrent = 0;
  self.car_chargestate = @"starting";
  self.car_chargestateN = 0x101;
  [self notifyUpdates];
  }

- (void)commandDoStopCharge
  {
  [JHNotificationManager notificationWithMessage:@"Stopping Charge..."];
  [self commandIssue:@"12"];
  self.car_linevoltage = 0;
  self.car_chargecurrent = 0;
  self.car_chargestate = @"stopping";
  self.car_chargestateN = 0x115;
  [self notifyUpdates];
  }

- (void)commandDoSetChargeCurrent:(int)current
  {
  [JHNotificationManager notificationWithMessage:@"Setting Charge Current..."];
  [self commandIssue:[NSString stringWithFormat:@"15,%d",current]];
  }

- (void)commandDoSetChargeModecurrent:(int)mode current:(int)current
  {
  [JHNotificationManager notificationWithMessage:@"Setting Charge Mode and Current..."];
  [self commandIssue:[NSString stringWithFormat:@"16,%d,%d",mode,current]];
  }

- (void)commandDoWakeupCar
  {
  [JHNotificationManager notificationWithMessage:@"Waking up Car..."];
  [self commandIssue:@"18"];
  }

- (void)commandDoWakeupTempSubsystem
  {
  [JHNotificationManager notificationWithMessage:@"Waking up Temperature Subsystem..."];
  [self commandIssue:@"19"];
  }

- (void)commandDoLockCar:(NSString*)pin
  {
  [self commandIssue:[NSString stringWithFormat:@"20,%@",pin]];
  }

- (void)commandDoActivateValet:(NSString*)pin
  {
  [self commandIssue:[NSString stringWithFormat:@"21,%@",pin]];
  }

- (void)commandDoUnlockCar:(NSString*)pin
  {
  [self commandIssue:[NSString stringWithFormat:@"22,%@",pin]];
  }

- (void)commandDoDeactivateValet:(NSString*)pin
  {
  [self commandIssue:[NSString stringWithFormat:@"23,%@",pin]];
  }

- (void)commandDoUSSD:(NSString*)ussd
  {
  [self commandIssue:[NSString stringWithFormat:@"41,%@",ussd]];
  }

- (void)commandDoRequestGPRSData
  {
  [self commandIssue:@"30"];
  }

- (void)commandDoHomelink:(int)button
  {
  [JHNotificationManager notificationWithMessage:@"Issuing Homelink Command..."];
  [self commandIssue:[NSString stringWithFormat:@"24,%d",button]];
  }

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
  if (__managedObjectContext != nil)
    {
    return __managedObjectContext;
    }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator != nil)
    {
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
  return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
  if (__managedObjectModel != nil)
    {
    return __managedObjectModel;
    }
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
  __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
  if (__persistentStoreCoordinator != nil)
    {
    return __persistentStoreCoordinator;
    }
  
  NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ovmsmodel.sqlite"];
  
  NSError *error = nil;
  __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
//  if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]){
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
    }    
  
  return __persistentStoreCoordinator;
}

+ (BOOL)doesSystemVersionMeetRequirement:(NSString *)minRequirement {
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    
    if ([currSysVer compare:minRequirement options:NSNumericSearch] != NSOrderedAscending) {
        return YES;
    }else{
        return NO;
    }
}

+ (void)routeFrom:(CLLocationCoordinate2D)from To:(CLLocationCoordinate2D)to {
    NSMutableString *mapURL;
    if ([ovmsAppDelegate doesSystemVersionMeetRequirement:@"6.0"]) {
        mapURL = [NSMutableString stringWithString:@"http://maps.apple.com/"];
    } else {
        mapURL = [NSMutableString stringWithString:@"http://maps.google.com/maps"];
    }
    
    [mapURL appendFormat:@"?saddr=%1.6f,%1.6f", from.latitude, from.longitude];
    [mapURL appendFormat:@"&daddr=%1.6f,%1.6f", to.latitude, to.longitude];
    
    NSLog(@"route: %@", mapURL);
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[mapURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}


@end
