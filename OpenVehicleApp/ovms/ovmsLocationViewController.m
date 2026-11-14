//
//  ovmsLocationViewController.m
//  ovms
//
//  Created by Mark Webb-Johnson on 16/11/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import "ovmsLocationViewController.h"
#import "OCMInformationController.h"
#import <TargetConditionals.h>
#import <math.h>

#define IDENTIFIER_CLUSTER @"cluster"
#define IDENTIFIER_PIN @"pin"
#define IDENTIFIER_OVMS @"OVMS"

@implementation ovmsLocationViewController

@synthesize myMapView;
@synthesize m_car_location;
@synthesize m_groupcar_locations;
@synthesize m_lastregion;

#pragma mark - View lifecycle
- (void)viewDidLoad{
    [super viewDidLoad];
    self.isLoadAll = NO;
    self.isUseRange = YES;
    self.vehicleTrail = [NSMutableArray array];
    [self restoreVehicleTrail];
    [self setupModernMapOverlay];
}

- (void)setupModernMapOverlay {
    UIStackView *card = [[UIStackView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.axis = UILayoutConstraintAxisVertical;
    card.spacing = 3.0;
    card.layoutMargins = UIEdgeInsetsMake(12, 14, 12, 14);
    card.layoutMarginsRelativeArrangement = YES;
    card.backgroundColor = [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:0.92];
    card.layer.cornerRadius = 15.0;
    self.modernLocationTitle = [[UILabel alloc] init];
    self.modernLocationTitle.textColor = [UIColor whiteColor];
    self.modernLocationTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.modernLocationDetail = [[UILabel alloc] init];
    self.modernLocationDetail.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    self.modernLocationDetail.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.modernLocationDetail.numberOfLines = 2;
    [card addArrangedSubview:self.modernLocationTitle];
    [card addArrangedSubview:self.modernLocationDetail];
    [self.view addSubview:card];

    UIStackView *buttons = [[UIStackView alloc] init];
    buttons.translatesAutoresizingMaskIntoConstraints = NO;
    buttons.axis = UILayoutConstraintAxisHorizontal;
    buttons.spacing = 10.0;
    UIButton *recenter = [UIButton buttonWithType:UIButtonTypeSystem];
    [recenter setTitle:@"Recenter" forState:UIControlStateNormal];
    [recenter addTarget:self action:@selector(recenterVehicle) forControlEvents:UIControlEventTouchUpInside];
    UIButton *options = [UIButton buttonWithType:UIButtonTypeSystem];
    [options setTitle:@"Map options" forState:UIControlStateNormal];
    [options addTarget:self action:@selector(showMapOptions) forControlEvents:UIControlEventTouchUpInside];
    for (UIButton *button in @[recenter, options]) {
        button.backgroundColor = [UIColor colorWithRed:0.047 green:0.071 blue:0.118 alpha:0.92];
        button.layer.cornerRadius = 12.0;
        button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button.widthAnchor constraintGreaterThanOrEqualToConstant:105.0].active = YES;
        [button.heightAnchor constraintEqualToConstant:44.0].active = YES;
        [buttons addArrangedSubview:button];
    }
    [self.view addSubview:buttons];
    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12.0],
        [card.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:14.0],
        [card.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14.0],
        [buttons.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14.0],
        [buttons.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-14.0]
    ]];
}

- (void)recenterVehicle {
    self.isAutotrack = YES;
    if (self.m_car_location) [self.myMapView setCenterCoordinate:self.m_car_location.coordinate animated:YES];
}

- (void)showMapOptions { [self locationSnapped:nil]; }

