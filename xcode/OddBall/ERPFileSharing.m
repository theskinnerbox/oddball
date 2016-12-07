//
//  ERPFileSharing.m
//  OddBall
//
//  Created by Claudio Capobianco on 29/05/13.
//  Copyright (c) 2013 claudio. All rights reserved.
//

#import "ERPFileSharing.h"

@implementation ERPFileSharing

+ (BOOL)exportText:(NSString*)text ToFile:(NSString*)exportName withForce:(BOOL)force {
    
    //[self createDataPath];
    
    // Figure out destination name (in public docs dir)
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:exportName];
    
    // Check if file already exists (unless we force the write)
    if (!force && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return FALSE;
    }
    
    // Write to disk
    NSError *error;
    [text writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) {
        NSLog(@"Error: %@", [error userInfo]);
        return FALSE;
    }
    
    return TRUE;
    
}

+ (NSData*)importDataFromFile:(NSString *)importFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:importFile];
    return [[NSData alloc]initWithContentsOfFile:filePath];
}

@end
