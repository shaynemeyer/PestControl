//
//  Bug.m
//  PestControl
//
//  Created by Shayne Meyer on 9/12/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "Bug.h"
#import "MyScene.h"
#import "TileMapLayer.h"

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

-(void)walk
{
    // cast bugs parent to TileMapLayer object.
    TileMapLayer *tileLayer = (TileMapLayer *)self.parent;
    
    // find bugs current position on the grid. Use it as a starting point, choose random coordinates from one of the 8 surrounding tiles.
    CGPoint tileCoord = [tileLayer coordForPoint:self.position];
    int randomX = arc4random() % 3 - 1;
    int randomY = arc4random() % 3 - 1;
    CGPoint randomCoord = CGPointMake(tileCoord.x + randomX, tileCoord.y + randomY);
    
    // make sure the tile you chose is valid. for example if the bug is on the edge of the map then the edge tile is not a valid tile to move to.
    BOOL didMove = NO;
    MyScene *scene = (MyScene *)self.scene;
    if ([tileLayer isValidTileCoord:randomCoord] && ![scene tileAtCoord:randomCoord hasAnyProps:(PCWallCategory|PCWaterCategory)]) {
        // if valid walk the bug.
        didMove = YES;
        CGPoint randomPos = [tileLayer pointForCoord:randomCoord];
        SKAction *moveToPos = [SKAction sequence:@[[SKAction moveTo:randomPos duration:1],
                                                   [SKAction runBlock:^(void){
            [self walk];
        }]]];
        [self runAction:moveToPos];
    }
    
    // if you hit an invalid tile, wait a short period of time then walk again.
    if (!didMove) {
        [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.25 withRange:0.15],
                                             [SKAction performSelector:@selector(walk) onTarget:self]]]];
    }
}

-(void)start
{
    [self walk];
}

@end
