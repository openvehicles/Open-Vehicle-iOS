//
//  OpenChargeSync.m
//  OpenChargeMap
//
//  Created by JLab13 on 2/20/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import "OCMSyncHelper.h"
#import "ovmsAppDelegate.h"
#import "NSObject+CDHelper.h"

#import "EntityName.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })
#define BASE_URL @"http://api.openchargemap.io/v2/poi/?output=json&verbose=false"
#define SWF(format, args...) [NSString stringWithFormat:format, args]

//#define UPDATE_SEC 120.0
#define UPDATE_METER 1000.0

@interface OCMSyncHelper()

@property (nonatomic, strong) id<OCMSyncDelegate> delegate;
@property (nonatomic, assign) BOOL isProcess;
@property (nonatomic, assign) BOOL isSyncAction;
@property (nonatomic, assign) CLLocationCoordinate2D lastCoordinate;
@property (nonatomic, strong) NSString *connectiontypeid;

@end

@implementation OCMSyncHelper

- (id)initWithDelegate:(id)delegate {
    if ([self init]) {
        self.delegate = delegate;
        self.isProcess = NO;
        self.isSyncAction = NO;
    }
    return self;
}

- (void)startSyncWhithCoordinate:(CLLocationCoordinate2D)coordinate toDistance:(double)distance connectiontypeid:(NSString *)connectiontypeid {
    if (self.isProcess) return;
    NSLog(@"startSyncWhithCoordinate: %@ = %@", connectiontypeid, self.connectiontypeid);

    if (![self allowNextUpdate:coordinate] && [self.connectiontypeid isEqualToString:connectiontypeid]) return;
    self.connectiontypeid = connectiontypeid;
    
    self.isProcess = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSString *surl = SWF(@"%@&latitude=%0.6f&longitude=%0.6f&distance=%g&distanceunit=KM&maxresults=500&connectiontypeid=%@", BASE_URL,
                         coordinate.latitude, coordinate.longitude, distance, connectiontypeid);
    NSLog(@"start sync: %@", surl);
    
    [self performSelectorInBackground:@selector(start:) withObject:[NSURL URLWithString:surl]];
}


- (void)startSyncWhithCoordinate:(CLLocationCoordinate2D)coordinate toDistance:(double)distance {
    if (self.isProcess) return;
    NSLog(@"startSyncWhithCoordinate: %@", self.connectiontypeid);
    
    if (![self allowNextUpdate:coordinate] && !self.connectiontypeid) return;
    self.connectiontypeid = nil;
    
    self.isProcess = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSString *surl = SWF(@"%@&latitude=%0.6f&longitude=%0.6f&distance=%g&distanceunit=KM&maxresults=500", BASE_URL,
                         coordinate.latitude, coordinate.longitude, distance);
    NSLog(@"start sync: %@", surl);
    
    [self performSelectorInBackground:@selector(start:) withObject:[NSURL URLWithString:surl]];
}

- (void)startSyncAll:(CLLocationCoordinate2D)coordinate {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           if (!placemarks.count) return;
                           
                           CLPlacemark *place = placemarks[0];
                           [self startSyncWhithCountry:place.ISOcountryCode];
                       });
                   }];
}

- (void)startSyncWhithCountry:(NSString *)countrycode {
    if (self.isProcess) return;
    self.isProcess = YES;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSString *surl = SWF(@"%@&countrycode=%@&maxresults=5000", BASE_URL, countrycode);
    NSLog(@"start sync: %@", surl);
    
    [self performSelectorInBackground:@selector(start:) withObject:[NSURL URLWithString:surl]];
}

- (BOOL)allowNextUpdate:(CLLocationCoordinate2D)coordinate {
    CLLocation *from = [[CLLocation alloc] initWithLatitude:self.lastCoordinate.longitude longitude:self.lastCoordinate.longitude];
    CLLocation *to = [[CLLocation alloc] initWithLatitude:coordinate.longitude longitude:coordinate.longitude];
    CLLocationDistance distance = [from distanceFromLocation:to];
    
    if (distance < UPDATE_METER) return NO;
    
    self.lastCoordinate = coordinate;
    return YES;
}

