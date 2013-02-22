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
	
	[super didOpen];
}

- (void)didReceiveMessage:(NSString *)msg
{
	//HTTPLogTrace2(@"%@[%p]: didReceiveMessage: %@", THIS_FILE, self, msg);
	//NSLog(@"%@", msg);
	//[self sendMessage:[NSString stringWithFormat:@"%@", [NSDate date]]];
    [[DJQueueManager sharedQueueManager] addReadingListItemWithJSONInfo:msg];
}

- (void)didClose
{
	HTTPLogTrace();
	
	[super didClose];
}

@end