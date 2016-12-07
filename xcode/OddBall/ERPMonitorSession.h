//
//  ERPMonitorSession.h
//  OddBall
//
//  Created by Claudio Capobianco on 24/06/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ERPMonitorSession;

static const NSInteger ERP_BPM_PLAY_COUNTINUOSLY = 0;
static const NSInteger ERP_DURATION_INFINITE = 0;

@protocol ERPMonitorSession
- (void)beatRoutine:(ERPMonitorSession *)session;
@end

@interface ERPMonitorSession : NSObject

@property id delegate;

@property CGFloat audioBPM;  // 0: play countinuosly
@property CGFloat audioBPMVariability;
@property CGFloat rareFreq;
@property CGFloat commonFreq;
@property CGFloat rareCommonRate;
@property CGFloat beatDurationSeconds;

@property CGFloat duration; // seconds, 0 is infinite (until stop)

@property (readonly) BOOL isPlaying;
@property (readonly) NSDate* lastRareTime;
@property (readonly) BOOL lastIsRare;

-(void)start;
-(void)stop;
-(void)update;

@end
