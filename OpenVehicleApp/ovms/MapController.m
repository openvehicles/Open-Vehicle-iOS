//
//  MapController.m
//  OpenChargeMap
//
//  Created by JLab13 on 2/19/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import "MapController.h"
#import "OCMSyncHelper.h"
#import "NSObject+CDHelper.h"

#import "EntityName.h"

#import "ChargingAnnotation.h"
#import "REVClusterAnnotationView.h"

#define IDENTIFIER_CLUSTER @"cluster"
#define IDENTIFIER_PIN @"pin"

@interface MapController()<OCMSyncDelegate>
@property (nonatomic, strong, readonly) NSArray *locations;
@end

@implementation MapController
double distanceIdeal, distanceEstimated;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    distanceIdeal = 5000;
    distanceEstimated = 5500;
    
    self.mapView.region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(50.079176,-5.662766), distanceEstimated, distanceEstimated);
    
    [self initOverlays];
    [self initAnnotations];
}


- (IBAction)handleLoad:(id)sender {
    [self performSelectorInBackground:@selector(loadData) withObject:nil];
}

- (IBAction)handleTest:(id)sender {
    [self initAnnotations];
    [self initOverlays];
}

- (void)loadData {
    OCMSyncHelper *loader = [[OCMSyncHelper alloc] initWithDelegate:self];
    [loader startSyncWhithCoordinate:self.mapView.centerCoordinate toDistance:distanceEstimated / 1000];
}

- (void)didFinishSync {
    UIAlertView *allert = [[UIAlertView alloc] initWithTitle:nil
                                                     message:@"FinishSync"
                                                    delegate:nil
                                           cancelButtonTitle:@"Ok"
                                           otherButtonTitles:nil];
    [allert show];
    [self initAnnotations];
}

- (void)initOverlays {
    if (self.mapView.overlays.count) {
        [self.mapView removeOverlays:self.mapView.overlays];
    }
    
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:self.mapView.region.center radius:distanceIdeal];
    circle.title = @"ideal";
    [self.mapView addOverlay:circle];
    [self.mapView addOverlay:[MKCircle circleWithCenterCoordinate:self.mapView.region.center radius:distanceEstimated]];
}

- (NSArray *)locations {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.mapView.centerCoordinate, distanceEstimated, distanceEstimated);

//    double minLat = region.center.latitude - (region.span.latitudeDelta / 2.0);
//    double maxLat = region.center.latitude + (region.span.latitudeDelta / 2.0);
//    double minLong = region.center.longitude - (region.span.longitudeDelta / 2.0);
//    double maxLong = region.center.longitude + (region.span.longitudeDelta / 2.0);
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

- (void)initAnnotations {
    NSMutableArray *pins = [NSMutableArray array];
    for (ChargingLocation *loc in self.locations) {
        [pins addObject:[ChargingAnnotation pinWithChargingLocation:loc]];
    }
    [self.mapView addAnnotations:pins];
}

#pragma mark - Map view delegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if([annotation class] == MKUserLocation.class) {
		return nil;
	}
    
    ChargingAnnotation *pin = (ChargingAnnotation *)annotation;
    MKAnnotationView *annView;
    
    if( [pin nodeCount] > 0 ){
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
        annView.centerOffset = CGPointMake(0.0, -15.0);
    }
    return annView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if (![view isKindOfClass:[REVClusterAnnotationView class]]) {
        NSFetchRequest *fr = [self fetchRequestWithEntityName:ENChargingLocation];
        ChargingAnnotation *an = view.annotation;
        [fr setPredicate:[NSPredicate predicateWithFormat:@"uuid = %@", an.location_uuid]];
        
        ChargingLocation *cloc = [self executeFetchRequest:fr][0];
        for (Connection *cn in cloc.conections) {
            NSLog(@"%@: %@", cn.level_title, cn);
        }
        
        return;
    }
    
    CLLocationCoordinate2D centerCoordinate = [(REVClusterPin *)view.annotation coordinate];
    MKCoordinateSpan newSpan = MKCoordinateSpanMake(mapView.region.span.latitudeDelta/2.0, mapView.region.span.longitudeDelta/2.0);
    [mapView setRegion:MKCoordinateRegionMake(centerCoordinate, newSpan) animated:YES];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay {
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    circleView.lineWidth = 3;
    
    if ([overlay title]) {
        circleView.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.4];
    } else {
        circleView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
    }
    
    return circleView;
}


@end
