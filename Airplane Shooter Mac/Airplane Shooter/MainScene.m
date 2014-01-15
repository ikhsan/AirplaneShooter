//
//  MainScene.m
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/12/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import "MainScene.h"
#import "helper.h"
#import "IXNXboxDrumpad.h"

const static CGFloat PlaneScale = 0.6;
const static CGFloat PlaneSpeed = 0.2;

@interface MainScene () <SKPhysicsContactDelegate, IXNXboxDrumpadDelegate>

@property (nonatomic) CGRect screenRect;
@property (nonatomic) double currentMaxAccelX;
@property (nonatomic) double currentMaxAccelY;

@property (strong, nonatomic) SKSpriteNode *plane;
@property (strong, nonatomic) SKSpriteNode *planeShadow;
@property (strong, nonatomic) SKSpriteNode *propeller;
@property (strong, nonatomic) NSArray *smokeTrails;

@property (strong, nonatomic) NSMutableArray *explosionTextures;
@property (strong, nonatomic) NSMutableArray *cloudsTextures;

@property (strong, nonatomic) IXNXboxDrumpad *xboxDrumpad;

@end

@implementation MainScene

- (id)initWithSize:(CGSize)size
{
    if (!(self = [super initWithSize:size])) return nil;
    
    // init several sizes used in all scene
    self.screenRect = CGRectMake(0, 0, size.width, size.height);
    
    // adding the background
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"airPlanesBackground"];
    background.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
    background.scale = (self.screenRect.size.height / 1024.0);
    [self addChild:background];
    
    // add our plane
    [self addPlaneToScene];
    
    // add environments (enemies & clouds)
    [self addEnvironments];
    
    // use the first gamepad that's found, connect, and listen to it
    NSArray *pads = [IXNXboxDrumpad connectedGamepads];
    if (pads.count > 0) {
        GameDevice *firstDevice = [IXNXboxDrumpad connectedGamepads][0];
        IXNXboxDrumpad *thePad = [IXNXboxDrumpad drumpadWithDevice:firstDevice];
        thePad.delegate = self;
        self.xboxDrumpad = thePad;
        
        [self.xboxDrumpad triggerLEDEvent:LEDTriggerAllBlink];
        
        [self.xboxDrumpad listen];
    }
    
    return self;
}

- (void)addPlaneToScene
{
    // adding the airplane
    [self addChild:self.plane];
    
    // adding the shadow
    [self addChild:self.planeShadow];
    
    // adding the airplane's propeller
    [self addChild:self.propeller];
    
    // adding the smoke trails
    for (SKNode *node in self.smokeTrails)
        [self addChild:node];
    
    // add propeller sound
    SKAction *propellerSound = [SKAction playSoundFileNamed:@"propeller.wav" waitForCompletion:YES];
    [self.plane runAction:[SKAction repeatActionForever:propellerSound]];
}

- (void)addEnvironments
{
    // add explosions
    self.explosionTextures = [NSMutableArray new];
    for (int i = 6; i <= 11; i++) {
        SKTexture *texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"%d.png", i]];
        [self.explosionTextures addObject:texture];
    }
    
    // add clouds
    self.cloudsTextures = [NSMutableArray new];
    for (int i = 1; i <= 4; i++) {
        NSString *name = [NSString stringWithFormat:@"cloud%d.png", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:name];
        [self.cloudsTextures addObject:texture];
    }
    
    // physics
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    self.physicsWorld.contactDelegate = self;
    
    //  add enemies and clouds
    SKAction *wait = [SKAction waitForDuration:1];
    SKAction *callEnemies = [SKAction runBlock:^{
        [self createEnemies];
        [self createClouds];
    }];
    SKAction *updateEnvironment = [SKAction sequence:@[wait, callEnemies]];
    [self runAction:[SKAction repeatActionForever:updateEnvironment]];
}

#pragma mark - Setter Methods

- (SKSpriteNode *)nodeWithImageName:(NSString *)imageName scale:(CGFloat)scale  position:(CGPoint)pos zPosition:(NSInteger)zPosition
{
    SKSpriteNode *node = [SKSpriteNode spriteNodeWithImageNamed:imageName];
    node.scale = scale;
    node.zPosition = zPosition;
    node.position = pos;
    
    return node;
}

