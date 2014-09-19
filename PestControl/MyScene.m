//
//  MyScene.m
//  PestControl
//
//  Created by Shayne Meyer on 9/10/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "MyScene.h"
#import "TileMapLayer.h"
#import "TileMapLayerLoader.h"
#import "Player.h"
#import "Bug.h"
#import "Breakable.h"
#import "FireBug.h"
#import "TmxTileMapLayer.h"

@interface MyScene () <SKPhysicsContactDelegate>

@end

@implementation MyScene
{
    SKNode *_worldNode;
    TileMapLayer *_bgLayer;
    Player *_player;
    TileMapLayer *_bugLayer;
    TileMapLayer *_breakableLayer;
    JSTileMap *_tileMap;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        [self createWorld];
        [self createCharacters];
        [self centerViewOn:_player.position];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    UITouch *touch = [touches anyObject];
    [_player moveToward:[touch locationInNode:_worldNode]];

}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

-(void)centerViewOn:(CGPoint)centerOn
{
    _worldNode.position = [self pointToCenterViewOn:centerOn];
}

-(CGPoint)pointToCenterViewOn:(CGPoint)centerOn
{
    CGSize size = self.size;
    CGFloat x = Clamp(centerOn.x, size.width / 2, _bgLayer.layerSize.width - size.width / 2);
    CGFloat y = Clamp(centerOn.y, size.height / 2, _bgLayer.layerSize.height - size.height / 2);
    return CGPointMake(-x, -y);
}

-(void)didSimulatePhysics
{
    CGPoint target = [self pointToCenterViewOn:_player.position];
    CGPoint newPosition = _worldNode.position;
    newPosition.x += (target.x - _worldNode.position.x) * 0.1f;
    newPosition.y += (target.y - _worldNode.position.y) * 0.1f;
    
    _worldNode.position = newPosition;
}

#pragma mark
#pragma mark - Create Scene Methods

-(TileMapLayer *)createScenery
{
    //return [TileMapLayerLoader tileMapLayerFromFileNamed:@"level-1-bg.txt"];
    _tileMap = [JSTileMap mapNamed:@"level-3.tmx"];
    return [[TmxTileMapLayer alloc] initWithTmxLayer:[_tileMap layerNamed:@"Background"]];
}

-(void)createWorld
{
    _bgLayer = [self createScenery];
    _worldNode = [SKNode node];
    if (_tileMap) {
        [_worldNode addChild:_tileMap];
    }
    [_worldNode addChild:_bgLayer];
    [self addChild:_worldNode];
    
    self.anchorPoint = CGPointMake(0.5, 0.5);
    _worldNode.position = CGPointMake(-_bgLayer.layerSize.width / 2, -_bgLayer.layerSize.height / 2);
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    
    // define boundary
    SKNode *bounds = [SKNode node];
    bounds.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, 0, _bgLayer.layerSize.width, _bgLayer.layerSize.height)];
    bounds.physicsBody.categoryBitMask = PCBoundaryCategory;
    bounds.physicsBody.friction = 0;
    [_worldNode addChild:bounds];
    
    self.physicsWorld.contactDelegate = self;
    
    _breakableLayer = [self createBreakables];
    if (_breakableLayer) {
        [_worldNode addChild:_breakableLayer];
    }
}

-(void)createCharacters
{
    //_bugLayer = [TileMapLayerLoader tileMapLayerFromFileNamed:@"level-2-bugs.txt"];
    _bugLayer = [[TmxTileMapLayer alloc] initWithTmxObjectGroup:[_tileMap groupNamed:@"Bugs"] tileSize:_tileMap.tileSize gridSize:_bgLayer.gridSize];
    [_worldNode addChild:_bugLayer];
    
    _player = (Player *)[_bugLayer childNodeWithName:@"player"];
    [_player removeFromParent];
    [_worldNode addChild:_player];
    
    [_bugLayer enumerateChildNodesWithName:@"bug" usingBlock:^(SKNode *node, BOOL *stop) {
        [(Bug *)node start];
    }];
}

#pragma mark
#pragma mark - Contact Methods

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *other = (contact.bodyA.categoryBitMask == PCPlayerCategory ? contact.bodyB : contact.bodyA);
    
    if (other.categoryBitMask == PCBugCategory) {
        [other.node removeFromParent];
    } else if (other.categoryBitMask & PCBreakableCategory) {
        Breakable *breakable = (Breakable *)other.node;
        [breakable smashBreakable];
    }  else if (other.categoryBitMask & PCFireBugCategory) {
        FireBug *fireBug = (FireBug *)other.node;
        [fireBug kickBug];
    }
}

-(void)didEndContact:(SKPhysicsContact *)contact
{
    // find other body involved in the contact.
    SKPhysicsBody *other = (contact.bodyA.categoryBitMask == PCPlayerCategory ? contact.bodyB : contact.bodyA);
    
    // if non-zero value, collision was something solid enough to cause the player to change direction.
    if (other.categoryBitMask & _player.physicsBody.collisionBitMask) {
        // change direction.
        [_player faceCurrentDirection];
    }
    
}

- (TileMapLayer *)createBreakables
{
    if (_tileMap) {
        TMXLayer *breakables = [_tileMap layerNamed:@"Breakables"];
        return (breakables ? [[TmxTileMapLayer alloc] initWithTmxLayer:breakables] : nil);
    } else {
        return [TileMapLayerLoader tileMapLayerFromFileNamed:@"level-2-breakables.txt"];
    }
}

#pragma mark
#pragma mark - TileAt Methods

-(BOOL)tileAtPoint:(CGPoint)point hasAnyProps:(uint32_t)props
{
    SKNode *tile = [_breakableLayer tileAtPoint:point];
    if (!tile) {
        tile = [_bgLayer tileAtPoint:point];
    }
    return tile.physicsBody.categoryBitMask & props;
}

-(BOOL)tileAtCoord:(CGPoint)coord hasAnyProps:(uint32_t)props
{
    return [self tileAtPoint:[_bgLayer pointForCoord:coord] hasAnyProps:props];
}

@end
