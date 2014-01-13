//
//  MainWindow.h
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/12/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainWindow : NSWindow

@property (nonatomic, strong) IBOutlet NSView *mainView;

- (void)start;

@end
