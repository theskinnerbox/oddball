//
//  SoundPlayer.m
//  OddBall
//
//  Created by Claudio Capobianco on 19/05/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//

#import "SoundPlayer.h"

@interface SoundPlayer () {
    AVAudioPlayer* appSoundPlayer;  
    NSURL* soundFileURL;
    BOOL playing;
}

@end

@implementation SoundPlayer
@synthesize rate = _rate;
@synthesize isPlaying = _isPlaying;
@synthesize currentTime = _currentTime;

-(double)rate {
    return [appSoundPlayer rate];
}

-(void)setRate:(double)rate {
    [appSoundPlayer setRate:rate];
}

-(NSTimeInterval)currentTime {
    return [appSoundPlayer rate];
}

-(void)setCurrentTime:(NSTimeInterval)currentTime {
    [appSoundPlayer setCurrentTime:currentTime];
}

-(BOOL)isPlaying {
    return [appSoundPlayer isPlaying];
}

-(id)init {
    self = [super init];
    [self setupApplicationAudio];
    playing = NO;
    return self;
}

//    UISwitch* sw = (UISwitch*)sender;

-(BOOL)togglePlay {

    if (playing) {
        [appSoundPlayer stop];
        [appSoundPlayer setCurrentTime:0.0];
    } else {
        [appSoundPlayer play];
    }
    playing = !playing;
    
    return playing;
}

#pragma mark - Setup audio

- (void) setupApplicationAudio {
	
	// Gets the file system path to the sound to play.
	NSString *soundFilePath = [[NSBundle mainBundle]	pathForResource:	@"metronome60bpm"
                                                              ofType:				@"wav"];
    
	// Converts the sound's file path to an NSURL object
	NSURL *newURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	soundFileURL = newURL;
    
	// Registers this class as the delegate of the audio session.
	[[AVAudioSession sharedInstance] setDelegate: self];
	
	// Activates the audio session.
	NSError *activationError = nil;
	[[AVAudioSession sharedInstance] setActive: YES error: &activationError];
    
	// Instantiates the AVAudioPlayer object, initializing it with the sound
	AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: soundFileURL error: nil];
	appSoundPlayer = newPlayer;
	
	// "Preparing to play" attaches to the audio hardware and ensures that playback
	//		starts quickly when the user taps Play
	[appSoundPlayer prepareToPlay];
	[appSoundPlayer setVolume: 1.0];
	[appSoundPlayer setDelegate: self];
    
    [appSoundPlayer setNumberOfLoops: -1]; // infinite
    
    [appSoundPlayer setEnableRate: YES];
    [appSoundPlayer setRate: 1.0];  // from 0.5 to 2.0, 1.0 is normal speed
}

#pragma mark - AV Foundation delegate methods____________

- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *) appSoundPlayer successfully: (BOOL) flag {
    
	NSLog(@"audioPlayerDidFinishPlaying\n");
}

- (void) audioPlayerBeginInterruption: player {
    
	NSLog(@"audioPlayerBeginInterruption\n");
}

- (void) audioPlayerEndInterruption: player {
    
    NSLog(@"audioPlayerEndInterruption\n");
}

@end