- (SKSpriteNode *)plane
{
    if (!_plane)
    {
        _plane = [self nodeWithImageName:@"PLANE 8 N" scale:PlaneScale position:CGPointZero zPosition:3];
        _plane.position = CGPointMake(CGRectGetWidth(_screenRect) / 2, 15 + (_plane.size.height / 2));
    }
    
    return _plane;
}

- (SKSpriteNode *)planeShadow
{
    if (!_planeShadow)
    {
        CGPoint p = shadowPosition(self.plane.position);
        _planeShadow = [self nodeWithImageName:@"PLANE 8 SHADOW" scale:PlaneScale position:p zPosition:1];
    }
    
    return _planeShadow;
}

- (SKSpriteNode *)propeller
{
    if (!_propeller)
    {
        CGPoint p = mac_propellerPosition(self.plane.position, self.plane.size, 0);
        
        _propeller = [self nodeWithImageName:@"PLANE PROPELLER 1" scale:.2 position:p zPosition:1];
        
        NSArray *textures = @[[SKTexture textureWithImageNamed:@"PLANE PROPELLER 1"], [SKTexture textureWithImageNamed:@"PLANE PROPELLER 2"]];
        
        SKAction *spin = [SKAction animateWithTextures:textures timePerFrame:.1];
        SKAction *spinForever = [SKAction repeatActionForever:spin];
        [_propeller runAction:spinForever];
    }
    
    return _propeller;
}

- (NSArray *)smokeTrails
{
    if (!_smokeTrails)
    {
        NSString *smokePath = [[NSBundle mainBundle] pathForResource:@"trail" ofType:@"sks"];
        
        _smokeTrails = @[[NSKeyedUnarchiver unarchiveObjectWithFile:smokePath],
                         [NSKeyedUnarchiver unarchiveObjectWithFile:smokePath],
                         [NSKeyedUnarchiver unarchiveObjectWithFile:smokePath]];
        
        [_smokeTrails enumerateObjectsUsingBlock:^(SKNode *node, NSUInteger idx, BOOL *stop) {
            node.position = smokePosition(self.plane.position, self.plane.size, idx);
            node.zPosition = 2;
        }];
    }
    
    return _smokeTrails;
}

#pragma mark - Motion methods

- (void)setPlanesPosition:(CGPoint)p
{
    self.plane.position = p;
    
    self.planeShadow.position = shadowPosition(self.plane.position);
    
    CGFloat offset = 0;
    if (self.currentMaxAccelX > TiltConstant)
        offset = 5.0;
    else if (self.currentMaxAccelX < -TiltConstant)
        offset = -5.0;
    
    self.propeller.position = mac_propellerPosition(self.plane.position, self.plane.size, offset);
    
    [self.smokeTrails enumerateObjectsUsingBlock:^(SKNode *node, NSUInteger idx, BOOL *stop) {
        node.position = smokePosition(self.plane.position, self.plane.size, idx);
    }];
}

#pragma mark - Environments

- (void)createEnemies
{
    if (arc4random_uniform(2) == 0) return;
    
    // make an enemy
    NSString *enemyName = (arc4random_uniform(2) == 0)? @"PLANE 1 N" : @"PLANE 2 N";
    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithImageNamed:enemyName];
    enemy.scale = PlaneScale;
    enemy.zPosition = 4;
    
    enemy.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:enemy.size];
    enemy.physicsBody.dynamic = YES;
    enemy.physicsBody.categoryBitMask = enemyCategory;
    enemy.physicsBody.contactTestBitMask = bulletCategory;
    enemy.physicsBody.collisionBitMask = 0;
    
    // make the path
    CGPathRef path = [self randomPathForSize:enemy.size];
    SKAction *planeDestroy = [SKAction followPath:path asOffset:NO orientToPath:YES duration:5];
    SKAction *remove = [SKAction removeFromParent];
    [enemy runAction:[SKAction sequence:@[planeDestroy, remove]]];
    
    [self addChild:enemy];
}

