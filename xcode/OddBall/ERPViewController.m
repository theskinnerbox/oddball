//
//  ERPViewController.m
//  OddBall
//
//  Created by Claudio Capobianco on 15/04/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//

#import "ERPViewController.h"
#import "ERPFileSharing.h"
//#import "SoundPlayer.h"
#import "ERPNetworkConnection.h"

static const CGFloat kBeatDurationSeconds = 0.2;
static const NSUInteger kPedalPort = 9090;
static NSString* kAlertSessionTitle = @"Start new session";
static NSString* kAlertButtonTitle = @"Button disabled";

@interface ERPViewController () <ERPNetworkConnectionDelegate> {
    //SoundPlayer* soundplayer;
    int clickCount;
    NSTimeInterval startDevice;
    //NSThread *soundPlayerThread;
    BOOL isPlaying;
    NSThread *networkThread;
    NSUInteger triggerCounter;
    NSUInteger heartbeatCounter;
}

@property BOOL isRareClicked;
@property BOOL isPlaying;
@property NSMutableArray* eventsArray;

@property ERPMonitorSession* session;
@property NSString* activityName;

@property ERPNetworkConnection* netObj;

@end

#pragma mark - View delegates

@implementation ERPViewController

@synthesize triggerCounterLabel;

@synthesize audioBPM;
@synthesize audioBPMVariability;
@synthesize rareFreq;
@synthesize commonFreq;
@synthesize rareCommonRate;
@synthesize beatDurationSeconds;
@synthesize useTouchscreenButton;
@synthesize pedalPort;
@synthesize enableSettingChange;
@synthesize showTriggerInput;


//@synthesize lastRareTime;
@synthesize isPlaying;
//@synthesize lastIsRare;
@synthesize isRareClicked;
@synthesize eventsArray;

@synthesize session;
@synthesize activityName;
@synthesize startTimestamp;

@synthesize netObj;

- (BOOL)canBecomeFirstResponder {
    return YES;
}

-(void)reset {
    isRareClicked = NO;
    clickCount = 0;
    startDevice = 0.0;
    self.delayLabel.text = [NSString stringWithFormat:@"Delay: ... (%d)",clickCount];
    self.activityLabel.text = [NSString stringWithFormat:@"..."];
    
    eventsArray = [[NSMutableArray alloc]init];
    
    self.session = nil;
}

-(void)resetTriggerCounters {
    // Trigger & Heartbeat counters
    triggerCounter = 0;
    heartbeatCounter = 0;
    if (showTriggerInput) {
        // trigger
        self.triggerCounterLabel.hidden = NO;
        self.triggerCounterLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)triggerCounter];
        // heartbeat
        self.heartbeatCounterLabel.hidden = NO;
        self.heartbeatCounterLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)heartbeatCounter];
    } else {
        self.triggerCounterLabel.hidden = YES;
        self.heartbeatCounterLabel.hidden = YES;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self reset];
    
    audioBPM = 40;
    audioBPMVariability = 10;
    rareFreq = 440;
    commonFreq = 220;
    rareCommonRate = 25;
    beatDurationSeconds = kBeatDurationSeconds;
    useTouchscreenButton = false;
    pedalPort = kPedalPort;
    enableSettingChange = YES;
    showTriggerInput = NO;
    
    //soundplayer = [[SoundPlayer alloc]init];
    
    // Touchscreen button
    //[[self oddClickButton] setEnabled:NO];
    if (useTouchscreenButton) {
        [[self oddClickButton] setAlpha:1.0];
    } else {
        [[self oddClickButton] setAlpha:0.4];
    }
    
    // Trigger counters
    [self resetTriggerCounters];
    
    
    // UDP connection to devices (e.g. pedal)
    netObj = [[ERPNetworkConnection alloc] initWithPort:pedalPort];
    assert(netObj != nil);
    netObj.delegate = self;
    [netObj start];
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Turn on remote control event delivery
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // Set itself as the first responder
    [self becomeFirstResponder];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button events
- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                NSLog(@"toggle\n");
                [self updateClickFromSource:@"headset"];
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                NSLog(@"prev\n");
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"next\n");
                break;
                
            default:
                break;
        }
    }
}



- (IBAction)oddClick:(id)sender {
    if (useTouchscreenButton) {
        [self updateClickFromSource:@"screen"];
    } else {
        [self alertButtonTextAction];
    }
}


- (IBAction)audioSwitch:(id)sender {
    UISwitch* sw = (UISwitch*)sender;
    
    if (sw.on) {
        [self alertTextAction];
    } else {
        [self stopMonitoring];
    }
    
    //[tonegen togglePlay];
    //[soundplayer togglePlay];
    
}

#pragma mark - Start & Stop
-(void)startMonitoring {
    if (useTouchscreenButton) {
        // appeareance first
        //[[self oddClickButton] setEnabled:YES];
        //[[self oddClickButton] setAlpha:1.0];
    }
    [self reset];
    
    //start monitoring
    self.session = [[ERPMonitorSession alloc]init];
    self.session.delegate = self;
    self.session.audioBPM = self.audioBPM;
    self.session.audioBPMVariability = self.audioBPMVariability;
    self.session.rareFreq = self.rareFreq;
    self.session.commonFreq = self.commonFreq;
    self.session.rareCommonRate = self.rareCommonRate;
    self.session.beatDurationSeconds = self.beatDurationSeconds;
    self.session.duration = ERP_DURATION_INFINITE;
    [[self session]start];
    
    isPlaying = YES;
    enableSettingChange = NO;
    startTimestamp = [NSDate date];
}

-(void)stopMonitoring {
    if (useTouchscreenButton) {
        // appeareance first
        //[[self oddClickButton] setEnabled:NO];
        //[[self oddClickButton] setAlpha:0.4];
    }
    [[self session]stop];
    
    [self saveEvents];
    isPlaying = NO;
    enableSettingChange = YES;
    
}

#pragma mark - Beat managing
-(void)beatRoutine:(ERPMonitorSession *)session {
    BOOL lastIsRare = [[self session]lastIsRare];
    if ((lastIsRare) && (isRareClicked == NO)) {
        NSLog(@"error click (miss)");
        
        NSDictionary* dict = [[NSDictionary alloc]initWithObjectsAndKeys:
                              @"errorClick",@"type",
                              @"missTarget",@"value",
                              [NSDate date], @"timestamp",
                              @"", @"note",
                              nil];
        [eventsArray addObject:dict];
    }
    isRareClicked = NO;
}




#pragma mark - Update click
-(void)newActivity:(NSString*)actName {
    if (isPlaying) {
        self.activityLabel.text = [NSString stringWithFormat:@"%@", actName];
        
        NSDictionary* dict = [[NSDictionary alloc]initWithObjectsAndKeys:
                              @"activityStart",@"type",
                              activityName,@"value",
                              [NSDate date], @"timestamp",
                              @"", @"note",
                              nil];
        [eventsArray addObject:dict];
    }
}

-(void)addHeader {
    // bpm
    NSDate* now = [NSDate date];
    NSNumber* value = [NSNumber numberWithFloat:audioBPM];
    NSDictionary* dict = [[NSDictionary alloc]initWithObjectsAndKeys:
                          @"bpm",@"type",
                          value,@"value",
                          now, @"timestamp",
                          @"", @"note",
                          nil];
    [eventsArray addObject:dict];
    
    // bpm variability
    value = [NSNumber numberWithFloat:audioBPMVariability];
    dict = [[NSDictionary alloc]initWithObjectsAndKeys:
            @"bpmVariability",@"type",
            value,@"value",
            now, @"timestamp",
            @"", @"note",
            nil];
    [eventsArray addObject:dict];
    
    // H freq
    value = [NSNumber numberWithFloat:rareFreq];
    dict = [[NSDictionary alloc]initWithObjectsAndKeys:
            @"rareStimulusHz",@"type",
            value,@"value",
            now, @"timestamp",
            @"", @"note",
            nil];
    [eventsArray addObject:dict];
    
    // L freq
    value = [NSNumber numberWithFloat:commonFreq];
    dict = [[NSDictionary alloc]initWithObjectsAndKeys:
            @"commonStimulusHz",@"type",
            value,@"value",
            now, @"timestamp",
            @"", @"note",
            nil];
    [eventsArray addObject:dict];
    
    // H/L rate
    value = [NSNumber numberWithFloat:rareCommonRate];
    dict = [[NSDictionary alloc]initWithObjectsAndKeys:
            @"rareOnCommonRate",@"type",
            value,@"value",
            now, @"timestamp",
            @"", @"note",
            nil];
    [eventsArray addObject:dict];
}

