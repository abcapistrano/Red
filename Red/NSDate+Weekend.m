//
//  NSDate+Weekend.m
//  Red
//
//  Created by Earl on 3/8/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import "NSDate+Weekend.h"

@implementation NSDate (Weekend)
- (BOOL) isWeekend {
    NSDateComponents *dc = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self];
    NSUInteger weekday = [dc weekday];


    if (weekday == 1 || weekday == 7) //if weekday is Saturday or Sunday
    {
        return YES;
    } else {
        return NO;

    }

    
}
@end
