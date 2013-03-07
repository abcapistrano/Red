#import "MyWebSocket.h"
#import "HTTPLogging.h"
#import "DJQueueManager.h"

// Log levels: off, error, warn, info, verbose
// Other flags : trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN | HTTP_LOG_FLAG_TRACE;


@implementation MyWebSocket

- (void)didOpen
{
	HTTPLogTrace();
	NSLog(@"open");
	[super didOpen];

  
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WebsocketConnected"
                                                        object:self];



}



- (void)didReceiveMessage:(NSString *)msg
{

    NSData *jsonData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MessageReceived"
                                                        object:self
                                                      userInfo:info];


}

- (void)didClose
{
    NSLog(@"websocket close");
	HTTPLogTrace();
	
	[super didClose];
}

@end
