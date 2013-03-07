//
//  DJReadingListQueue.h
//  Red
//
//  Created by Earl on 3/6/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DJReadingListQueue
- (void) addReadingListItemWithInfoDictionary: (NSDictionary *) dict;
- (void) websocketConnected;
@end


@protocol Agent
- (void) wake; //does nothing but to open the connection
@end