- (CGPathRef)randomPathForSize:(CGSize)size
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat height = CGRectGetHeight(self.screenRect);
    CGFloat width = CGRectGetWidth(self.screenRect);
    
    CGPoint p1 = CGPointMake(ixn_random(size.width, width - (size.width * 2)), height + 80.0);
    CGPoint p2 = CGPointMake(ixn_random(size.width, width - (size.width * 2)), ixn_random(size.height, width / 2));
    CGPoint p3 = CGPointMake(ixn_random(0, p2.y), ixn_random(width / 2, width - size.height));
    CGPoint p4 = CGPointMake(ixn_random(size.width, width - (size.width * 2)), -100.0);
    
    CGPathMoveToPoint(path, NULL, p1.x, p1.y);
    CGPathAddCurveToPoint(path, NULL, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y);
    
    return path;
}

- (void)createClouds
{
    if (arc4random_uniform(2) == 0) return;
    
    int whichCloud = ixn_random(0, 3);
    SKSpriteNode *cloud = [SKSpriteNode spriteNodeWithTexture:self.cloudsTextures[whichCloud]];
    
    int randomYAxix = ixn_random(0, self.screenRect.size.height);
    cloud.position = CGPointMake(self.screenRect.size.height + cloud.size.height / 2, randomYAxix);
    cloud.zPosition = ixn_random(0, 5);
    cloud.scale = (CGFloat)ixn_random(5, 10) * 0.1;
    int randomTimeCloud = ixn_random(9, 19);
    
    SKAction *move =[SKAction moveTo:CGPointMake(-cloud.size.height, randomYAxix) duration:randomTimeCloud];
    SKAction *remove = [SKAction removeFromParent];
    [cloud runAction:[SKAction sequence:@[move,remove]]];
    [self addChild:cloud];
}

#pragma mark - Collision detection delegate methods

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if ((firstBody.categoryBitMask & bulletCategory) != 0)
    {
        // add explosion
        SKSpriteNode *explosion = [SKSpriteNode spriteNodeWithTexture:self.explosionTextures[0]];
        explosion.zPosition = 1;
        explosion.scale = PlaneScale;
        explosion.position = contact.bodyA.node.position;
        [self addChild:explosion];
        
        SKAction *explosionAction = [SKAction animateWithTextures:self.explosionTextures timePerFrame:0.06];
        SKAction *remove = [SKAction removeFromParent];
        SKAction *explodeSound = [SKAction playSoundFileNamed:@"explosion.wav" waitForCompletion:NO];
        [explosion runAction:[SKAction sequence:@[explodeSound, explosionAction,remove]]];
        
        if (self.xboxDrumpad) {
            [self.xboxDrumpad triggerLEDEvent:LEDTriggerOn1];
            [self.xboxDrumpad triggerLEDEvent:LEDTriggerOn2];
            [self.xboxDrumpad triggerLEDEvent:LEDTriggerOn4];
            [self.xboxDrumpad triggerLEDEvent:LEDTriggerOn3];
            [self.xboxDrumpad triggerLEDEvent:LEDTriggerAllOff];
        }
        
        // remove from scene
        SKNode *projectile = (contact.bodyA.categoryBitMask & bulletCategory) ? contact.bodyA.node : contact.bodyB.node;
        SKNode *enemy = (contact.bodyA.categoryBitMask & bulletCategory) ? contact.bodyB.node : contact.bodyA.node;
        [projectile runAction:[SKAction removeFromParent]];
        [enemy runAction:[SKAction removeFromParent]];
    }
}

#pragma mark - Interaction methods

