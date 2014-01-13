//
//  Airplane_ShooterTests.m
//  Airplane ShooterTests
//
//  Created by Ikhsan Assaat on 1/12/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import <XCTest/XCTest.h>
#include <IOKit/hid/IOHIDLib.h>

#import "hidapi.h"

#define MAX_STR 255

@interface Airplane_ShooterTests : XCTestCase {
    int res;
	unsigned char buf[65];
	wchar_t wstr[MAX_STR];
	hid_device *madcatz;
    struct hid_device_info *madcatz_info;
}

@end

@implementation Airplane_ShooterTests

- (void)setUp
{
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    madcatz_info = hid_enumerate(0x0738, 0x9871);
    XCTAssertTrue(madcatz_info, @"Madcatz should be found");
    
    printf("Device Found\n  type: %04hx %04hx\n  path: %s\n  serial_number: %ls",
           madcatz_info->vendor_id, madcatz_info->product_id, madcatz_info->path, madcatz_info->serial_number);
    printf("\n");
    printf("  Manufacturer: %ls\n", madcatz_info->manufacturer_string);
    printf("  Product:      %ls\n", madcatz_info->product_string);
    printf("\n");
    
    madcatz = hid_open(0x0738, 0x9871, NULL);
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    hid_close(madcatz);
    [super tearDown];
}

- (void)testMadcatzHandle
{
    res = hid_get_serial_number_string(madcatz, wstr, MAX_STR);
    printf("\nSerial number: %ls\n\n", wstr);

    res = hid_get_product_string(madcatz, wstr, MAX_STR);
    printf("Product: %ls\n\n", wstr);
}
    
@end