- (void)dealloc {
    [self setMyMapView:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;

    self.m_car_location = nil;
    if (m_groupcar_locations == nil) m_groupcar_locations = [[NSMutableDictionary alloc] init];
    self.isAutotrack = YES;

    [[ovmsAppDelegate myRef] registerForUpdate:self];
    
    [self doupdate: true];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    [self.historyTimeout invalidate];
    if (self.historyLoading) { [[ovmsAppDelegate myRef] commandCancel]; self.historyLoading = NO; }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // As we are about to disappear, remove all the car location objects
    // Remove all existing annotations
    for (int k=0; k < [myMapView.annotations count]; k++) {
        if ([[myMapView.annotations objectAtIndex:k] isKindOfClass:[VehicleAnnotation class]]) {
            [myMapView removeAnnotation:[myMapView.annotations objectAtIndex:k]];
        }
    }
    self.m_car_location = nil;
    if (m_groupcar_locations != nil) {
        [m_groupcar_locations removeAllObjects];
        m_groupcar_locations = nil;
    }

    [[ovmsAppDelegate myRef] deregisterFromUpdate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
#if DEBUG && TARGET_OS_SIMULATOR
    if (self.screenshotScenarioHandled) return;
    NSString *scenario = [[[NSProcessInfo processInfo] environment] objectForKey:@"OVMS_SCREENSHOT_SCENARIO"];
    if ([scenario isEqualToString:@"map-options"]) {
        self.screenshotScenarioHandled = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [self showMapOptions]; });
    } else if ([scenario isEqualToString:@"map-history-loading"]) {
        self.screenshotScenarioHandled = YES;
        CLLocationCoordinate2D center=[ovmsAppDelegate myRef].car_location;
        if (!CLLocationCoordinate2DIsValid(center) || (center.latitude==0 && center.longitude==0)) center=CLLocationCoordinate2DMake(51.5074,-0.1278);
        [self.vehicleTrail removeAllObjects]; for(NSInteger i=0;i<18;i++) [self.vehicleTrail addObject:[NSValue valueWithMKCoordinate:CLLocationCoordinate2DMake(center.latitude-.012+i*.0007,center.longitude-.016+i*.0009+sin(i*.5)*.001)]];
        [self initOverlays]; self.modernLocationTitle.text=@"Loading trip history…"; self.modernLocationDetail.text=@"Receiving GPS record 64 of 180 from the vehicle server";
    }
#endif
}

- (void)settingsChanged:(NSNotification *)notification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger val = 11 - round([defaults floatForKey:@"ovmsMapBlocs"]);
    if (val < 1 || val > 10) val = 4;
    
    if (self.myMapView.blocks != val) {
        self.myMapView.blocks = val;
        [self performSelector:@selector(initAnnotations) withObject:nil afterDelay:0.3f];
        
        NSLog(@"Setup MAP view blocks: %ld", (long)val);
    }
}

- (IBAction)locationSnapped:(id)sender {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Map options" message:@"Choose what is shown around the vehicle." preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *tracking = self.isAutotrack ? @"Disable automatic tracking" : @"Enable automatic tracking";
    [sheet addAction:[UIAlertAction actionWithTitle:tracking style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.isAutotrack = !self.isAutotrack;
        if (self.isAutotrack) [self recenterVehicle];
    }]];
    NSString *filter = self.isFiltredChargingStation ? @"Show all connector types" : @"Filter compatible connectors";
    [sheet addAction:[UIAlertAction actionWithTitle:filter style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (![ovmsAppDelegate myRef].sel_connection_type_ids.length) {
            UIAlertController *warning = [UIAlertController alertControllerWithTitle:@"Connector types needed" message:@"Configure the vehicle's connector types in Settings before enabling this filter." preferredStyle:UIAlertControllerStyleAlert];
            [warning addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:warning animated:YES completion:nil];
        } else {
            self.isFiltredChargingStation = !self.isFiltredChargingStation;
            if (self.m_car_location) [self loadData:[ovmsAppDelegate myRef].car_location];
        }
    }]];
    NSString *range = self.isUseRange ? @"Show stations beyond range" : @"Only show stations in range";
    [sheet addAction:[UIAlertAction actionWithTitle:range style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.isUseRange = !self.isUseRange;
        if (self.m_car_location) [self loadData:[ovmsAppDelegate myRef].car_location];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Refresh trip history" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [self refreshVehicleHistory]; }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Clear recent vehicle trail" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.vehicleTrail removeAllObjects];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self vehicleTrailKey]];
        [self initOverlays];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - 60, 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (NSString *)vehicleTrailKey { return [NSString stringWithFormat:@"vehicleTrail.%@",[ovmsAppDelegate myRef].sel_car?:@"vehicle"]; }
