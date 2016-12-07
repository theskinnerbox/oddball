//
//  ERPNetworkConnection.m
//  OddBall
//
//  Created by Claudio Capobianco on 25/02/14.
//  Copyright (c) 2014 claudio. All rights reserved.
//

#import "ERPNetworkConnection.h"
#include <netdb.h>


//static const CGFloat kBeatDurationSeconds = 0.2;

@interface ERPNetworkConnection ()

@property (nonatomic, retain) NSThread *networkThread;
@property (nonatomic, strong, readwrite) UDPEcho *      echo;
@property NSUInteger recvPort;

@end

@implementation ERPNetworkConnection
@synthesize echo      = _echo;
@synthesize networkThread;
@synthesize recvPort;

#pragma mark * Utilities

static NSString * DisplayAddressForAddress(NSData * address)
// Returns a dotted decimal string for the specified address (a (struct sockaddr)
// within the address NSData).
{
    int         err;
    NSString *  result;
    char        hostStr[NI_MAXHOST];
    char        servStr[NI_MAXSERV];
    
    result = nil;
    
    if (address != nil) {
        
        // If it's a IPv4 address embedded in an IPv6 address, just bring it as an IPv4
        // address.  Remember, this is about display, not functionality, and users don't
        // want to see mapped addresses.
        
        if ([address length] >= sizeof(struct sockaddr_in6)) {
            const struct sockaddr_in6 * addr6Ptr;
            
            addr6Ptr = [address bytes];
            if (addr6Ptr->sin6_family == AF_INET6) {
                if ( IN6_IS_ADDR_V4MAPPED(&addr6Ptr->sin6_addr) || IN6_IS_ADDR_V4COMPAT(&addr6Ptr->sin6_addr) ) {
                    struct sockaddr_in  addr4;
                    
                    memset(&addr4, 0, sizeof(addr4));
                    addr4.sin_len         = sizeof(addr4);
                    addr4.sin_family      = AF_INET;
                    addr4.sin_port        = addr6Ptr->sin6_port;
                    addr4.sin_addr.s_addr = addr6Ptr->sin6_addr.__u6_addr.__u6_addr32[3];
                    address = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
                    assert(address != nil);
                }
            }
        }
        err = getnameinfo([address bytes], (socklen_t) [address length], hostStr, sizeof(hostStr), servStr, sizeof(servStr), NI_NUMERICHOST | NI_NUMERICSERV);
        if (err == 0) {
            result = [NSString stringWithFormat:@"%s:%s", hostStr, servStr];
            assert(result != nil);
        }
    }
    
    return result;
}

static NSString * DisplayStringFromData(NSData *data)
// Returns a human readable string for the given data.
{
    NSMutableString *   result;
    NSUInteger          dataLength;
    NSUInteger          dataIndex;
    const uint8_t *     dataBytes;
    
    assert(data != nil);
    
    dataLength = [data length];
    dataBytes  = [data bytes];
    
    result = [NSMutableString stringWithCapacity:dataLength];
    assert(result != nil);
    
    [result appendString:@"\""];
    for (dataIndex = 0; dataIndex < dataLength; dataIndex++) {
        uint8_t     ch;
        
        ch = dataBytes[dataIndex];
        if (ch == 10) {
            [result appendString:@"\n"];
        } else if (ch == 13) {
            [result appendString:@"\r"];
        } else if (ch == '"') {
            [result appendString:@"\\\""];
        } else if (ch == '\\') {
            [result appendString:@"\\\\"];
        } else if ( (ch >= ' ') && (ch < 127) ) {
            [result appendFormat:@"%c", (int) ch];
        } else {
            [result appendFormat:@"\\x%02x", (unsigned int) ch];
        }
    }
    [result appendString:@"\""];
    
    return result;
}

static NSString * DisplayErrorFromError(NSError *error)
// Given an NSError, returns a short error string that we can print, handling
// some special cases along the way.
{
    NSString *      result;
    NSNumber *      failureNum;
    int             failure;
    const char *    failureStr;
    
    assert(error != nil);
    
    result = nil;
    
    // Handle DNS errors as a special case.
    
    if ( [[error domain] isEqual:(NSString *)kCFErrorDomainCFNetwork] && ([error code] == kCFHostErrorUnknown) ) {
        failureNum = [[error userInfo] objectForKey:(id)kCFGetAddrInfoFailureKey];
        if ( [failureNum isKindOfClass:[NSNumber class]] ) {
            failure = [failureNum intValue];
            if (failure != 0) {
                failureStr = gai_strerror(failure);
                if (failureStr != NULL) {
                    result = [NSString stringWithUTF8String:failureStr];
                    assert(result != nil);
                }
            }
        }
    }
    
    // Otherwise try various properties of the error object.
    
    if (result == nil) {
        result = [error localizedFailureReason];
    }
    if (result == nil) {
        result = [error localizedDescription];
    }
    if (result == nil) {
        result = [error description];
    }
    assert(result != nil);
    return result;
}