- (void)startSyncAction {
    if (self.isProcess) return;
    
    self.isProcess = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self performSelectorInBackground:@selector(startAction:) withObject:[NSNumber numberWithBool:YES]];
}


- (void)start:(NSURL *)url {
    if (!self.isSyncAction) [self startAction:[NSNumber numberWithBool:NO]];
    
    NSError* error = nil;
    NSData *receivedData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
    
    if (error) {
        [self performSelectorOnMainThread:@selector(stop:) withObject:error waitUntilDone:NO];
        return;
    }
    
    NSArray* json = [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:kNilOptions
                                                      error:&error];

    if (error) {
        [self performSelectorOnMainThread:@selector(stop:) withObject:error waitUntilDone:NO];
        return;
    }
    
    if (json.count) {
        [self performSelectorOnMainThread:@selector(parseAndStop:) withObject:json waitUntilDone:NO];
//        [self parseData:json];
    
        [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:NO];
    } else {
        NSLog(@"Response empty data");
        [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:NO];
    }
}

- (void)startAction:(NSNumber *)single {
    NSError* error = nil;
    NSString *surl = SWF(@"%@&action=getcorereferencedata", BASE_URL);
    NSLog(@"SyncAction: %@", surl);
    NSData *receivedData = [NSData dataWithContentsOfURL:[NSURL URLWithString:surl] options:NSDataReadingUncached error:&error];
    if (error) {
        [self performSelectorOnMainThread:@selector(stop:) withObject:error waitUntilDone:NO];
        return;
    }
    
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:receivedData
                                                         options:kNilOptions
                                                           error:&error];
    if (error) {
        [self performSelectorOnMainThread:@selector(stop:) withObject:error waitUntilDone:NO];
        return;
    }
    
    [self performSelectorOnMainThread:@selector(syncActionAndStop:) withObject:@[data, single] waitUntilDone:NO];
//    if (data.count) {
//        [self syncAction:data];
//        self.isSyncAction = YES;
//    }
//
//    if ([single boolValue]) {
//        [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:NO];
//    }
}

- (void)syncActionAndStop:(NSArray *)data {
    [self syncAction:data[0]];
    self.isSyncAction = YES;
    
    NSNumber *single = data[1];
    
    if ([single boolValue]) {
        [self stop:nil];
    }
}


- (void)parseAndStop:(NSArray *)items {
    [self parseData:items];
    [self stop:nil];
}

- (void)stop:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.isProcess = NO;
    
    if (error) {
        NSLog(@"ERROR %@, %@", error, [error userInfo]);
        
        if ([self.delegate respondsToSelector:@selector(didFailWithError:)]) {
            [self.delegate didFailWithError:error];
        }
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didFinishSync)]) {
        [self.delegate didFinishSync];
    }
}

#pragma mark - parse data
- (void)parseData:(NSArray *)items {
    NSLog(@"parseData: %d", items.count);

    for (NSDictionary *row in items) {
        [self parseChargingLocations:row];
    }
    
    [[ovmsAppDelegate myRef] saveContext];
    
    NSLog(@"Sync %d records.", items.count);
}

- (void)parseChargingLocations:(NSDictionary *)row {
    ChargingLocation *cl = [self entityWithName:ENChargingLocation
                                        asWhere:@"uuid"
                                        inValue:row[@"UUID"]];
    if (!cl) {
        cl = [NSEntityDescription insertNewObjectForEntityForName:ENChargingLocation
                                           inManagedObjectContext:self.managedObjectContext];
    }
    
    cl.uuid = NULL_TO_NIL(row[@"UUID"]);
    cl.data_providers_reference = NULL_TO_NIL(row[@"DataProvidersReference"]);
    cl.data_quality_level = NULL_TO_NIL(row[@"DataQualityLevel"]);
    cl.general_comments = NULL_TO_NIL(row[@"GeneralComments"]);
    cl.number_of_points = NULL_TO_NIL(row[@"NumberOfPoints"]);
    
    if (NULL_TO_NIL(row[@"UsageType"])) {
        cl.usage = NULL_TO_NIL(row[@"UsageType"][@"Title"]);
    }
    
    if (NULL_TO_NIL(row[@"StatusType"])) {
        cl.status_id = NULL_TO_NIL(row[@"StatusType"][@"ID"]);
        cl.status_is_operational = NULL_TO_NIL(row[@"StatusType"][@"IsOperational"]);
        cl.status_title = NULL_TO_NIL(row[@"StatusType"][@"Title"]);
    }
    
    [self parseAddressInfoToChargingLocations:cl asObject:NULL_TO_NIL(row[@"AddressInfo"])];
    [self parseOperatorInfoToChargingLocations:cl asObject:NULL_TO_NIL(row[@"OperatorInfo"])];
    [self parseConnectionToChargingLocations:cl asArray:NULL_TO_NIL(row[@"Connections"])];
}

