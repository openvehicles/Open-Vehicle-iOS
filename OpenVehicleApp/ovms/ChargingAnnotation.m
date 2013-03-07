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
    if ([self init]) {
        self.uuid = location.uuid;
        self.title = location.operator_info.title;
        self.subtitle = [NSString stringWithFormat:@"Status: %@, Points: %@",
                         location.status_title,
                         location.number_of_points];
        
        
        self.coordinate = CLLocationCoordinate2DMake([location.addres_info.latitude doubleValue],
                                                     [location.addres_info.longitude doubleValue]);
//        NSInteger level = 0;
//        self.level = 0;
//        BOOL isFirst = YES;
//        for (Connection *cn in location.conections) {
//            level = [cn.level.is_fast_charge_capable boolValue] ? 3 : 2;
//            if (level > self.level) self.level = level;
//            
//            if (!isFirst) continue;
//            isFirst = NO;
//            
//            self.title = cn.connection_type.title;
//            if (cn.level) {
//                self.subtitle = [NSString stringWithFormat:@"Status: %@, Points: %@, Voltage: %@",
//                                 location.status_title,
//                                 location.number_of_points,
//                                 cn.level.comments];
//            } else {
//                self.subtitle = [NSString stringWithFormat:@"Status: %@, Points: %@",
//                                 location.status_title,
//                                 location.number_of_points];
//            }
//            
//        }
        if (location.conections.count) {
            Connection *cn = location.conections.allObjects[0];
            self.title = cn.connection_type.title;
            if (cn.level) {
                self.subtitle = [NSString stringWithFormat:@"Status: %@, Points: %@, Voltage: %@",
                                 location.status_title,
                                 location.number_of_points,
                                 cn.level.comments];
            } else {
                self.subtitle = [NSString stringWithFormat:@"Status: %@, Points: %@",
                                 location.status_title,
                                 location.number_of_points];
            }
        }
        
        self.level = [location.status_is_operational boolValue] ? 1 : 0;
        if ([location.status_id integerValue] == 20) {
            self.level = 2;
        }
    }
    return self;
}

@end
