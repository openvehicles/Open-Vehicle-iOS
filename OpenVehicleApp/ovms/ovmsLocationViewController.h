//
//  ovmsLocationViewController.h
//  ovms
//
//  Created by Mark Webb-Johnson on 16/11/11.
//  Copyright (c) 2011 Hong Hay Villa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "ovmsAppDelegate.h"
#import "ovmsVehicleAnnotation.h"

#import "OCMSyncHelper.h"
#import "EntityName.h"
#import "ChargingAnnotation.h"
#import "NSObject+CDHelper.h"
#import "REVClusterAnnotationView.h"

#define IDENTIFIER_CLUSTER @"cluster"
#define IDENTIFIER_PIN @"pin"


@interface ovmsLocationViewController : UIViewController <MKMapViewDelegate, ovmsUpdateDelegate, OCMSyncDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *myMapView;
@property (nonatomic, retain) ovmsVehicleAnnotation *m_car_location;
@property (strong, nonatomic) NSMutableDictionary* m_groupcar_locations;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *m_locationsnap;
@property (assign) BOOL m_autotrack;
@property (assign) MKCoordinateRegion m_lastregion;
@property (strong, nonatomic) OCMSyncHelper *loader;
@property (nonatomic, strong, readonly) NSArray *locations;

- (IBAction)locationSnapped:(id)sender;

-(void) update;
-(void) groupUpdate:(NSArray*)result;

-(void)zoomToFitMapAnnotations:(MKMapView*)mapView;

@end
