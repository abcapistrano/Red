//
//  LinkRollSite+Extra.h
//  Red
//
//  Created by Earl on 2/23/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "LinkRollSite.h"

@interface LinkRollSite (Extra)
+ (LinkRollSite *) linkRollSiteWithDefaultContext;
- (void) read;
- (NSURL *) url;
@end
