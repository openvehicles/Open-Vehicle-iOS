//
//  OCMInformationController.h
//  Open Vehicle
//
//  Created by JLab13 on 3/7/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface OCMInformationController : UITableViewController

@property (nonatomic, strong) NSString *locationUUID;
@property (nonatomic, assign) CLLocationCoordinate2D from;
@property (nonatomic, assign) CLLocationCoordinate2D to;

@end
