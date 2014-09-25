//
//  Player.m
//  PestControl
//
//  Created by Shayne Meyer on 9/11/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "Player.h"
#import "MyScene.h"

@implementation Player
{
    SKEmitterNode *_emitter;
    AnimatingSprite *_sprite;
}

-(instancetype)init
{
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"characters"];
    SKTexture *texture = [atlas textureNamed:@"player_ft1"];
    texture.filteringMode = SKTextureFilteringNearest;
    
    if (self = [super init]) {
        _sprite = [[AnimatingSprite alloc] initWithTexture:texture];
        self.name = @"player";
        
        [self addChild:_sprite];
        
        // use a circle thats a bit smaller.
        CGFloat minDiam = MIN(_sprite.size.width, _sprite.size.height);
        minDiam = MAX(minDiam-16, 4);
        self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:minDiam / 2.0];
        // enable collision detection.
        self.physicsBody.usesPreciseCollisionDetection = YES;
        // 
        self.physicsBody.allowsRotation = NO;
        self.physicsBody.restitution = 1;
        self.physicsBody.friction = 0;
        self.physicsBody.linearDamping = 0;
        
        self.physicsBody.categoryBitMask = PCPlayerCategory;
        self.physicsBody.contactTestBitMask = 0xFFFFFFFF;
        
        self.physicsBody.collisionBitMask = PCBoundaryCategory | PCWallCategory | PCWaterCategory | PCFireBugCategory;
        
        // setup animation
        _sprite.facingForwardAnim = [AnimatingSprite createAnimWithPrefix:@"player" suffix:@"ft"];
        _sprite.facingBackAnim = [AnimatingSprite createAnimWithPrefix:@"player" suffix:@"bk"];
        _sprite.facingSideAnim = [AnimatingSprite createAnimWithPrefix:@"player" suffix:@"lt"];
    }
    
    return self;
}

-(void)moveToward:(CGPoint)targetPosition
{
    CGPoint targetVector = CGPointNormalize(CGPointSubtract(targetPosition, self.position));
    targetVector = CGPointMultiplyScalar(targetVector, 300);
    self.physicsBody.velocity = CGVectorMake(targetVector.x, targetVector.y);
    [self faceCurrentDirection];
}

-(void)faceCurrentDirection
{
    // set direction to current direction
    PCFacingDirection facingDir = _sprite.facingDirection;
    
    // is the player moving vertically more than horizontally? If so choose forward or backward based on which way the player is facing.
    CGVector dir = self.physicsBody.velocity;
    if (abs(dir.dy) > abs(dir.dx)) {
        if (dir.dy < 0) {
            facingDir = PCFacingForward;
        } else {
            facingDir = PCFacingBack;
        }
    } else {
        facingDir = (dir.dx > 0) ? PCFacingRight : PCFacingLeft;
    }
    
    // Set facingDirection Property.
    _sprite.facingDirection = facingDir;
}

//- (instancetype)initWithCoder:(NSCoder *)aDecoder
//{
//    if (self = [super initWithCoder:aDecoder]) {
//        _sprite = [aDecoder decodeObjectForKey:@"Player-Sprite"];
//        _emitter = [aDecoder decodeObjectForKey:@"Player-Emitter"];
//    }
//    return self;
//}
//
//- (void)encodeWithCoder:(NSCoder *)aCoder
//{
//    [super encodeWithCoder:aCoder];
//    [aCoder encodeObject:_sprite forKey:@"Player-Sprite"];
//    [aCoder encodeObject:_emitter forKey:@"Player-Emitter"];
//}

@end
