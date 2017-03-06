//
//  ERPViewController.h
//  OddBall
//
//  Created by Claudio Capobianco on 15/04/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ERPSettingsViewController.h"
#import "ERPMonitorSession.h"


@interface ERPViewController : UIViewController <ERPSettingsViewControllerDelegate,ERPMonitorSession,UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIButton *oddClickButton;
@property (weak, nonatomic) IBOutlet UISwitch *monitoringSwitch;

- (IBAction)oddClick:(id)sender;
- (IBAction)audioSwitch:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *delayLabel;
@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *triggerCounterLabel;
@property (weak, nonatomic) IBOutlet UILabel *heartbeatCounterLabel;

@property CGFloat audioBPM;
@property CGFloat audioBPMVariability;
@property CGFloat rareFreq;
@property CGFloat commonFreq;
@property CGFloat rareCommonRate;
@property CGFloat beatDurationSeconds;
@property BOOL useTouchscreenButton;
@property NSUInteger extTriggerPort;
@property BOOL showTriggerInput;

@property BOOL enableSettingChange;
@property NSDate* startTimestamp;


@end
