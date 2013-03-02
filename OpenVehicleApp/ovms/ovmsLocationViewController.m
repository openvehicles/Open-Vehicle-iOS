//
//  ovmsLocationViewController.m
//  ovms
//
//  Created by Mark Webb-Johnson on 16/11/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import "ovmsLocationViewController.h"

#define IDENTIFIER_CLUSTER @"cluster"
#define IDENTIFIER_PIN @"pin"
#define IDENTIFIER_OVMS @"OVMS"

@implementation ovmsLocationViewController

@synthesize myMapView;
@synthesize m_car_location;
@synthesize m_groupcar_locations;
@synthesize m_lastregion;

#pragma mark - View lifecycle
- (void)viewDidUnload {
    [self setMyMapView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;

    self.m_car_location = nil;
    if (m_groupcar_locations == nil) m_groupcar_locations = [[NSMutableDictionary alloc] init];
    self.isAutotrack = YES;

    [[ovmsAppDelegate myRef] registerForUpdate:self];
    
    [self update];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
  
    // As we are about to disappear, remove all the car location objects
    // Remove all existing annotations
    for (int k=0; k < [myMapView.annotations count]; k++) {
        if ([[myMapView.annotations objectAtIndex:k] isKindOfClass:[ovmsVehicleAnnotation class]]) {
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
    NSLog(@"%s item:%d", __PRETTY_FUNCTION__, index);
    switch (index) {
        case 0: {
            self.isAutotrack = !self.isAutotrack;
            if (self.isAutotrack && m_car_location) {
                [myMapView setCenterCoordinate:m_car_location.coordinate animated:YES];
            }
            break;
        }
        case 1: {
            self.isFiltredChargingStation = !self.isFiltredChargingStation;
            [self performSelector:@selector(isUnderConstruction) withObject:nil afterDelay:0.7f];
            
            break;
        }
        case 2: {
            self.isUseRange = !self.isUseRange;
            [self performSelector:@selector(isUnderConstruction) withObject:nil afterDelay:0.7f];
            break;
        }
    }
    
    [popoverView showSuccess];
    [popoverView performSelector:@selector(dismiss) withObject:nil afterDelay:0.5f];
}

- (void)isUnderConstruction {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                    message:@"Is under construction"
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}


#pragma mark - Load Open Charge Map Data
- (void)loadData:(CLLocationCoordinate2D)location {
    if (!self.loader) {
        self.loader = [[OCMSyncHelper alloc] initWithDelegate:self];
    }
    double estimatedrange = (double)[ovmsAppDelegate myRef].car_estimatedrange;
    if (estimatedrange > 0.1) {
        [self.loader startSyncWhithCoordinate:location toDistance:estimatedrange];
    }
}

- (void)didFinishSync {
    [self initAnnotations];
}

- (void)didFailWithError:(NSError *)error {
    [self initAnnotations];
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

- (void)initOverlays {
    double idealrange = [ovmsAppDelegate myRef].car_idealrange * 1000.0;
    double estimatedrange = [ovmsAppDelegate myRef].car_estimatedrange * 1000.0;
    
    [myMapView removeOverlays:myMapView.overlays];
    if ((idealrange + estimatedrange) > 0 && self.m_car_location) {
        [myMapView addOverlay:[MKCircle circleWithCenterCoordinate:[ovmsAppDelegate myRef].car_location radius:idealrange]];
        [myMapView addOverlay:[MKCircle circleWithCenterCoordinate:[ovmsAppDelegate myRef].car_location radius:estimatedrange]];
    }
}


- (NSArray *)locations {
    double estimatedrange = (double)[ovmsAppDelegate myRef].car_estimatedrange * 1000;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(myMapView.centerCoordinate, estimatedrange, estimatedrange);
    
    double minLat = region.center.latitude - (region.span.latitudeDelta);
    double maxLat = region.center.latitude + (region.span.latitudeDelta);
    double minLong = region.center.longitude - (region.span.longitudeDelta);
    double maxLong = region.center.longitude + (region.span.longitudeDelta);
    
    NSFetchRequest *fr = [self fetchRequestWithEntityName:ENChargingLocation];
    NSPredicate *pr = [NSPredicate predicateWithFormat:@"addres_info.latitude > %f AND addres_info.latitude < %f AND addres_info.longitude > %f AND addres_info.longitude < %f",
                       minLat, maxLat, minLong, maxLong];
    [fr setPredicate:pr];
    
    return [self executeFetchRequest:fr];
}

-(void)update {
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
            
            [myMapView setRegion:region animated:YES];
            [myMapView regionThatFits:region]; 
        }
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
        ovmsVehicleAnnotation *pa = [m_groupcar_locations objectForKey:vehicleid];
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

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    // Provide a custom view for the ovmsVehicleAnnotation
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }

    if([annotation isKindOfClass:[ovmsVehicleAnnotation class]]) {
        MKAnnotationView *annotationView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:IDENTIFIER_OVMS];

        //Here's where the magic happens
        ovmsVehicleAnnotation *pa = (ovmsVehicleAnnotation*)annotation;
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
    m_lastregion = mapView.region;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MKCoordinateRegion newRegion = mapView.region;

    if (((m_lastregion.span.latitudeDelta / newRegion.span.latitudeDelta) > 1.5)||
        ((m_lastregion.span.latitudeDelta / newRegion.span.latitudeDelta) < 0.75)) {
        
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
