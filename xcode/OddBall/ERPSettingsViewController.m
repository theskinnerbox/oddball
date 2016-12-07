//
//  ERPSettingsViewController.m
//  OddBall
//
//  Created by Claudio Capobianco on 22/05/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//

#import "ERPSettingsViewController.h"

static const NSString* versionString = @"1.3";
static const int toneSliderResolution = 50;

@interface ERPSettingsViewController ()
@property ERPMonitorSession* session;
@end

@implementation ERPSettingsViewController

@synthesize audioBPM;
@synthesize audioBPMVariability;
@synthesize rareFreq;
@synthesize commonFreq;
@synthesize rareCommonRate;
@synthesize beatDurationSeconds;
@synthesize useTouchscreenButton;
@synthesize pedalPort;
@synthesize showTriggerInput;
@synthesize enableSettingChange;

@synthesize session;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    enableSettingChange = [[self delegate]enableSettingChange];
    self.session = [[ERPMonitorSession alloc]init];
    self.session.delegate = self;
    
    audioBPM = [[self delegate]audioBPM];
    self.rateSlider.value = audioBPM;
    self.audioRateLabel.text = [NSString stringWithFormat:@"%d",(int)audioBPM];
    [self.rateSlider setEnabled:enableSettingChange];
    
    audioBPMVariability = [[self delegate]audioBPMVariability];
    self.audioRateVariabilitySlider.value = audioBPMVariability;
    self.audioRateVariabilityLabel.text = [NSString stringWithFormat:@"%d %%",(int)audioBPMVariability];
    [self.audioRateVariabilitySlider setEnabled:enableSettingChange];
    
    rareFreq = [[self delegate]rareFreq];
    self.rareSlider.value = rareFreq;
    self.rareFreqLabel.text = [NSString stringWithFormat:@"%d Hz",(int)rareFreq];
    [self.rareSlider setEnabled:enableSettingChange];
    
    commonFreq = [[self delegate]commonFreq];
    self.commonSlider.value = commonFreq;
    self.commonFreqLabel.text = [NSString stringWithFormat:@"%d Hz",(int)commonFreq];
    [self.commonSlider setEnabled:enableSettingChange];
    
    rareCommonRate = [[self delegate]rareCommonRate];
    self.rareCommonRateSlider.value = rareCommonRate;
    self.rareCommonRateLabel.text = [NSString stringWithFormat:@"%d %%",(int)rareCommonRate];
    [self.rareCommonRateSlider setEnabled:enableSettingChange];
    
    [self.playButton setEnabled:enableSettingChange];
    
    self.beatDurationSeconds = self.delegate.beatDurationSeconds;
    
    self.useTouchscreenButton = self.delegate.useTouchscreenButton;
    [self.screenButtonSwitch setOn:self.useTouchscreenButton animated:YES];
    
    self.pedalPort = self.delegate.pedalPort;
    self.pedalPortLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.delegate.pedalPort];
    
    self.showTriggerInput = self.delegate.showTriggerInput;
    [self.triggerSwitch setOn:self.showTriggerInput animated:YES];
    
    self.versionLabel.text = [NSString stringWithFormat:@"%@",versionString];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)rateSlider:(id)sender {
    UISlider* sl = (UISlider*)sender;
    float value = [sl value];
    value = round(value*toneSliderResolution)/toneSliderResolution;
    // NSLog(@"audio rate: %01f",value);
    self.audioRateLabel.text = [NSString stringWithFormat:@"%d",(int)value];
    audioBPM = value;
    
    self.session.audioBPM = audioBPM;
    
    //        // test session
    //        if (self.session.isPlaying == NO) {
    //            self.session.audioBPMVariability = 0;
    //            self.session.rareFreq = 0;
    //            self.session.commonFreq = self.commonFreq;
    //            self.session.rareCommonRate = 0; // always common
    //            self.session.beatDurationSeconds = beatDurationSeconds;
    //            self.session.duration = 60/audioBPM * 4; // play 4 beat
    //            [self.session start];
    //        } else {
    //            [self.session update];
    //        }
}

