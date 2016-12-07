//
//  SoundPlayer.h
//  OddBall
//
//  Created by Claudio Capobianco on 19/05/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SoundPlayer : NSObject  <AVAudioPlayerDelegate>
@property double rate;
@property (readonly) BOOL isPlaying;
@property NSTimeInterval currentTime;

-(BOOL)togglePlay;

@end
