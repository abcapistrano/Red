//
//  ListenerDelegate.h
//  Red
//
//  Created by Earl on 3/6/13.
//  Copyright (c) 2013 Earl. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DJReadingListQueue.h"
@class HTTPServer;

@interface ListenerDelegate : NSObject <NSXPCListenerDelegate, Agent> {

    HTTPServer *httpServer;
    NSXPCConnection *connection;
    id observer1, observer2;
}

@end
