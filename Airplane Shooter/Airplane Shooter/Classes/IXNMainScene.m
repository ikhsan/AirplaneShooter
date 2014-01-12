//
//  IXNMainScene.m
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/11/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import "IXNMainScene.h"

#import <CoreMotion/CoreMotion.h>
#import "helper.h"

@interface IXNMainScene () <UIAccelerometerDelegate, SKPhysicsContactDelegate>

@property (nonatomic) CGRect screenRect;
@property (nonatomic) double currentMaxAccelX;
@property (nonatomic) double currentMaxAccelY;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) SKSpriteNode *plane;
@property (strong, nonatomic) SKSpriteNode *planeShadow;
@property (strong, nonatomic) SKSpriteNode *propeller;

@property (strong, nonatomic) SKEmitterNode *fireTrail;
@property (strong, nonatomic) NSArray *smokeTrails;

@property (strong, nonatomic) NSMutableArray *explosionTextures;
@property (strong, nonatomic) NSMutableArray *cloudsTextures;


@end

@implementation IXNMainScene

- (id)initWithSize:(CGSize)size
{
    if (!(self = [super initWithSize:size])) return nil;
    
    // init several sizes used in all scene
    self.screenRect = [UIScreen mainScreen].bounds;
    
    // adding the background
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"airPlanesBackground"];
    background.position = CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame));
    [self addChild:background];
    
    // add our plane
    [self addPlaneToScene];
    
    // add environments (enemies & clouds)
    [self addEnvironments];
    
    // add explosions
    SKTextureAtlas *explosionAtlas = [SKTextureAtlas atlasNamed:@"Explosion"];
    NSArray *textureNames = [explosionAtlas textureNames];
    self.explosionTextures = [NSMutableArray new];
    for (NSString *name in textureNames) {
        SKTexture *texture = [explosionAtlas textureNamed:name];
        [self.explosionTextures addObject:texture];
    }
    
    // add clouds
    SKTextureAtlas *cloudsAtlas = [SKTextureAtlas atlasNamed:@"Clouds"];
    NSArray *textureNamesClouds = [cloudsAtlas textureNames];
    self.cloudsTextures = [NSMutableArray new];
    for (NSString *name in textureNamesClouds) {
        SKTexture *texture = [cloudsAtlas textureNamed:name];
        [self.cloudsTextures addObject:texture];
    }
    
    // start motion manager
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        if (error) NSLog(@"error : %@", [error localizedDescription]);
        
        [self outputAccelerationData:accelerometerData.acceleration];
    }];
    
    // physics
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    self.physicsWorld.contactDelegate = self;
    
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
    
    // adding the fire trail
    [self addChild:self.fireTrail];
    
    // adding the smoke trails
    for (SKNode *node in self.smokeTrails)
        [self addChild:node];
}

- (void)addEnvironments
{
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
        _plane = [self nodeWithImageName:@"PLANE 8 N" scale:.6 position:CGPointZero zPosition:3];
        _plane.position = CGPointMake(CGRectGetWidth(_screenRect) / 2, 15 + (_plane.size.height / 2));
    }
    
    return _plane;
}

- (SKSpriteNode *)planeShadow
{
    if (!_planeShadow)
    {
        CGPoint p = shadowPosition(self.plane.position);
        
        _planeShadow = [self nodeWithImageName:@"PLANE 8 SHADOW" scale:.6 position:p zPosition:1];
    }
    
    return _planeShadow;
}

- (SKSpriteNode *)propeller
{
    if (!_propeller)
    {
        CGPoint p = propellerPosition(self.plane.position, self.plane.size, 0);
        
        _propeller = [self nodeWithImageName:@"PLANE PROPELLER 1" scale:.2 position:p zPosition:1];
        
        NSArray *textures = @[
                              [SKTexture textureWithImageNamed:@"PLANE PROPELLER 1"],
                              [SKTexture textureWithImageNamed:@"PLANE PROPELLER 2"]
                              ];
        
        SKAction *spin = [SKAction animateWithTextures:textures timePerFrame:.1];
        SKAction *spinForever = [SKAction repeatActionForever:spin];
        [_propeller runAction:spinForever];
    }
    
    return _propeller;
}

- (SKEmitterNode *)fireTrail
{
    if (!_fireTrail)
    {
        NSString *firePath = [[NSBundle mainBundle] pathForResource:@"trail" ofType:@"sks"];
        _fireTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:firePath];
        _fireTrail.zPosition = 2;
        _fireTrail.position = trailPosition(self.plane.position, self.plane.size);
    }
    
    return _fireTrail;
}

