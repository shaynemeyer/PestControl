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

-(instancetype)init
{
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"characters"];
    SKTexture *texture = [atlas textureNamed:@"player_ft1"];
    texture.filteringMode = SKTextureFilteringNearest;
    
    if (self = [super initWithTexture:texture]) {
        self.name = @"player";
        // use a circle thats a bit smaller.
        CGFloat minDiam = MIN(self.size.width, self.size.height);
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
        
        self.physicsBody.collisionBitMask = PCBoundaryCategory;
    }
    
    return self;
}

-(void)moveToward:(CGPoint)targetPosition
{
    CGPoint targetVector = CGPointNormalize(CGPointSubtract(targetPosition, self.position));
    targetVector = CGPointMultiplyScalar(targetVector, 300);
    self.physicsBody.velocity = CGVectorMake(targetVector.x, targetVector.y);
}

@end
