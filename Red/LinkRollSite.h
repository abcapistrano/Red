//
//  LinkRollSite.h
//  Red
//
//  Created by Earl on 2/23/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LinkRollSite : NSManagedObject

@property (nonatomic, retain) NSString * group;
@property (nonatomic, retain) NSDate * lastDateAccessed;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * urlString;

@end
