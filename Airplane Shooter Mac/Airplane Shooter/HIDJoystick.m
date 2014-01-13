//
//  Madcatz.m
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/13/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import "HIDJoystick.h"
#import "hidapi.h"

typedef enum {
    LEDStatusAllOff = 0x00,
    LEDStatusAllBlink = 0x01,
    LEDStatusFlashOn1 = 0x02,
    LEDStatusFlashOn2 = 0x03,
    LEDStatusFlashOn3 = 0x04,
    LEDStatusFlashOn4 = 0x05,
    LEDStatusOn1 = 0x06,
    LEDStatusOn2 = 0x07,
    LEDStatusOn3 = 0x08,
    LEDStatusOn4 = 0x09,
    LEDStatusRotating = 0x0a,
    LEDStatusCurrentBlink = 0x0b,
    LEDStatusSlowBlink = 0x0c,
    LEDStatusAlternating = 0x0d
} LEDStatus;

@interface HIDJoystick () {
    struct hid_device_info *c_device_info;
    hid_device *c_device;
}

@end


@implementation HIDJoystick

+ (instancetype)createWithDelegate:(id <HIDJoystickDelegate>)delegate
{
    return [[HIDJoystick alloc] initWithDelegate:delegate];
}

- (instancetype)initWithDelegate:(id <HIDJoystickDelegate>)delegate
{
    if (!(self = [super init])) return nil;
    
    c_device_info = hid_enumerate(0x0738, 0x9871);
    self.delegate = delegate;
    
    return self;
}

+ (BOOL)isConnected
{
    hid_device *a_device = hid_open(0x0738, 0x9871, NULL);
    BOOL connected = (a_device != NULL);
    hid_close(a_device);
    return connected;
}

- (void)listen
{
    // HID API
    c_device = hid_open(0x0738, 0x9871, NULL);
    if (c_device == NULL) return;
    
    [self ledEvent:LEDStatusAllBlink];
    
    dispatch_queue_t q = dispatch_queue_create("me.ikhsan.hid", NULL);
    dispatch_async(q, ^{
        int res;
        unsigned char buf[65];
        
        hid_set_nonblocking(c_device, 1);
        
        while (true) {
            res = hid_read(c_device, buf, 65);
            
            if (res <= 0) continue;
            
//            printf("%d %d %d\n", buf[1], buf[2], buf[3]);
            
            if (buf[1] == 20 && buf[3] == 64) {
                [self eventIsFired:KeyEventPressedX];
            }
            
            if (buf[1] == 20 && buf[3] == 128) {
                [self eventIsFired:KeyEventPressedY];
            }
            
            if (buf[1] == 20 && buf[3] == 16) {
                [self eventIsFired:KeyEventPressedA];
            }
            
            if (buf[1] == 20 && buf[3] == 32) {
                [self eventIsFired:KeyEventPressedB];
            }
            
            if (buf[1] == 20 && buf[3] == 1) {
                [self eventIsFired:KeyEventPressedKick];
            }
            
            if (buf[1] == 20 && buf[3] == 4) {
                [self eventIsFired:KeyEventPressedXBOX];
            }
                        
            if (buf[1] == 20 && buf[2] == 1) {
                [self eventIsFired:KeyEventPressedArrowUp];
            }
            
            if (buf[1] == 20 && buf[2] == 8) {
                [self eventIsFired:KeyEventPressedArrowRight];
            }
            
            if (buf[1] == 20 && buf[2] == 2) {
                [self eventIsFired:KeyEventPressedArrowDown];
            }
            
            if (buf[1] == 20 && buf[2] == 4) {
                [self eventIsFired:KeyEventPressedArrowLeft];
            }
            
            if (buf[1] == 20 && buf[2] == 0 && buf[3] == 0) {
                [self eventIsFired:KeyEventReleased];
            }
        }
    });
}

- (void)eventIsFired:(KeyEvent)event
{
    if (!self.delegate) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate hid:self keyEvent:event];
    });
}

- (void)ledEvent:(LEDStatus)status
{
    // http://www.lastrayofhope.com/2009/06/26/athena-xbox-360-pad-and-mac-os-x-cont/#codesyntax_2
    const unsigned char kReportType = 0x01;
	const unsigned char kReportSize = 0x03;
    const unsigned char kReportData[kReportSize] = {kReportType, kReportSize, status};
    
    hid_write(c_device, kReportData, kReportSize);
}

- (void)led:(LEDEvent)eventType
{
    if (eventType == LEDEventFlash) {
        [self ledEvent:LEDStatusOn1];
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self ledEvent:LEDStatusAllOff];
        });
    } else if (eventType == LEDEventBurst) {
        for (int i = 0; i < 4; i++) {
            [self ledEvent:(LEDStatusOn1 + i)];
            double delayInSeconds = 1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self ledEvent:LEDStatusAllOff];
            });
        }
    } else if (eventType == LEDEventAllBlinking) {
        [self ledEvent:LEDStatusAllBlink];
    }
}

@end
