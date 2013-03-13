//
//  ReadingListItem+Extra.m
//  Red
//
//  Created by Earl on 2/22/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "ReadingListItem+Extra.h"
@implementation ReadingListItem (Extra)


+ (ReadingListItem *) readingListItemWithDefaultContext {

    return [NSEntityDescription insertNewObjectForEntityForName:@"ReadingListItem"
                                         inManagedObjectContext:[[NSApp delegate] managedObjectContext]];

    
}
- (NSURL *) url {

    
    return [NSURL URLWithString:self.urlString];
}

- (NSURL *) referrerURL {

    return [NSURL URLWithString:self.referrer];
}
- (void) markAsRead {

    self.isRead = @(YES);
    self.dateRead = [NSDate date];
}

@end
