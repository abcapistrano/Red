//
//  NSArray+DemonJelly.h
//  DemonJelly
//
//  Created by Earl on 10/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSArray (ConvenienceMethods)
- (id)objectHavingValue:(id) value forKey:(NSString *)key;
- (NSArray *) sample : (NSInteger) sampleSize ;
- (id) firstObject;
@end


@interface NSMutableArray (ConvenienceMethods)
- (id) pop;
- (id) pop:(NSInteger) index;
- (NSArray *) grab : (NSInteger) sampleSize;
- (void)randomize;
@end