- (IBAction)audioRateVariabilitySlider:(id)sender {
    UISlider* sl = (UISlider*)sender;
    float value = [sl value];
    audioBPMVariability = value;
    self.audioRateVariabilityLabel.text = [NSString stringWithFormat:@"%d %%",(int)value];// test session
    
    self.session.audioBPMVariability = audioBPMVariability;
}

- (IBAction)rareFreqSlider:(id)sender {
    UISlider* sl = (UISlider*)sender;
    float value = [sl value];
    value = roundf(value/toneSliderResolution)*toneSliderResolution;
    [sl setValue:value];
    rareFreq = value;
    self.rareFreqLabel.text = [NSString stringWithFormat:@"%d Hz",(int)value];
    
    self.session.rareFreq = self.rareFreq;
    
    // test session
    if (self.session.isPlaying == NO) {
        // start a test session
        self.session.audioBPM = ERP_BPM_PLAY_COUNTINUOSLY;
        self.session.audioBPMVariability = 0;
        self.session.commonFreq = 0;
        self.session.rareCommonRate = 100; // always rare
        self.session.beatDurationSeconds = 0.6;
        self.session.duration = 0.1; // less than beat duration seconds, only one beep
        [self.session start];
    } else if (self.session.audioBPM == ERP_BPM_PLAY_COUNTINUOSLY) {
        // we're in single beat demo, update the test session
        [self.session update];
    } else {
        // regular session, do nothing
    }
}

- (IBAction)commonFreqSlider:(id)sender {
    UISlider* sl = (UISlider*)sender;
    float value = [sl value];
    value = roundf(value/toneSliderResolution)*toneSliderResolution;
    [sl setValue:value];
    commonFreq = value;
    self.commonFreqLabel.text = [NSString stringWithFormat:@"%d Hz",(int)value];
    
    self.session.commonFreq = self.commonFreq;
    
    // test session
    if (self.session.isPlaying == NO) {
        // start a test session
        self.session.audioBPM = ERP_BPM_PLAY_COUNTINUOSLY;
        self.session.audioBPMVariability = 0;
        self.session.rareFreq = 0;
        self.session.rareCommonRate = 0; // always standard
        self.session.beatDurationSeconds = 0.6;
        self.session.duration = 0.1; // less than beat duration seconds, only one beep
        [self.session start];
    } else if (self.session.audioBPM == ERP_BPM_PLAY_COUNTINUOSLY) {
        // we're in single beat demo, update the test session
        [self.session update];
    } else {
        // regular session, do nothing
    }
}

- (IBAction)rareCommonSlider:(id)sender {
    UISlider* sl = (UISlider*)sender;
    float value = [sl value];
    rareCommonRate = value;
    self.rareCommonRateLabel.text = [NSString stringWithFormat:@"%d %%",(int)value];
    
    self.session.rareCommonRate = rareCommonRate;
}

- (IBAction)switchScreenButton:(id)sender {
    UISwitch* sw = (UISwitch*)sender;
    self.useTouchscreenButton = sw.on;
}

- (IBAction)showTrigger:(id)sender {
    UISwitch* sw = (UISwitch*)sender;
    self.showTriggerInput = sw.on;
}


- (IBAction)done:(id)sender
{
    [self.session stop];
    [self.delegate settingsViewControllerDidFinish:self];
}

- (IBAction)play:(id)sender {
    if (self.session.isPlaying == NO) {
        self.session.audioBPM = self.audioBPM;
        self.session.audioBPMVariability = self.audioBPMVariability;
        self.session.rareFreq = self.rareFreq;
        self.session.commonFreq = self.commonFreq;
        self.session.rareCommonRate = self.rareCommonRate;
        self.session.beatDurationSeconds = self.beatDurationSeconds;
        self.session.duration = ERP_DURATION_INFINITE;
        
        [self.session start];
        self.playButton.title = @"Pause";
    } else {
        [self.session stop];
        self.playButton.title = @"Play";
    }
}

#pragma mark - Monitor delegate method

-(void)beatRoutine:(ERPMonitorSession *)session {
    return;
}



@end
