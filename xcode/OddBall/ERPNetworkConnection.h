//
//  ERPNetworkConnection.h
//  OddBall
//
//  Created by Claudio Capobianco on 25/02/14.
//  Copyright (c) 2014 claudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UDPEcho.h"

@protocol ERPNetworkConnectionDelegate;

@interface ERPNetworkConnection : NSObject <UDPEchoDelegate>

@property (nonatomic, weak,   readwrite) id<ERPNetworkConnectionDelegate>    delegate;
@property (readonly) BOOL isConnected;

-(id)initWithPort:(NSUInteger)port;
-(void)start;
-(void)stop;

@end

@protocol ERPNetworkConnectionDelegate <NSObject>

- (void)connection:(ERPNetworkConnection *)conn didReceiveData:(NSData *)data fromAddress:(NSData *)addr;
// Called after successfully receiving data.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);

@end