- (void)keyDown:(NSEvent *)theEvent
{
    if ([theEvent modifierFlags] & NSNumericPadKeyMask)
    {
        NSString *theArrow = [theEvent charactersIgnoringModifiers];
        unichar keyChar = 0;
        if ([theArrow length] == 0) return; // reject dead keys
        
        if ([theArrow length] == 1) {
            keyChar = [theArrow characterAtIndex:0];
            if (keyChar == NSLeftArrowFunctionKey) {
                self.currentMaxAccelX = -PlaneSpeed;
                return;
            }
            if (keyChar == NSRightArrowFunctionKey) {
                self.currentMaxAccelX = PlaneSpeed;
                return;
            }
            if (keyChar == NSUpArrowFunctionKey) {
                self.currentMaxAccelY = PlaneSpeed;
                return;
            }
            if (keyChar == NSDownArrowFunctionKey) {
                self.currentMaxAccelY = -PlaneSpeed;
                return;
            }
        }
    }
    
    if ([theEvent modifierFlags] & 256) //space bar
    {
        [self planeTargetFire];
    }
    
    [super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
    if ([theEvent modifierFlags] & NSNumericPadKeyMask)
    {
        NSString *theArrow = [theEvent charactersIgnoringModifiers];
        unichar keyChar = 0;
        if ([theArrow length] == 0) return; // reject dead keys
        
        if ([theArrow length] == 1) {
            keyChar = [theArrow characterAtIndex:0];
            if (keyChar == NSLeftArrowFunctionKey) {
                self.currentMaxAccelX = 0;
                return;
            }
            if (keyChar == NSRightArrowFunctionKey) {
                self.currentMaxAccelX = 0;
                return;
            }
            if (keyChar == NSUpArrowFunctionKey) {
                self.currentMaxAccelY = 0;
                return;
            }
            if (keyChar == NSDownArrowFunctionKey) {
                self.currentMaxAccelY = 0;
                return;
            }
        }
    }
    [super keyUp:theEvent];
}

- (void)planeTargetFire
{
    CGPoint location = self.plane.position;
    
    SKSpriteNode *bullet = [SKSpriteNode spriteNodeWithImageNamed:@"B 2.png"];
    bullet.position = CGPointMake(location.x, location.y + (self.plane.size.height / 2));
    bullet.zPosition = 1;
    bullet.scale = 0.8;
    
    bullet.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bullet.size];
    bullet.physicsBody.dynamic = NO;
    bullet.physicsBody.categoryBitMask = bulletCategory;
    bullet.physicsBody.contactTestBitMask = enemyCategory;
    bullet.physicsBody.collisionBitMask = 0;
    
    SKAction *action = [SKAction moveToY:self.frame.size.height + bullet.size.height duration:2];
    SKAction *remove = [SKAction removeFromParent];
    SKAction *gunSound = [SKAction playSoundFileNamed:@"gun.wav" waitForCompletion:NO];
    [bullet runAction:[SKAction sequence:@[gunSound, action, remove]]];
    
    if (self.xboxDrumpad) {
        [self.xboxDrumpad triggerLEDEvent:LEDTriggerOn1];
        [self.xboxDrumpad triggerLEDEvent:LEDTriggerAllOff];
    }
    
    [self addChild:bullet];
}

- (void)update:(CFTimeInterval)currentTime
{
    float maxX = CGRectGetWidth(self.screenRect) - (self.plane.size.width / 2);
    float minX = (self.plane.size.width / 2);
    
    float maxY = CGRectGetHeight(self.screenRect) - (self.plane.size.height / 2);
    float minY = (self.plane.size.height / 2);
    
    float newX = 0;
    float newY = 0;
    
    if (self.currentMaxAccelX > TiltConstant)
    {
        self.plane.texture = [SKTexture textureWithImageNamed:@"PLANE 8 R.png"];
    }
    else if (self.currentMaxAccelX < -TiltConstant)
    {
        self.plane.texture = [SKTexture textureWithImageNamed:@"PLANE 8 L.png"];
    }
    else
    {
        self.plane.texture = [SKTexture textureWithImageNamed:@"PLANE 8 N.png"];
    }
    
    newX = self.currentMaxAccelX * 10;
    newY = 0.2 + self.currentMaxAccelY * 10;
    
    newX = MIN(MAX(newX+_plane.position.x,minX),maxX);
    newY = MIN(MAX(newY+_plane.position.y,minY),maxY);
    [self setPlanesPosition:CGPointMake(newX, newY)];
}

#pragma mark - XBOX Drum Controller Delegate

- (void)xboxDrumpad:(IXNXboxDrumpad *)drumpad keyEventButton:(KeyEventButton)buttonEvent
{
    switch (buttonEvent) {
        case KeyEventPressedArrowUp:
            self.currentMaxAccelY = PlaneSpeed;
            break;
        case KeyEventPressedArrowRight:
            self.currentMaxAccelX = PlaneSpeed;
            break;
        case KeyEventPressedArrowDown:
            self.currentMaxAccelY = -PlaneSpeed;
            break;
        case KeyEventPressedArrowLeft:
            self.currentMaxAccelX = -PlaneSpeed;
            break;
        case KeyEventReleased:
            if (self.currentMaxAccelX != 0) self.currentMaxAccelX = 0;
            if (self.currentMaxAccelY != 0) self.currentMaxAccelY = 0;
            break;
        case KeyEventPressedX:
            [self planeTargetFire];
            break;
            
        default: break;
    }
}


@end
