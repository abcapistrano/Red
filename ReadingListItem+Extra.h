//
//  ReadingListItem+Extra.h
//  Red
//
//  Created by Earl on 2/22/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "ReadingListItem.h"

@interface ReadingListItem (Extra)
+ (ReadingListItem *) readingListItemWithDefaultContext;
@property (readonly) NSURL *url;
@property (readonly) NSURL *referrerURL;
- (void) markAsRead;
@end