-(void)updateTriggerCounterLabel {
    if (showTriggerInput) {
        triggerCounter++;
        triggerCounter = (triggerCounter % 10);
        self.triggerCounterLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)triggerCounter];
    }
}

-(void)updateHeartbeatCounterLabel {
    if (showTriggerInput) {
        heartbeatCounter++;
        heartbeatCounter = (heartbeatCounter % 10);
        self.heartbeatCounterLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)heartbeatCounter];
    }
}


-(void)updateClickFromSource:(NSString*)sourceStr {
    clickCount++;
    
    [self updateTriggerCounterLabel];
    
    if (isPlaying) {
        BOOL lastIsRare = [[self session]lastIsRare];
        if (lastIsRare) {
            if (isRareClicked == NO) { // this is the first click on target
                isRareClicked = YES;
                NSDate* lastRareTime = [[self session]lastRareTime];
                NSTimeInterval delayF = - ([lastRareTime timeIntervalSinceNow]*1000);
                NSInteger delay = (int)delayF;
                
                NSLog(@"delay: %ld ms (%@)",(long)delay,lastRareTime);
                
                NSNumber* delayNum = [[NSNumber alloc]initWithInteger:delay];
                NSDictionary* dict = [[NSDictionary alloc]initWithObjectsAndKeys:
                                      @"targetClickDelayMs",@"type",
                                      delayNum,@"value",
                                      [NSDate date], @"timestamp",
                                      sourceStr, @"note",
                                      nil];
                [eventsArray addObject:dict];
                
                self.delayLabel.text = [NSString stringWithFormat:@"Delay: %ld ms (%d)",(long)delay,clickCount];
                
            } else {
                NSLog(@"info: target click repeated");
                
                NSDictionary* dict = [[NSDictionary alloc]initWithObjectsAndKeys:
                                      @"info",@"type",
                                      @"twiceOnTarget",@"value",
                                      [NSDate date], @"timestamp",
                                      sourceStr, @"note",
                                      nil];
                [eventsArray addObject:dict];
                
                self.delayLabel.text = [NSString stringWithFormat:@"Delay: --- ms (%d)",clickCount];
            }
        } else {
            NSLog(@"error click (standard)");
            
            NSDictionary* dict = [[NSDictionary alloc]initWithObjectsAndKeys:
                                  @"errorClick",@"type",
                                  @"clickOnStandard",@"value",
                                  [NSDate date], @"timestamp",
                                  sourceStr, @"note",
                                  nil];
            [eventsArray addObject:dict];
            
            self.delayLabel.text = [NSString stringWithFormat:@"Delay: --- ms (%d)",clickCount];
        }
    } else {
        self.delayLabel.text = [NSString stringWithFormat:@"Delay: ... (%d)",clickCount];
    }
}

-(NSString*)stringFromTimeInterval:(NSTimeInterval)time {
    int timeInt = (int)floor(time);
    int ss = (timeInt % 60);
    int mm = floor((timeInt % 3600)/60.0);
    int hh = floor(timeInt/3600.0);
    int rem = (int)(round((time-timeInt)*1000.0));
    return [NSString stringWithFormat:@"%02d:%02d:%02d,%03d",hh,mm,ss,rem];
}