- (void)restoreVehicleTrail
{
    NSArray *saved=[[NSUserDefaults standardUserDefaults] arrayForKey:[self vehicleTrailKey]];
    for(NSDictionary *point in saved){ CLLocationDegrees lat=[point[@"lat"] doubleValue],lon=[point[@"lon"] doubleValue]; CLLocationCoordinate2D coordinate=CLLocationCoordinate2DMake(lat,lon); if(CLLocationCoordinate2DIsValid(coordinate)) [self.vehicleTrail addObject:[NSValue valueWithMKCoordinate:coordinate]]; }
}
- (void)saveVehicleTrail
{
    NSMutableArray *saved=[NSMutableArray arrayWithCapacity:self.vehicleTrail.count]; for(NSValue *value in self.vehicleTrail){ CLLocationCoordinate2D point=value.MKCoordinateValue; [saved addObject:@{@"lat":@(point.latitude),@"lon":@(point.longitude)}]; } [[NSUserDefaults standardUserDefaults] setObject:saved forKey:[self vehicleTrailKey]];
}
- (void)refreshVehicleHistory
{
    ovmsAppDelegate *app=[ovmsAppDelegate myRef]; if(![app commandIsFree]){ self.modernLocationTitle.text=@"History unavailable"; self.modernLocationDetail.text=@"Another vehicle command is still pending"; return; }
    self.pendingHistoryPoints=[NSMutableArray array]; self.historyLoading=YES; self.modernLocationTitle.text=@"Loading trip history…"; self.modernLocationDetail.text=@"Requesting GPS records from the vehicle server"; [app commandRegister:@"32,RT-GPS-Log" callback:self]; self.historyTimeout=[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(vehicleHistoryTimedOut:) userInfo:nil repeats:NO];
}
- (void)vehicleHistoryTimedOut:(NSTimer *)timer
{
    [[ovmsAppDelegate myRef] commandCancel]; self.historyLoading=NO; self.historyTimeout=nil; self.pendingHistoryPoints=nil; self.modernLocationTitle.text=@"Trip history timed out"; self.modernLocationDetail.text=@"The saved trail remains available; try again when the module is online";
}
- (void)commandResult:(NSArray *)result
{
    if(!self.historyLoading || result.count<3) return;
    if([result[2] isEqual:@"No historical data available"]){ [self finishVehicleHistory]; return; }
    NSInteger code=[result[1] integerValue]; if(code!=0){ [self.historyTimeout invalidate]; [[ovmsAppDelegate myRef] commandCancel]; self.historyLoading=NO; self.modernLocationTitle.text=@"History unavailable"; self.modernLocationDetail.text=result.count>2?result[2]:@"Vehicle rejected the request"; return; }
    if(result.count>8 && [result[4] isEqualToString:@"RT-GPS-Log"]){ CLLocationCoordinate2D point=CLLocationCoordinate2DMake([result[7] doubleValue],[result[8] doubleValue]); if(CLLocationCoordinate2DIsValid(point) && (point.latitude!=0 || point.longitude!=0)) [self.pendingHistoryPoints addObject:[NSValue valueWithMKCoordinate:point]]; self.modernLocationDetail.text=[NSString stringWithFormat:@"Receiving GPS record %@ of %@ from the vehicle server",result[2],result[3]]; }
    if(result.count>3 && [result[2] integerValue]==[result[3] integerValue]) [self finishVehicleHistory];
}
- (void)finishVehicleHistory
{
    [self.historyTimeout invalidate]; self.historyTimeout=nil; [[ovmsAppDelegate myRef] commandCancel]; self.historyLoading=NO;
    if(self.pendingHistoryPoints.count){ self.vehicleTrail=self.pendingHistoryPoints; if(self.vehicleTrail.count>2000) [self.vehicleTrail removeObjectsInRange:NSMakeRange(0,self.vehicleTrail.count-2000)]; [self saveVehicleTrail]; [self initOverlays]; self.modernLocationTitle.text=@"Trip history loaded"; self.modernLocationDetail.text=[NSString stringWithFormat:@"%lu GPS points saved for offline viewing",(unsigned long)self.vehicleTrail.count]; } else { self.modernLocationTitle.text=@"No trip history"; self.modernLocationDetail.text=@"The server has no GPS log records for this vehicle"; }
    self.pendingHistoryPoints=nil;
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
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:NSLocalizedString(@"Warning", nil)
                                             message:NSLocalizedString(@"The selected car has no setup of charger type. Please go to settings car and setup the charger types.",nil)
                                             preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* okButton = [UIAlertAction
                                            actionWithTitle:@"Ok"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                //Handle your yes please button action here
                                            }];
                [alert addAction:okButton];
                [self presentViewController:alert animated:YES completion:nil];
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


