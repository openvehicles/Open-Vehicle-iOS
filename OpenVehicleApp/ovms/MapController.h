//
//  MapController.h
//  OpenChargeMap
//
//  Created by JLab13 on 2/19/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapController : UIViewController<MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)handleLoad:(id)sender;
- (IBAction)handleTest:(id)sender;

@end
