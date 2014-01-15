//
//  Airplane_ShooterTests.m
//  Airplane ShooterTests
//
//  Created by Ikhsan Assaat on 1/12/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IXNXboxDrumpad.h"

@interface Airplane_ShooterTests : XCTestCase

@end

@implementation Airplane_ShooterTests

- (void)testAllConnectedHID
{
    NSMutableArray *HIDs = [NSMutableArray new];
    struct hid_device_info *device_info, *devices;
    devices = hid_enumerate(0x0, 0x0);
    
    device_info = devices;
    while (device_info) {
        GameDevice *gameDevice = [GameDevice createWithHIDInfo:device_info];
        [HIDs addObject:gameDevice];
        
        device_info = device_info->next;
    }
    hid_free_enumeration(devices);
    
    NSLog(@"all connected HIDs : %@", HIDs);
    XCTAssertTrue([HIDs count] > 0, @"Connected HIDs should be more than one");
}

@end

