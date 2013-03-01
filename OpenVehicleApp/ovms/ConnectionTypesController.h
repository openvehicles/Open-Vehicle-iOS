//
//  CRTableViewController.h
//  CRMultiRowSelector
//
//  Created by JLab13 on 3/01/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConnectionTypesController : UITableViewController

@property (nonatomic, strong) NSString *connectionTypeIds;

@property (nonatomic, strong) id target;
@property (nonatomic, unsafe_unretained) SEL action;

@end