#pragma mark - Load Open Charge Map Data
- (void)loadData:(CLLocationCoordinate2D)location {
    if (!self.loader) {
        self.loader = [[OCMSyncHelper alloc] initWithDelegate:self];
    }
    
    if (!self.isUseRange) {

        if (self.isLoadAll) {
            [self didFinishSync];
        } else {
            [self.loader startSyncAll:location];
        }
        return;
    }
    
    double estimatedrange = (double)[ovmsAppDelegate myRef].car_estimatedrange;
    NSString *connection_type_ids = [ovmsAppDelegate myRef].sel_connection_type_ids;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL ovmsOpenChargeMap = [defaults integerForKey:@"ovmsOpenChargeMap"];
    if (ovmsOpenChargeMap)
      {
      if (self.isFiltredChargingStation && connection_type_ids.length) {
          [self.loader startSyncWhithCoordinate:location toDistance:estimatedrange connectiontypeid:connection_type_ids];
      } else {
          [self.loader startSyncWhithCoordinate:location toDistance:estimatedrange];
      }
    }
}

- (void)didFinishSync {
    if (!self.isUseRange) self.isLoadAll = YES;
    
    [self initAnnotations];
}

- (void)didFailWithError:(NSError *)error {
// Just swallow the error for now, as OCM failures were littering the screen
    [self initAnnotations];
}

- (void)initAnnotations {
    NSMutableArray *rmAnnotations = [NSMutableArray array];
    
    for (id annotation in myMapView.annotations) {
        if ([annotation isKindOfClass:[VehicleAnnotation class]]) continue;
        [rmAnnotations addObject:annotation];
    }
    [myMapView removeAnnotations:rmAnnotations];
    
    NSMutableArray *annotations = [NSMutableArray array];
    for (ChargingLocation *loc in self.locations) {
        [annotations addObject:[ChargingAnnotation pinWithChargingLocation:loc]];
    }
    [myMapView addAnnotations:annotations];
    [self initOverlays];
}

