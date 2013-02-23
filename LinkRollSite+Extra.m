//
//  LinkRollSite+Extra.m
//  Red
//
//  Created by Earl on 2/23/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "LinkRollSite+Extra.h"

@implementation LinkRollSite (Extra)
+ (LinkRollSite *) linkRollSiteWithDefaultContext {
    return [NSEntityDescription insertNewObjectForEntityForName:@"LinkRollSite"
                                         inManagedObjectContext:[[NSApp delegate] managedObjectContext]];

}

- (void) awakeFromInsert {

    [super awakeFromInsert];
    self.lastDateAccessed = [NSDate distantPast];
}

- (void) read {
    self.lastDateAccessed = [NSDate date];
    
}

- (NSURL *) url {
    return [NSURL URLWithString:self.urlString];
}

@end
