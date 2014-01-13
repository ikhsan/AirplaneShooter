//
//  Madcatz.h
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/13/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    KeyEventPressedArrowUp = 1,
    KeyEventPressedArrowRight,
    KeyEventPressedArrowDown,
    KeyEventPressedArrowLeft,
    KeyEventPressedX,
    KeyEventPressedY,
    KeyEventPressedA,
    KeyEventPressedB,
    KeyEventPressedKick,
    KeyEventPressedBack,
    KeyEventPressedXBOX,
    KeyEventPressedStart,
    KeyEventReleased
} KeyEvent;

typedef enum {
    LEDEventFlash,
    LEDEventBurst,
    LEDEventAllBlinking
} LEDEvent;

@class HIDJoystick;

@protocol HIDJoystickDelegate <NSObject>

@optional
- (void)hid:(HIDJoystick *)hid keyEvent:(KeyEvent)event;

@end

@interface HIDJoystick : NSObject

@property (nonatomic, assign) id<HIDJoystickDelegate> delegate;

+ (BOOL)isConnected;

+ (instancetype)createWithDelegate:(id <HIDJoystickDelegate>)delegate;
- (void)listen;

- (void)led:(LEDEvent)eventType;

@end
