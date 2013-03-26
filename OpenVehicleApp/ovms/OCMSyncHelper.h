//
//  OpenChargeSync.h
//  OpenChargeMap
//
//  Created by JLab13 on 2/20/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@protocol OCMSyncDelegate <NSObject>
@optional
- (void)didFailWithError:(NSError *)error;
- (void)didFinishSync;
@end

@interface OCMSyncHelper : NSObject

- (id)initWithDelegate:(id)delegate;
- (void)startSyncWhithCoordinate:(CLLocationCoordinate2D)coordinate toDistance:(double)distance;
- (void)startSyncWhithCoordinate:(CLLocationCoordinate2D)coordinate toDistance:(double)distance connectiontypeid:(NSString *)connectiontypeid;
- (void)startSyncAll:(CLLocationCoordinate2D)coordinate;
- (void)startSyncWhithCountry:(NSString *)countrycode;
- (void)startSyncAction;
@end