- (void)parseAddressInfoToChargingLocations:(ChargingLocation *)cl asObject:(NSDictionary *)row {
//    NSLog(@"parseAddressInfoToChargingLocations: %d", row.count);
    if (!row) {
        cl.addres_info = nil;
        return;
    }
    
    NSNumber *entityID = row[@"ID"];
    
    AddressInfo *ai = cl.addres_info;
    if (!ai || ![ai.id isEqualToNumber:entityID]) {
        ai = [NSEntityDescription insertNewObjectForEntityForName:ENAddressInfo
                                               inManagedObjectContext:self.managedObjectContext];
        cl.addres_info = ai;
    }
    ai.id = entityID;
    ai.access_comments = NULL_TO_NIL(row[@"AccessComments"]);
    ai.address_line1 = NULL_TO_NIL(row[@"AddressLine1"]);
    ai.contact_telephone1 = NULL_TO_NIL(row[@"ContactTelephone1"]);
    ai.country_iso_code = NULL_TO_NIL(row[@"Country"][@"ISOCode"]);
    ai.country_title = NULL_TO_NIL(row[@"Country"][@"Title"]);
    ai.latitude = NULL_TO_NIL(row[@"Latitude"]);
    ai.longitude = NULL_TO_NIL(row[@"Longitude"]);
    ai.postcode = NULL_TO_NIL(row[@"Postcode"]);
    ai.related_url = NULL_TO_NIL(row[@"RelatedURL"]);
    ai.state_or_province = NULL_TO_NIL(row[@"StateOrProvince"]);
    ai.title = NULL_TO_NIL(row[@"Title"]);
    ai.town = NULL_TO_NIL(row[@"Town"]);
}

- (void)parseOperatorInfoToChargingLocations:(ChargingLocation *)cl asObject:(NSDictionary *)row {
//    NSLog(@"parseOperatorInfoToChargingLocations: %d", row.count);
    if (!row) {
        cl.operator_info = nil;
        return;
    }
    
    NSNumber *entityID = row[@"ID"];
    
    OperatorInfo *oi = cl.operator_info;
    if (!oi || ![oi.id isEqualToNumber:entityID]) {
        oi = [NSEntityDescription insertNewObjectForEntityForName:ENOperatorInfo
                                           inManagedObjectContext:self.managedObjectContext];
        cl.operator_info = oi;
    }
    oi.id = entityID;
    oi.address_info = NULL_TO_NIL(row[@"AddressInfo"]);
    oi.booking_url = NULL_TO_NIL(row[@"BookingURL"]);
    oi.comments = NULL_TO_NIL(row[@"Comments"]);
    oi.contact_email = NULL_TO_NIL(row[@"ContactEmail"]);
    oi.fault_report_email = NULL_TO_NIL(row[@"FaultReportEmail"]);
    oi.is_private_individual = NULL_TO_NIL(row[@"IsPrivateIndividual"]);
    oi.phone_primary_contact = NULL_TO_NIL(row[@"PhonePrimaryContact"]);
    oi.phone_secondary_contact = NULL_TO_NIL(row[@"PhoneSecondaryContact"]);
    oi.title = NULL_TO_NIL(row[@"Title"]);
    oi.website_url = NULL_TO_NIL(row[@"WebsiteURL"]);
}

