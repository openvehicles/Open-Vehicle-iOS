//
//  AddressInfo.h
//  Open Vehicle
//
//  Created by JLab13 on 2/25/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AddressInfo : NSManagedObject

@property (nonatomic, retain) NSString * access_comments;
@property (nonatomic, retain) NSString * address_line1;
@property (nonatomic, retain) NSString * contact_telephone1;
@property (nonatomic, retain) NSString * country_iso_code;
@property (nonatomic, retain) NSString * country_title;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * postcode;
@property (nonatomic, retain) NSString * related_url;
@property (nonatomic, retain) NSString * state_or_province;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * town;

@end
