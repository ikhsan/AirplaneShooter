//
//  IXNViewController.m
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/11/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import "IXNViewController.h"

#import <SpriteKit/SpriteKit.h>
#import "IXNMainScene.h"

@implementation IXNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view = [[SKView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    SKView *view = (SKView *)self.view;
    view.showsFPS = YES;
    view.showsNodeCount = YES;
    view.showsDrawCount = YES;
    
    SKScene *scene = [IXNMainScene sceneWithSize:view.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // play!
    [view presentScene:scene];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
