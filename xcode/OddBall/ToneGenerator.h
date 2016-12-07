//
//  ToneGenerator.h
//  ToneGenerator
//
//  Created by Claudio Capobianco on 18/05/13.
//
//

#import <Foundation/Foundation.h>

#import <AudioUnit/AudioUnit.h>

@interface ToneGenerator : NSObject {
AudioComponentInstance toneUnit;

@public
    
double frequency;
double sampleRate;
double theta;

}

- (BOOL)togglePlay;
- (void)stop;

@end
