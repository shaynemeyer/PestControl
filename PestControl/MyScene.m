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

typedef NS_ENUM(int32_t, PCGameState)
{
    PCGameStateStartingLevel,
    PCGameStatePlaying,
    PCGameStateInLevelMenu,
};

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
    PCGameState _gameState;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        [self createWorld];
        [self createCharacters];
        [self centerViewOn:_player.position];
        [self createUserInterface];
        _gameState = PCGameStateStartingLevel;
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    switch (_gameState) {
        case PCGameStateStartingLevel:
        {
            [self childNodeWithName:@"msgLabel"].hidden = YES;
            _gameState = PCGameStatePlaying;
            self.paused = NO;
            // Intentionally omitted break.
        }
        case PCGameStatePlaying:
        {
            UITouch *touch = [touches anyObject];
            [_player moveToward:[touch locationInNode:_worldNode]];
            break;
        }
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    if (_gameState != PCGameStatePlaying) {
        return;
    }
    
    if (![_bugLayer childNodeWithName:@"bug"]) {
        [self endLevelWithSuccess:YES];
    }
}

-(void)endLevelWithSuccess:(BOOL)won
{
    // display proper message. Win or lose.
    SKLabelNode *label = (SKLabelNode *)[self childNodeWithName:@"msgLabel"];
    label.text = (won ? @"You Win!!!" : @"Too Slow!!!");
    label.hidden = NO;
    // Give the user the option to move on to the next level.
    SKLabelNode *nextLevel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    nextLevel.text = @"Next Level?";
    nextLevel.name = @"nextLevelLabel";
    nextLevel.fontSize = 28;
    nextLevel.horizontalAlignmentMode = (won ? SKLabelHorizontalAlignmentModeCenter : SKLabelHorizontalAlignmentModeLeft);
    nextLevel.position = (won ? CGPointMake(0, -40) : CGPointMake(0+20, -40));
    [self addChild:nextLevel];
    // stop player movement.
    _player.physicsBody.linearDamping = 1;
    _gameState = PCGameStateInLevelMenu;
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

-(void)didMoveToView:(SKView *)view
{
    if (_gameState == PCGameStateStartingLevel) {
        self.paused = YES;
    }
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
    
    if (_tileMap) {
        [self createCollisionAreas];
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

-(void)createCollisionAreas
{
    TMXObjectGroup *group = [_tileMap groupNamed:@"CollisionAreas"];
    
    NSArray *waterObjects = [group objectsNamed:@"water"];
    for (NSDictionary *waterObj in waterObjects) {
        CGFloat x = [waterObj[@"x"] floatValue];
        CGFloat y = [waterObj[@"y"] floatValue];
        CGFloat w = [waterObj[@"width"] floatValue];
        CGFloat h = [waterObj[@"height"] floatValue];
        
        SKSpriteNode *water = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(w, h)];
        water.name = @"water";
        water.position = CGPointMake(x + w / 2, y + h / 2);
        
        water.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(w, h)];
        
        water.physicsBody.categoryBitMask = PCWaterCategory;
        water.physicsBody.dynamic = NO;
        water.physicsBody.friction = 0;
        water.hidden = YES;
        
        [_bgLayer addChild:water];
    }
}

-(void)createUserInterface
{
    SKLabelNode *startMsg = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    startMsg.name = @"msgLabel";
    startMsg.text = @"Tap Screen to run!";
    startMsg.fontSize = 32;
    startMsg.position = CGPointMake(0, 20);
    [self addChild:startMsg];
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