- (void)initOverlays {
    double idealrange = [ovmsAppDelegate myRef].car_idealrange * 1000.0;
    double estimatedrange = [ovmsAppDelegate myRef].car_estimatedrange * 1000.0;
    
    [myMapView removeOverlays:myMapView.overlays];
    
    if ((idealrange + estimatedrange) > 0 && self.m_car_location && self.isUseRange) {
        [myMapView addOverlay:[MKCircle circleWithCenterCoordinate:[ovmsAppDelegate myRef].car_location radius:idealrange]];
        [myMapView addOverlay:[MKCircle circleWithCenterCoordinate:[ovmsAppDelegate myRef].car_location radius:estimatedrange]];
    }
    if (self.vehicleTrail.count > 1) {
        CLLocationCoordinate2D coordinates[self.vehicleTrail.count];
        for (NSUInteger index = 0; index < self.vehicleTrail.count; index++) coordinates[index] = [self.vehicleTrail[index] MKCoordinateValue];
        [myMapView addOverlay:[MKPolyline polylineWithCoordinates:coordinates count:self.vehicleTrail.count]];
    }
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

-(void)update {
    [self doupdate: false];
}

-(void)doupdate:(BOOL)forced {
    // The car has reported updated information, and we may need to reflect that
    CLLocationCoordinate2D location = [ovmsAppDelegate myRef].car_location;
    ovmsAppDelegate *app = [ovmsAppDelegate myRef];
    self.modernLocationTitle.text = app.car_gpslock > 0 ? @"Vehicle located" : @"Waiting for GPS";
    self.modernLocationDetail.text = [NSString stringWithFormat:@"%.5f, %.5f  ·  %@  ·  estimated range %@",
                                      location.latitude, location.longitude,
                                      [app.car_speed_s length] ? app.car_speed_s : @"stationary",
                                      [app.car_estimatedrange_s length] ? app.car_estimatedrange_s : @"--"];
    if (CLLocationCoordinate2DIsValid(location) && (location.latitude != 0 || location.longitude != 0)) {
        CLLocationCoordinate2D previous = self.vehicleTrail.count ? [[self.vehicleTrail lastObject] MKCoordinateValue] : kCLLocationCoordinate2DInvalid;
        CLLocation *point = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
        CLLocation *last = CLLocationCoordinate2DIsValid(previous) ? [[CLLocation alloc] initWithLatitude:previous.latitude longitude:previous.longitude] : nil;
        if (!last || [point distanceFromLocation:last] >= 10.0) {
            [self.vehicleTrail addObject:[NSValue valueWithMKCoordinate:location]];
            if (self.vehicleTrail.count > 2000) [self.vehicleTrail removeObjectAtIndex:0];
            [self saveVehicleTrail];
            [self initOverlays];
        }
    }
//    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(22.315778,114.220304);
    

    MKCoordinateRegion region = myMapView.region;
    if (( (region.center.latitude != location.latitude)&&
      (region.center.longitude != location.longitude) ) || forced) {

        if (self.m_car_location) {
            [UIView beginAnimations:@"ovmsVehicleAnnotationAnimation" context:nil];
            [UIView setAnimationBeginsFromCurrentState:YES];
            [UIView setAnimationDuration:3.0];
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            [self.m_car_location setDirection:[ovmsAppDelegate myRef].car_direction % 360];
            [self.m_car_location setSpeed:[ovmsAppDelegate myRef].car_speed_s];
            [self.m_car_location setCoordinate: location];
            [UIView commitAnimations];
            
            
            MKMapPoint mapPoint = MKMapPointForCoordinate(location);
            MKMapRect mapRect = myMapView.visibleMapRect;
            CGFloat zoomFactor = mapRect.size.width / myMapView.bounds.size.width;
            
            mapRect.origin.x += 40 * zoomFactor;
            mapRect.origin.y += 40 * zoomFactor;
            mapRect.size.width -= 80 * zoomFactor;
            mapRect.size.height -= 80 * zoomFactor;
            
            if (!MKMapRectContainsPoint(mapRect, mapPoint) && self.isAutotrack) {
                region.center = location;
                [myMapView setRegion:region animated:YES];
            }
            
        } else {
            // Remove all existing annotations
            NSMutableArray *annotations = [NSMutableArray array];
            for (id annotation in myMapView.annotations) {
                if (![annotation isKindOfClass:[VehicleAnnotation class]]) continue;
                [annotations addObject:annotation];
            }
            [myMapView removeAnnotations:annotations];
          
            // Create the vehicle annotation
            VehicleAnnotation *pa = [[VehicleAnnotation alloc] initWithCoordinate:location];
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
            
            [myMapView setRegion:region animated:YES];
            [myMapView regionThatFits:region];
        }
        
    [self loadData:location];
    }
}

-(void)groupUpdate:(NSArray*)result {
    if (m_groupcar_locations == nil) return;

    if ([result count] >= 10) {
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

        if ( (gpslock < 1) || (stalegps<1) ) return; // No GPS lock or data
        if ([vehicleid isEqualToString:[ovmsAppDelegate myRef].sel_car]) return; // Not the selected car 

        VehicleAnnotation *pa = [m_groupcar_locations objectForKey:vehicleid];
        if (pa != nil) {
            // Update an existing car
            [pa setCoordinate:location];
            [pa setTitle:vehicleid];
            [pa setSubtitle:[ovmsAppDelegate myRef].car_speed_s];
            [pa setImagefile:@"connection_good.png"];
            [pa setDirection:direction];
            [pa setSpeed:[[ovmsAppDelegate myRef] convertSpeedUnits:speed]];
        } else {
            // Create a new car
            pa = [[VehicleAnnotation alloc] initWithCoordinate:location];
            [pa setGroupCar:YES];
            [pa setTitle:vehicleid];
            [pa setSubtitle:[ovmsAppDelegate myRef].car_speed_s];
            [pa setImagefile:@"car_default.png"];
            [pa setDirection:direction%360];
            [pa setSpeed:[[ovmsAppDelegate myRef] convertSpeedUnits:speed]];
            [m_groupcar_locations setObject:pa forKey:vehicleid];
            [myMapView addAnnotation:pa];
        }
    }  
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    // Provide a custom view for the ovmsVehicleAnnotation
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }

    if([annotation isKindOfClass:[VehicleAnnotation class]]) {
        MKAnnotationView *annotationView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:IDENTIFIER_OVMS];

        //Here's where the magic happens
        VehicleAnnotation *pa = (VehicleAnnotation*)annotation;
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
        
        if ([pin nodeCount]) {
            annView.image = [UIImage imageNamed:@"cluster.png"];
        }
        
        [(REVClusterAnnotationView*)annView setClusterText: [NSString stringWithFormat:@"%lu",(unsigned long)[pin nodeCount]]];
        annView.canShowCallout = NO;
    } else {
        annView = [mapView dequeueReusableAnnotationViewWithIdentifier:IDENTIFIER_PIN];
        if (!annView) {
            annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:IDENTIFIER_PIN];
            annView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        annView.image = [UIImage imageNamed:[NSString stringWithFormat:@"level%ld.png", (long)pin.level]];
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
    m_lastregion = mapView.region;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MKCoordinateRegion newRegion = mapView.region;

    if (((m_lastregion.span.latitudeDelta / newRegion.span.latitudeDelta) > 1.5)||
        ((m_lastregion.span.latitudeDelta / newRegion.span.latitudeDelta) < 0.75)) {
        
        // Kludgy redraw of all annotations, by removing then replacing the annotations...
        NSMutableArray *rmAnnotations = [NSMutableArray array];
        for (id annotation in myMapView.annotations) {
            if (![annotation isKindOfClass:[VehicleAnnotation class]]) continue;
            [rmAnnotations addObject:annotation];
        }
        [myMapView removeAnnotations:rmAnnotations];
        
        if (m_car_location != nil) {
            [myMapView addAnnotation:m_car_location];
            [m_car_location redrawView];
        }
        
        NSEnumerator *enumerator = [m_groupcar_locations objectEnumerator];
        VehicleAnnotation *pa;
        while ((pa = [enumerator nextObject])) {
            [myMapView addAnnotation:pa];
            [pa redrawView];
        }
    }
}

- (void)mapView:(MKMapView *)aMapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *view in views) {
        if ([view.annotation isKindOfClass:[VehicleAnnotation class]]) {
            [view.superview bringSubviewToFront:view];
        } else {
            [view.superview sendSubviewToBack:view];
        }
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *trail = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        trail.strokeColor = [UIColor colorWithRed:0.10 green:0.58 blue:1.0 alpha:0.85]; trail.lineWidth = 5.0;
        return trail;
    }
    //MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithOverlay:overlay];
    circleView.lineWidth = 3;

    if ([mapView.overlays indexOfObject:overlay]) {
        circleView.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.4];
    } else {
        circleView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
    }
    
    return circleView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if (![view.annotation isKindOfClass:[ChargingAnnotation class]]) return;
    
    OCMInformationController *crl = [[OCMInformationController alloc] initWithStyle:UITableViewStyleGrouped];
    ChargingAnnotation *annotation = view.annotation;
    crl.locationUUID = annotation.uuid;
    crl.from = [ovmsAppDelegate myRef].car_location;
    crl.to = view.annotation.coordinate;
    [self.navigationController pushViewController:crl animated:YES];
}

@end