- (void)parseConnectionToChargingLocations:(ChargingLocation *)cl asArray:(NSArray *)items {
//    NSLog(@"parseConnectionToChargingLocations: %d", items.count);

    if (!items) {
        cl.conections = nil;
        return;
    }
    
    if (cl.conections) {
        NSSet *conections = [NSSet setWithSet:cl.conections];
        for (Connection *co in conections) {
            [cl removeConectionsObject:co];
        }
    }
    
    for (NSDictionary *row in items) {
        NSNumber *entityID = row[@"ID"];
        
        Connection *co = [self entityWithName:ENConnection
                                      asWhere:@"id"
                                      inValue:[entityID stringValue]];
        if (!co) {
            co = [NSEntityDescription insertNewObjectForEntityForName:ENConnection
                                               inManagedObjectContext:self.managedObjectContext];
        }
        
        co.id = entityID;
        co.amps = NULL_TO_NIL(row[@"Amps"]);
        co.comments = NULL_TO_NIL(row[@"Comments"]);
        co.voltage = NULL_TO_NIL(row[@"Voltage"]);
        co.power_kw = [NULL_TO_NIL(row[@"PowerKW"]) stringValue];
        co.quantity = NULL_TO_NIL(row[@"Quantity"]);
        co.reference = NULL_TO_NIL(row[@"Reference"]);

        if (NULL_TO_NIL(row[@"StatusType"])) {
            co.status_is_operational = NULL_TO_NIL(row[@"StatusType"][@"IsOperational"]);
            co.status_title = NULL_TO_NIL(row[@"StatusType"][@"Title"]);
        }
        
        if (NULL_TO_NIL(row[@"ConnectionType"])) {
            co.connection_type = [self entityWithName:ENConnectionTypes
                                              asWhere:@"id"
                                              inValue:[row[@"ConnectionType"][@"ID"] stringValue]];
        }
        if (NULL_TO_NIL(row[@"Level"])) {
            co.level = [self entityWithName:ENChargerTypes
                                    asWhere:@"id"
                                    inValue:[row[@"Level"][@"ID"] stringValue]];
        }
        
        [cl addConectionsObject:co];
    }
}

#pragma mark - syncAction
- (void)syncAction:(NSDictionary *)data {
    NSLog(@"syncAction: %d", data.count);
    
    [self parseConnectionTypes:NULL_TO_NIL(data[@"ConnectionTypes"])];
    [self parseChargerTypes:NULL_TO_NIL(data[@"ChargerTypes"])];

    [[ovmsAppDelegate myRef] saveContext];
}

- (void)parseConnectionTypes:(NSArray *)items {
    NSLog(@"parseConnectionTypes: %d", items.count);
    if (!items) return;
    
    for (NSDictionary *row in items) {
        NSNumber *entityID = row[@"ID"];
        
        ConnectionTypes *entity = [self entityWithName:ENConnectionTypes
                                               asWhere:@"id"
                                               inValue:[entityID stringValue]];
        if (!entity) {
            entity = [NSEntityDescription insertNewObjectForEntityForName:ENConnectionTypes
                                                   inManagedObjectContext:self.managedObjectContext];
        }
        
        entity.id = row[@"ID"];
        entity.title = NULL_TO_NIL(row[@"Title"]);
        entity.formal_name = NULL_TO_NIL(row[@"FormalName"]);
        entity.is_discontinued = NULL_TO_NIL(row[@"IsDiscontinued"]);
        entity.is_obsolete = NULL_TO_NIL(row[@"IsObsolete"]);
    }
}

- (void)parseChargerTypes:(NSArray *)items {
    NSLog(@"parseChargerTypes: %d", items.count);
    if (!items) return;
    
    for (NSDictionary *row in items) {
        NSNumber *entityID = row[@"ID"];
        
        ChargerTypes *entity = [self entityWithName:ENChargerTypes
                                            asWhere:@"id"
                                            inValue:[entityID stringValue]];
        if (!entity) {
            entity = [NSEntityDescription insertNewObjectForEntityForName:ENChargerTypes
                                                   inManagedObjectContext:self.managedObjectContext];
        }
        
        entity.id = row[@"ID"];
        entity.title = NULL_TO_NIL(row[@"Title"]);
        entity.comments = NULL_TO_NIL(row[@"Comments"]);
        entity.is_fast_charge_capable = NULL_TO_NIL(row[@"IsFastChargeCapable"]);
    }
}


@end
