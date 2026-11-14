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

@interface ovmsLocationViewController : UIViewController <MKMapViewDelegate, ovmsUpdateDelegate, ovmsCommandDelegate, OCMSyncDelegate, PopoverViewDelegate>

@property (strong, nonatomic) IBOutlet REVClusterMapView *myMapView;
@property (strong, nonatomic) NSMutableDictionary* m_groupcar_locations;
@property (strong, nonatomic) VehicleAnnotation *m_car_location;
@property (assign) BOOL isAutotrack;
@property (assign) BOOL isFiltredChargingStation;
@property (assign) BOOL isUseRange;
@property (assign) BOOL isLoadAll;

@property (assign) MKCoordinateRegion m_lastregion;

@property (strong, nonatomic) OCMSyncHelper *loader;
@property (nonatomic, strong, readonly) NSArray *locations;
@property (strong, nonatomic) UILabel *modernLocationTitle;
@property (strong, nonatomic) UILabel *modernLocationDetail;
@property (assign) BOOL screenshotScenarioHandled;
@property (strong, nonatomic) NSMutableArray *vehicleTrail;
@property (strong, nonatomic) NSMutableArray *pendingHistoryPoints;
@property (strong, nonatomic) NSTimer *historyTimeout;
@property (assign) BOOL historyLoading;

- (IBAction)locationSnapped:(id)sender;

-(void) update;
-(void) doupdate:(BOOL)forced;
-(void) groupUpdate:(NSArray*)result;
-(void) showMapOptions;
-(void) refreshVehicleHistory;

@end