-(void)saveEvents {
    NSMutableString* text = [[NSMutableString alloc]init];
    
    //Create a dateformatter for a custom timestamp representation
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString* dateStr = [formatter stringFromDate:self.startTimestamp];
    NSString* str = [NSString stringWithFormat:@"%@,localTimestamp\n",
                     dateStr];
    [text appendString:str];
    
    
    [formatter setDateFormat:@"HH:mm:ss"];
    for(NSDictionary* dict in eventsArray) {
        NSDate* eventDate = [dict objectForKey:@"timestamp"];
        NSTimeInterval diffTime = [eventDate timeIntervalSinceDate:self.startTimestamp];
        NSString* diffDateStr = [self stringFromTimeInterval:diffTime];
        NSLog(@"diffTime %@",diffDateStr);
        NSString* str = [NSString stringWithFormat:@"%@,%@,%@,%@\n",
                         diffDateStr,
                         [dict objectForKey:@"type"],
                         [dict objectForKey:@"value"],
                         [dict objectForKey:@"note"]];
        [text appendString:str];
    }
    NSString* deviceName = [[UIDevice currentDevice] name];
    // for filename, it's safer change : to -
    [formatter setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
    NSString* fileDateStr = [formatter stringFromDate:[NSDate date]];
    NSString* fileName = [NSString stringWithFormat:@"%@ %@ %@.txt",deviceName,activityName,fileDateStr];
    [ERPFileSharing exportText:text ToFile:fileName withForce:YES];
}





#pragma mark - Settings
- (void)settingsViewControllerDidFinish:(ERPSettingsViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    //NSLog(@"Main: BPM: %f", controller.audioBPM);
    
    self.audioBPM = controller.audioBPM;
    self.audioBPMVariability = controller.audioBPMVariability;
    self.rareFreq = controller.rareFreq;
    self.commonFreq = controller.commonFreq;
    self.rareCommonRate = controller.rareCommonRate;
    self.beatDurationSeconds = controller.beatDurationSeconds;
    self.useTouchscreenButton = controller.useTouchscreenButton;
    self.extTriggerPort = controller.extTriggerPort;
    self.showTriggerInput = controller.showTriggerInput;
    
    // Touchscreen button
    if (useTouchscreenButton) {
        [[self oddClickButton] setAlpha:1.0];
    } else {
        [[self oddClickButton] setAlpha:0.4];
    }
    
    [self resetTriggerCounters];
    
    // Sound player
    //[soundplayer setRate:controller.audioBPM];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showSettings"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark - Alert
// Session ID
- (void)alertTextAction
{
	// open an alert with two custom buttons
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kAlertSessionTitle message:@"Enter session ID:"
                                                   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString* titleStr = [actionSheet title];
    if ([titleStr compare:kAlertSessionTitle] == NSOrderedSame) {
        NSString* clickStr = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([clickStr compare:@"OK"] == NSOrderedSame) {
            
            NSString* str = [[actionSheet textFieldAtIndex:0] text];
            NSLog(@"Alert OK! text: %@", str);
            
            activityName = str;
            [self startMonitoring];
            [self newActivity:str];
            [self addHeader];
            
        } else {
            NSLog(@"Alert Cancel");
            [[self monitoringSwitch] setOn:NO];
        }
    }
    // else: button alert, do nothing
}

// Touch Button
- (void)alertButtonTextAction
{
	// open an alert with two custom buttons
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kAlertButtonTitle message:@"You can enable it on the settings panel"
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	alert.alertViewStyle = UIAlertViewStyleDefault;
    [alert show];
}


#pragma mark - Network delegate
- (void)connection:(ERPNetworkConnection *)conn didReceiveData:(NSData *)data fromAddress:(NSData *)addr {
    const char* b = [data bytes];
    if (b != nil) {
        if (b[0] == 'p') {
            [self updateClickFromSource:@"pedal"];
        } else {
            [self updateHeartbeatCounterLabel];
        }
    }
    
}

@end
