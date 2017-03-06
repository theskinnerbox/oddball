//
//  ERPSettingsViewController.h
//  OddBall
//
//  Created by Claudio Capobianco on 22/05/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ERPMonitorSession.h"

@class ERPSettingsViewController;

@protocol ERPSettingsViewControllerDelegate
- (void)settingsViewControllerDidFinish:(ERPSettingsViewController *)controller;

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

@end

@interface ERPSettingsViewController : UITableViewController <ERPMonitorSession>

@property (weak, nonatomic) id <ERPSettingsViewControllerDelegate> delegate;

/* Actions */
- (IBAction)done:(id)sender;
- (IBAction)play:(id)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *playButton;

/* Labels */
@property (weak, nonatomic) IBOutlet UILabel *audioRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *audioRateVariabilityLabel;
@property (weak, nonatomic) IBOutlet UILabel *rareFreqLabel;
@property (weak, nonatomic) IBOutlet UILabel *commonFreqLabel;
@property (weak, nonatomic) IBOutlet UILabel *rareCommonRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *extTriggerPortLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

/* Sliders actions */
- (IBAction)rateSlider:(id)sender;
- (IBAction)audioRateVariabilitySlider:(id)sender;
- (IBAction)rareFreqSlider:(id)sender;
- (IBAction)commonFreqSlider:(id)sender;
- (IBAction)rareCommonSlider:(id)sender;

/* Sliders objects */
@property (weak, nonatomic) IBOutlet UISlider *rateSlider;
@property (weak, nonatomic) IBOutlet UISlider *audioRateVariabilitySlider;
@property (weak, nonatomic) IBOutlet UISlider *rareSlider;
@property (weak, nonatomic) IBOutlet UISlider *commonSlider;
@property (weak, nonatomic) IBOutlet UISlider *rareCommonRateSlider;

/* Switch actions */
- (IBAction)switchScreenButton:(id)sender;
- (IBAction)showTrigger:(id)sender;

/* Switch objects */
@property (weak, nonatomic) IBOutlet UISwitch *screenButtonSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *triggerSwitch;

/*@property (weak, nonatomic) IBOutlet UILabel *connectBT;*/


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


@end
