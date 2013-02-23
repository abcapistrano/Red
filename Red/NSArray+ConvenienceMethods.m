//
//  NSArray+DemonJelly.m
//  DemonJelly
//
//  Created by Earl on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSArray+ConvenienceMethods.h"
#import <dispatch/dispatch.h>

@implementation NSArray (ConvenienceMethods)

//assumes that this is an array of dictionaries, and the contents of each dict are unique
- (id)objectHavingValue:(id) value forKey:(NSString *)key {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K == %@", key, value];
    NSArray *result = [self filteredArrayUsingPredicate:pred];
    return [result lastObject];
}


- (NSArray *) sample : (NSInteger) sampleSize 
{
    NSMutableArray * this = [self mutableCopy];
    [this randomize];
    
    NSInteger maxSize = [self count];
    
    if (maxSize < sampleSize) {
        sampleSize = maxSize;
    }
    
    NSRange x = NSMakeRange(0, sampleSize);
    return [this subarrayWithRange:x];
    
}

- (id) firstObject {
    if ([self count] > 0) return [self objectAtIndex:0];
    else return nil;
}


@end


@implementation NSMutableArray (ConvenienceMethods)
- (id) pop {
    id obj = [self lastObject];
    [self removeLastObject];
    return obj;
}
- (id) pop:(NSInteger) index {
    id obj = [self objectAtIndex:index];
    [self removeObjectAtIndex:index];
    return obj;
}
// WARNING: this shuffles the array
- (NSArray *) grab : (NSInteger) sampleSize {
    
    NSInteger maxSize = [self count];
    
    if (maxSize < sampleSize) {
        sampleSize = maxSize;
    }
    
    NSRange x = NSMakeRange(0, sampleSize);
    
    [self randomize];
    
    NSArray *sample = [self subarrayWithRange:x];
    
    [self removeObjectsInRange:x];
    
    
    return sample;
    
   
}

- (void)randomize
{
    NSInteger count = [self count];
    for (NSInteger i = 0; i < count - 1; i++)
    {
        NSInteger swap = arc4random() % (count - i) + i;
        [self exchangeObjectAtIndex:swap withObjectAtIndex:i];
    }
}


@end