		//
//  ERPMonitorSession.m
//  OddBall
//
//  Created by Claudio Capobianco on 24/06/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//

#import "ERPMonitorSession.h"
#import "ToneGenerator.h"

@interface ERPMonitorSession () {
    ToneGenerator* tonegen;
}

@property (nonatomic, retain) NSThread *soundPlayerThread;
@property NSDate* startTime;

@end

@implementation ERPMonitorSession

@synthesize audioBPM;
@synthesize audioBPMVariability;
@synthesize rareFreq;
@synthesize commonFreq;
@synthesize rareCommonRate;

@synthesize lastRareTime;
@synthesize lastIsRare;

@synthesize soundPlayerThread;
@synthesize beatDurationSeconds;
@synthesize startTime;

//@synthesize iisGain;

#pragma mark - Initialization
-(id)init {
    self = [super init];
    
    beatDurationSeconds = 0.2;
    lastIsRare = NO;
    
    tonegen = [[ToneGenerator alloc]init];
    
    return self;
}

#pragma mark - Start/Stop

-(BOOL)isPlaying {
    return [[self soundPlayerThread] isExecuting];
}

-(void)start {
    [self startDriverThread];
}

-(void)stop {
    [self stopDriverThread];
}

-(void)update {
    
    if (lastIsRare) {
        tonegen->frequency = rareFreq;
    } else {
        tonegen->frequency = commonFreq;
    }
    startTime = [[NSDate alloc] init];
}

#pragma mark - Thread management

- (void)startDriverThread {
    if (soundPlayerThread != nil) {
        [soundPlayerThread cancel];
        //[self waitForSoundDriverThreadToFinish];
        //self.soundPlayerThread = nil;
    }
    
    NSThread *driverThread = [[NSThread alloc] initWithTarget:self 	selector:@selector(startDriverTimer:) object:nil];
    self.soundPlayerThread = driverThread;
    
    [self.soundPlayerThread start];
}

- (void)stopDriverThread {
    [tonegen togglePlay]; // off
    [self.soundPlayerThread cancel];
    
    //_isPlaying = NO;
    //[self waitForSoundDriverThreadToFinish];
    //self.soundPlayerThread = nil;
}

- (void)waitForSoundDriverThreadToFinish {
    while (soundPlayerThread && ![soundPlayerThread isFinished]) { // Wait for the thread to finish.
        [NSThread sleepForTimeInterval:0.1];
    }
}

// This method is invoked from the driver thread
- (void)startDriverTimer:(id)info {
    // Give the sound thread high priority to keep the timing steady.
    [NSThread setThreadPriority:1.0];
    BOOL continuePlaying = YES;
    //_isPlaying = YES;
    
    startTime = [[NSDate alloc] init];
    
    // Start play
    [tonegen togglePlay]; //on
    
    while (continuePlaying) {  // Loop until cancelled.

        [[self delegate] beatRoutine:self];
        [self playBeat];
        [self playIIS];
        
        // check if session duration is over
        if (self.duration > 0) {
            NSDate *currentTime = [[NSDate alloc] init];
            NSDate *curtainTime = [[NSDate alloc] initWithTimeInterval:self.duration sinceDate:startTime];
            if ([currentTime compare:curtainTime] != NSOrderedAscending) {
                [self stopDriverThread];
            }
        }
        
        // exit condition
        if (continuePlaying) {
            if ([soundPlayerThread isCancelled] == YES) {
                continuePlaying = NO;
            }
        }
    }
}

-(void)mute {
    tonegen->frequency = 0;
}

-(void)playBeat {
    int rand = arc4random() % 100;
    if (rand < rareCommonRate) {
        tonegen->frequency = rareFreq;
        lastRareTime = [[NSDate alloc] init];
        lastIsRare = true;
    } else {
        tonegen->frequency = commonFreq;
        lastIsRare = false;
    }
    
    [NSThread sleepForTimeInterval:beatDurationSeconds];
    
    [self mute];
}

-(void)playIIS {

    if (audioBPM > 0) {
        //iis: intervallo inter stimolo
        int sign = 1 - 2 * (arc4random() % 2);
        int bpmVariability = (int)round(audioBPMVariability);
        CGFloat randBPM = 0;
        if (bpmVariability > 0) {
            randBPM = (float)((float)(arc4random() % bpmVariability) * (float)sign);
        }
        CGFloat periodDurationSeconds =  (60/audioBPM * (1 + randBPM/100));
        NSLog(@"sign: %d, bpmvar %d, randbpm: %f, iis: %f",sign, bpmVariability,randBPM, periodDurationSeconds);
        
        CGFloat iisDurationSeconds = periodDurationSeconds - beatDurationSeconds;
        if (iisDurationSeconds > 0) {
            [NSThread sleepForTimeInterval:iisDurationSeconds];
        }
    }
    // if audioBPM is 0, do nothing
}



@end
