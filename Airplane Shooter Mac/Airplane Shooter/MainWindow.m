//
//  MainWindow.m
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/12/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import "MainWindow.h"
#import <SpriteKit/SpriteKit.h>
#import "MainScene.h"

@implementation MainWindow

- (void)start
{
    SKView *view = (SKView *)self.mainView;
    view.showsFPS = YES;
    view.showsNodeCount = YES;
    view.showsDrawCount = YES;
    
    MainScene *mainScene = [MainScene sceneWithSize:self.mainView.bounds.size];
    mainScene.scaleMode = SKSceneScaleModeAspectFill;
    
    // play!
    [view presentScene:mainScene];
}

@end
