//
//  ERPFileSharing.h
//  OddBall
//
//  Created by Claudio Capobianco on 29/05/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//  The code is an excerpt and adaptation of the following project:
//    http://www.raywenderlich.com/1948/how-integrate-itunes-file-sharing-with-your-ios-app
//
// USAGE:
// Enable "Application supports iTunes file sharing" (UIFileSharingEnabled) in your info.plist.
//
// Sample code:
//
//  NSString* exportFileName = @"from_ios_to_mac.txt";
//  if ([ERPFileSharing exportToFile:exportFileName withForce:YES] == YES) {
//      NSLog(@"%@: export OK %d",exportFileName);
//  }
//
//  NSString* importFileName = @"from_mac_to_ios.txt";
//  NSData* data = [ERPFileSharing importFromFile:importFileName];
//  if (data != nil) {
//      NSLog(@"%@: import OK, len %d",importFileName,[data length]);
//  }


#import <Foundation/Foundation.h>

@interface ERPFileSharing : NSObject

+ (BOOL)exportText:(NSString*)text ToFile:(NSString*)exportName withForce:(BOOL)force;

+ (NSData*)importDataFromFile:(NSString *)importFile;

@end
