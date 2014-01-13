//
//  Madcatz.m
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/13/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import "HIDJoystick.h"
#import "hidapi.h"

#define MAX_STR 1000

@interface HIDJoystick () {
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
    
    NSLog(@"listen to madcatz");
    dispatch_queue_t q = dispatch_queue_create("me.ikhsan.hid", NULL);
    dispatch_async(q, ^{
        int res;
        unsigned char buf[65];
        
        hid_set_nonblocking(c_device, 1);
        
        while (true) {
            res = hid_read(c_device, buf, 65);
            
            if (res <= 0) continue;
            
            if (buf[1] == 20 && buf[3] == 64) {
                [self eventIsFired:KeyEventPressedX];
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
            
            if (buf[1] == 20 && buf[2] == 0) {
                [self eventIsFired:KeyEventReleasedArrow];
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

@end