#pragma mark * Echo delegate
- (BOOL)runServerOnPort:(NSUInteger)port
// One of two Objective-C 'mains' for this program.  This creates a UDPEcho
// object and runs it in server mode.
{
    assert(self.echo == nil);
    
    self.echo = [[UDPEcho alloc] init];
    assert(self.echo != nil);
    
    self.echo.delegate = self;
    
    [self.echo startServerOnPort:port];
    
    while (self.echo != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    // The loop above is supposed to run forever.  If it doesn't, something must
    // have failed and we want main to return EXIT_FAILURE.
    
    return NO;
}

- (void)echo:(UDPEcho *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr
// This UDPEcho delegate method is called after successfully receiving data.
{
    assert(echo == self.echo);
#pragma unused(echo)
    assert(data != nil);
    assert(addr != nil);
    NSLog(@"received %@ from %@", DisplayStringFromData(data), DisplayAddressForAddress(addr));
    [[self delegate] connection:self didReceiveData:data fromAddress:addr];
}

- (void)echo:(UDPEcho *)echo didReceiveError:(NSError *)error
// This UDPEcho delegate method is called after a failure to receive data.
{
    assert(echo == self.echo);
#pragma unused(echo)
    assert(error != nil);
    NSLog(@"received error: %@", DisplayErrorFromError(error));
}

#pragma mark - Thread management

- (void)startDriverThread {
    if (networkThread != nil) {
        [networkThread cancel];
    }
    
    NSThread *driverThread = [[NSThread alloc] initWithTarget:self 	selector:@selector(startDriverTimer:) object:nil];
    self.networkThread = driverThread;
    
    [self.networkThread start];
}

- (void)stopDriverThread {
    [self.networkThread cancel];
}

/*
- (void)waitForNetworkDriverThreadToFinish {
    while (networkThread && ![networkThread isFinished]) { // Wait for the thread to finish.
        [NSThread sleepForTimeInterval:0.1];
    }
}*/

// This method is invoked from the driver thread
- (void)startDriverTimer:(id)info {
    // Give the network thread high priority to keep the timing steady.
    //[NSThread setThreadPriority:1.0];
    if ([self runServerOnPort:(NSUInteger) self.recvPort]) { //FIXME please parametrize port
        NSLog(@"UDP server launch failed");
    }
}

#pragma mark * Public
-(id)initWithPort:(NSUInteger)port {
    self = [super init];
    self.recvPort = port;
    return self;
}
-(BOOL)isPlaying {
    return [[self networkThread] isExecuting];
}

-(void)start {
    [self startDriverThread];
}

-(void)stop {
    [self stopDriverThread];
}
@end



/*
 @property CFSocketContext ctxt;
 @property CFSocketRef connection;
 
@synthesize ctxt;
@synthesize connection;

-(id)init {
    self = [super init];
    
    // Create a context object to describe that object.
    ctxt.version = 0;
    ctxt.info = my_context_object;
    ctxt.retain = CFRetain;
    ctxt.release = CFRelease;
    ctxt.copyDescription = NULL;
    
   // Create a CFSocket object (CFSocketRef) for the CFSocketNativeHandle object by calling CFSocketCreateWithNative.
    connection = CFSocketCreateWithNative(kCFAllocatorDefault,
                                                      sock,
                                                      kCFSocketDataCallBack,
                                                      handleNetworkData,
                                                      &ctxt);
    
    // Tell Core Foundation that it is allowed to close the socket when the underlying Core Foundation object is invalidated.
    CFOptionFlags sockopt = CFSocketGetSocketFlags(connection);
    
    sockopt |= kCFSocketCloseOnInvalidate | kCFSocketAutomaticallyReenableReadCallBack;
    CFSocketSetSocketFlags(connection, sockopt);
    
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(
                                                                  kCFAllocatorDefault,
                                                                  connection,
                                                                  0);
    
    // Create an event source for the socket and schedule it on your run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), socketsource, kCFRunLoopDefaultMode);
    
    return self;
} */

