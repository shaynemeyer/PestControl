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

+(void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFacingForwardAnim = [Bug createAnimWithPrefix:@"bug" suffix:@"ft"];
        sharedFacingBackAnim = [Bug createAnimWithPrefix:@"bug" suffix:@"bk"];
        sharedFacingSideAnim = [Bug createAnimWithPrefix:@"bug" suffix:@"lt"];
    });
}

static SKAction *sharedFacingBackAnim = nil;
-(SKAction *)facingBackAnim
{
    return sharedFacingBackAnim;
}

static SKAction *sharedFacingForwardAnim = nil;
-(SKAction *)facingForwardAnim
{
    return sharedFacingForwardAnim;
}

static SKAction *sharedFacingSideAnim = nil;
-(SKAction *)facingSideAnim
{
    return sharedFacingSideAnim;
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
        [self faceDirection:CGPointMake(randomX, randomY)];
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

-(void)faceDirection:(CGPoint)dir
{
    // store direction sprite currently faces
    PCFacingDirection facingDir = self.facingDirection;
    // determines whether the new tile is located diagonally from the current tile.
    if (dir.y != 0 && dir.x != 0) {
        // for diagonal motion choose the appropriate facing direction.
        facingDir = dir.y < 0 ? PCFacingBack : PCFacingForward;
        self.zRotation = dir.y < 0 ? M_PI_4 : - M_PI_4;
        if (dir.x > 0) {
            self.zRotation *= -1;
        }
    } else {
        // if not diagonal, set rotation to zero.
        self.zRotation = 0;
        
        // choose correct direction based on whether the movement is horizontal (y==0) or vertical.
        if (dir.y == 0) {
            if (dir.x > 0) {
                facingDir = PCFacingRight;
            } else if (dir.x < 0) {
                facingDir = PCFacingLeft;
            }
        } else if (dir.y < 0) {
            facingDir = PCFacingBack;
        } else {
            facingDir = PCFacingForward;
        }
    }
    // set the facingDirection Property.
    self.facingDirection = facingDir;
}

@end
