//
//  helper.h
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/12/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#ifndef Airplane_Shooter_helper_h
#define Airplane_Shooter_helper_h

// helper methods
static const CGFloat TiltConstant = 0.05;
static const uint8_t bulletCategory = 1;
static const uint8_t enemyCategory = 2;
static const uint8_t planeCategory = 3;

CGPoint shadowPosition(CGPoint planePosition)
{
    return CGPointMake(planePosition.x + 15.0, planePosition.y - 15.0);
}

CGPoint propellerPosition(CGPoint planePosition, CGSize planeSize, CGFloat offset)
{
    return CGPointMake(planePosition.x + offset, planePosition.y - 5.0 + (planeSize.height / 2));
}

CGPoint mac_propellerPosition(CGPoint planePosition, CGSize planeSize, CGFloat offset)
{
    return CGPointMake(planePosition.x + offset, planePosition.y - 2.0 + (planeSize.height / 2));
}

CGPoint smokePosition(CGPoint planePosition, CGSize planeSize, int idx)
{
    if (idx == 2) return CGPointMake(planePosition.x, planePosition.y - (planeSize.height / 2));
    
    CGFloat wing = (planeSize.width / 2) - 10.0;
    CGFloat offset = (idx == 0)? wing : -wing;
    return CGPointMake(planePosition.x + offset, planePosition.y);
}

int ixn_random(int from, int to)
{
    return arc4random_uniform(to - from) + from;
}

#endif
