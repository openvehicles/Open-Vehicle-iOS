//
//  OperatorInfo.h
//  Open Vehicle
//
//  Created by JLab13 on 3/1/13.
//  Copyright (c) 2013 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OperatorInfo : NSManagedObject

@property (nonatomic, retain) NSString * address_info;
@property (nonatomic, retain) NSString * booking_url;
@property (nonatomic, retain) NSString * comments;
@property (nonatomic, retain) NSString * contact_email;
@property (nonatomic, retain) NSString * fault_report_email;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * is_private_individual;
@property (nonatomic, retain) NSString * phone_primary_contact;
@property (nonatomic, retain) NSString * phone_secondary_contact;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * website_url;

@end
