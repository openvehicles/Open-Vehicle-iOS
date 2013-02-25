//
//  ChargingPin.m
//  OpenChargeMap
//
//  Created by JLab13 on 2/21/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import "ChargingAnnotation.h"

@implementation ChargingAnnotation

+ (id)pinWithChargingLocation:(ChargingLocation*)location {
    return [[ChargingAnnotation alloc] initWithChargingLocation:location];
}

- (id)initWithChargingLocation: (ChargingLocation*)location {
    if ([super init]) {
        self.location_uuid = location.uuid;
        self.title = location.operator_info.title;
        self.subtitle = [NSString stringWithFormat:@"Status: %@, Points: %@",
                         location.status_title,
                         location.number_of_points];
        self.coordinate = CLLocationCoordinate2DMake([location.addres_info.latitude doubleValue],
                                                     [location.addres_info.longitude doubleValue]);
        NSInteger level = 0;
        self.level = 0;
        for (Connection *cn in location.conections) {
            level = [cn.level_is_fast_charge boolValue] ? 3 : 2;
            if (level > self.level) self.level = level;
        }
    }
    return self;
}

@end
