//
//  Bug.m
//  PestControl
//
//  Created by Shayne Meyer on 9/12/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "Bug.h"
#import "MyScene.h"

@implementation Bug

-(instancetype)init
{
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"characters"];
    SKTexture *texture = [atlas textureNamed:@"bug_ft1"];
    texture.filteringMode = SKTextureFilteringNearest;
    
    if (self = [super initWithTexture:texture]) {
        self.name = @"bug";
        CGFloat minDiam = MIN(self.size.width, self.size.height);
        minDiam = MAX(minDiam-8, 8);
        self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:minDiam / 2.0];
        self.physicsBody.categoryBitMask = PCBugCategory;
        self.physicsBody.collisionBitMask = 0;
    }
    
    return self;
}

@end
