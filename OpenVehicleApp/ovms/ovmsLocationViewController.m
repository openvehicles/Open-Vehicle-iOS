//
//  ovmsLocationViewController.m
//  ovms
//
//  Created by Mark Webb-Johnson on 16/11/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import "ovmsLocationViewController.h"
#import "OCMInformationController.h"

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
}

- (void)viewDidUnload {
    [self setMyMapView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"sel_connection_type_ids: %@", [ovmsAppDelegate myRef].sel_connection_type_ids);
    
    self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;

    self.m_car_location = nil;
    if (m_groupcar_locations == nil) m_groupcar_locations = [[NSMutableDictionary alloc] init];
    self.isAutotrack = YES;

    [[ovmsAppDelegate myRef] registerForUpdate:self];
    
    [self update];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
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
    NSArray *options = @[
        self.isAutotrack ? NSLocalizedString(@"Turn OFF autotrack", nil) : NSLocalizedString(@"Turn ON autotrack", nil),
        self.isFiltredChargingStation ? NSLocalizedString(@"Filtered Stations OFF", nil) : NSLocalizedString(@"Filtered Stations ON", nil),
        self.isUseRange ? NSLocalizedString(@"Only show Stations in range OFF", nil) : NSLocalizedString(@"Only show Stations in range ON", nil)
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
    // The car has reported updated information, and we may need to reflect that
    CLLocationCoordinate2D location = [ovmsAppDelegate myRef].car_location;
//    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(22.315778,114.220304);
    

    MKCoordinateRegion region = myMapView.region;
    if ( (region.center.latitude != location.latitude)&&
      (region.center.longitude != location.longitude) ) {

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

        NSLog(@"groupUpdate for %@", vehicleid);
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
            NSLog(@"groupCarCreated %@ count=%lu", vehicleid,(unsigned long)[[myMapView annotations] count]);
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

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay {
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
