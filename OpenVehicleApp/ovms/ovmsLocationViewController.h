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
#import "VehicleAnnotation.h"

#import "OCMSyncHelper.h"
#import "EntityName.h"
#import "ChargingAnnotation.h"
#import "NSObject+CDHelper.h"

#import "REVClusterMap.h"
#import "REVClusterAnnotationView.h"
#import "PopoverView.h"

@interface ovmsLocationViewController : UIViewController <MKMapViewDelegate, ovmsUpdateDelegate, OCMSyncDelegate, PopoverViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *myMapView;
@property (strong, nonatomic) NSMutableDictionary* m_groupcar_locations;
@property (strong, nonatomic) VehicleAnnotation *m_car_location;
@property (assign) BOOL isAutotrack;
@property (assign) BOOL isFiltredChargingStation;
@property (assign) BOOL isUseRange;

@property (assign) MKCoordinateRegion m_lastregion;

@property (strong, nonatomic) OCMSyncHelper *loader;
@property (nonatomic, strong, readonly) NSArray *locations;

- (IBAction)locationSnapped:(id)sender;

-(void) update;
-(void) groupUpdate:(NSArray*)result;

@end