- (NSArray *)smokeTrails
{
    if (!_smokeTrails)
    {
        NSString *smokePath = [[NSBundle mainBundle] pathForResource:@"trail" ofType:@"sks"];
        
        _smokeTrails = @[
                         [NSKeyedUnarchiver unarchiveObjectWithFile:smokePath],
                         [NSKeyedUnarchiver unarchiveObjectWithFile:smokePath]
                         ];
        
        [_smokeTrails enumerateObjectsUsingBlock:^(SKNode *node, NSUInteger idx, BOOL *stop) {
            node.position = smokePosition(self.plane.position, self.plane.size, idx);
            node.zPosition = 2;
        }];
    }
    
    return _smokeTrails;
}

- (CMMotionManager *)motionManager
{
    if (!_motionManager)
    {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.accelerometerUpdateInterval = .2;
    }
    
    return _motionManager;
}

#pragma mark - Motion methods

- (void)outputAccelerationData:(CMAcceleration)acceleration
{
    self.currentMaxAccelX = self.currentMaxAccelY = 0.0;
    
    if (fabs(acceleration.x) > fabs(self.currentMaxAccelX))
        self.currentMaxAccelX = acceleration.x;
    
    if (fabs(acceleration.y) > fabs(self.currentMaxAccelY))
        self.currentMaxAccelY = acceleration.y;
}

- (void)setPlanesPosition:(CGPoint)p
{
    self.plane.position = p;
    
    self.planeShadow.position = shadowPosition(self.plane.position);
    
    CGFloat offset = 0;
    if (self.currentMaxAccelX > TiltConstant)
        offset = 5.0;
    else if (self.currentMaxAccelX < -TiltConstant)
        offset = -5.0;
    
    self.propeller.position = propellerPosition(self.plane.position, self.plane.size, offset);
    
    self.fireTrail.position = trailPosition(self.plane.position, self.plane.size);
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
    enemy.scale = 0.6;
    enemy.zPosition = 1;
    
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
    CGPoint p2 = CGPointMake(
                             ixn_random(size.width, width - (size.width * 2)),
                             ixn_random(size.height, width / 2)
                             );
    
    CGPoint p3 = CGPointMake(
                             ixn_random(0, p2.y),
                             ixn_random(width / 2, width - size.height)
                             );
    
    CGPoint p4 = CGPointMake(ixn_random(size.width, width - (size.width * 2)), -100.0);
    
    CGPathMoveToPoint(path, NULL, p1.x, p1.y);
    CGPathAddCurveToPoint(path, NULL, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y);
    
    return path;
}

- (void)createClouds
{
    if (arc4random_uniform(2) == 0) return;
    
    int whichCloud = ixn_random(0, 3);
    SKSpriteNode *cloud = [SKSpriteNode spriteNodeWithTexture:[_cloudsTextures objectAtIndex:whichCloud]];
    
    int randomYAxix = ixn_random(0, self.screenRect.size.height);
    cloud.position = CGPointMake(self.screenRect.size.height + cloud.size.height / 2, randomYAxix);
    cloud.zPosition = 1;
    int randomTimeCloud = ixn_random(9, 19);
    
    SKAction *move =[SKAction moveTo:CGPointMake(-cloud.size.height, randomYAxix) duration:randomTimeCloud];
    SKAction *remove = [SKAction removeFromParent];
    [cloud runAction:[SKAction sequence:@[move,remove]]];
    [self addChild:cloud];
    
}

#pragma mark - Interaction methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
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
    [bullet runAction:[SKAction sequence:@[action,remove]]];
    
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
    newY = 6.0 + self.currentMaxAccelY * 10;
    
    newX = MIN(MAX(newX+_plane.position.x,minX),maxX);
    newY = MIN(MAX(newY+_plane.position.y,minY),maxY);
    [self setPlanesPosition:CGPointMake(newX, newY)];
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
        SKSpriteNode *explosion = [SKSpriteNode spriteNodeWithTexture:[_explosionTextures objectAtIndex:0]];
        explosion.zPosition = 1;
        explosion.scale = 0.6;
        explosion.position = contact.bodyA.node.position;
        [self addChild:explosion];
        
        SKAction *explosionAction = [SKAction animateWithTextures:_explosionTextures timePerFrame:0.07];
        SKAction *remove = [SKAction removeFromParent];
        [explosion runAction:[SKAction sequence:@[explosionAction,remove]]];
        
        // remove from scene
        SKNode *projectile = (contact.bodyA.categoryBitMask & bulletCategory) ? contact.bodyA.node : contact.bodyB.node;
        SKNode *enemy = (contact.bodyA.categoryBitMask & bulletCategory) ? contact.bodyB.node : contact.bodyA.node;
        [projectile runAction:[SKAction removeFromParent]];
        [enemy runAction:[SKAction removeFromParent]];
    }
}

@end
