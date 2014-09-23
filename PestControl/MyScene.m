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
    int _level;
    double _levelTimeLimit;
    SKLabelNode *_timerLabel;
    double _currentTime;
    double _startTime;
    double _elapsedTime;
}

-(id)initWithSize:(CGSize)size level:(int)level{
    if (self = [super initWithSize:size]) {
        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Levels" ofType:@"plist"]];
        if (level < 0 || level >= [config[@"levels"] count]) {
            level = 0;
        }
        _level = level;
        
        NSDictionary *levelData = config[@"levels"][level];
        if (levelData[@"tmxFile"]) {
            _tileMap = [JSTileMap mapNamed:levelData[@"tmxFile"]];
        }
        
        [self createWorld:levelData];
        [self createCharacters:levelData];
        [self centerViewOn:_player.position];
        _levelTimeLimit = [levelData[@"timeLimit"] doubleValue];
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
            _timerLabel.hidden = NO;
            _startTime = _currentTime;
            // Intentionally omitted break.
        }
        case PCGameStatePlaying:
        {
            UITouch *touch = [touches anyObject];
            [_player moveToward:[touch locationInNode:_worldNode]];
            break;
        }
        case PCGameStateInLevelMenu:
        {
            UITouch *touch = [touches anyObject];
            CGPoint loc = [touch locationInNode:self];
            
            SKNode *node = [self childNodeWithName:@"nextLevelLabel"];
            if ([node containsPoint:loc]) {
                MyScene *newScene = [[MyScene alloc] initWithSize:self.size level:_level+1];
                
                [self.view presentScene:newScene transition:[SKTransition flipVerticalWithDuration:0.5]];
            } else {
                node = [self childNodeWithName:@"retryLabel"];
                if ([node containsPoint:loc]) {
                    MyScene *newScene = [[MyScene alloc] initWithSize:self.size level:_level];
                    [self.view presentScene:newScene transition:[SKTransition flipVerticalWithDuration:0.5]];
                }
            }
            break;
        }
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    _currentTime = currentTime;
    
    if (_gameState == PCGameStateInLevelMenu && !self.isPaused) {
        self.paused = YES;
    }
    
    if (_gameState != PCGameStatePlaying) {
        return;
    }
    
    _elapsedTime = currentTime - _startTime;
    
    CFTimeInterval timeRemaining = _levelTimeLimit - _elapsedTime;
    if (timeRemaining < 0) {
        timeRemaining = 0;
    }
    
    _timerLabel.text = [NSString stringWithFormat:@"Time Remaining: %2.2f", timeRemaining];
    
    if (_elapsedTime >= _levelTimeLimit) {
        [self endLevelWithSuccess:NO];
    } else if (![_bugLayer childNodeWithName:@"bug"]) {
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
    
    if (!won) {
        SKLabelNode *tryAgain = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        tryAgain.text = @"Try Again?";
        tryAgain.name = @"retryLabel";
        tryAgain.fontSize = 28;
        tryAgain.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
        tryAgain.position = CGPointMake(0-20, -40);
        [self addChild:tryAgain];
    }
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

-(TileMapLayer *)createScenery:(NSDictionary*)levelData
{
    //return [TileMapLayerLoader tileMapLayerFromFileNamed:@"level-1-bg.txt"];
    _tileMap = [JSTileMap mapNamed:@"level-3.tmx"];

    if (_tileMap) {
        return [[TmxTileMapLayer alloc] initWithTmxLayer:[_tileMap layerNamed:@"Background"]];
    } else {
        NSDictionary *layerFiles = levelData[@"layers"];
        return [TileMapLayerLoader tileMapLayerFromFileNamed:layerFiles[@"background"]];
    }
    
}

-(void)createWorld:(NSDictionary *)levelData
{
    _bgLayer = [self createScenery:levelData];
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
    bounds.name = @"worldBounds";
    [_worldNode addChild:bounds];
    
    self.physicsWorld.contactDelegate = self;
    
    _breakableLayer = [self createBreakables:levelData];
    if (_breakableLayer) {
        [_worldNode addChild:_breakableLayer];
    }
    
    if (_tileMap) {
        [self createCollisionAreas];
    }
}

-(void)createCharacters:(NSDictionary *)levelData
{
    if (_tileMap) {
        _bugLayer = [[TmxTileMapLayer alloc] initWithTmxObjectGroup:[_tileMap groupNamed:@"Bugs"]
                                                           tileSize:_tileMap.tileSize
                                                           gridSize:_bgLayer.gridSize];
    } else {
        NSDictionary *layerFiles = levelData[@"layers"];
        _bugLayer = [TileMapLayerLoader tileMapLayerFromFileNamed:layerFiles[@"bugs"]];
    }
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
    
    _timerLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
    _timerLabel.text = [NSString stringWithFormat:@"Time Remaining: %2.2f", _levelTimeLimit];
    _timerLabel.fontSize = 18;
    _timerLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _timerLabel.position = CGPointMake(0, 130);
    [self addChild:_timerLabel];
    _timerLabel.hidden = YES;
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

- (TileMapLayer *)createBreakables:(NSDictionary *)levelData
{
    if (_tileMap) {
        TMXLayer *breakables = [_tileMap layerNamed:@"Breakables"];
        return (breakables ? [[TmxTileMapLayer alloc] initWithTmxLayer:breakables] : nil);
    } else {
        NSDictionary *layerFiles = levelData[@"layers"];
        return [TileMapLayerLoader tileMapLayerFromFileNamed:layerFiles[@"breakables"]];
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

#pragma mark
#pragma mark - NSCoding methods

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    SKNode *worldBounds =
    [_worldNode childNodeWithName:@"worldBounds"];
    [worldBounds removeFromParent];
    
    //1
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_worldNode forKey:@"MyScene-WorldNode"];
    [aCoder encodeObject:_player forKey:@"MyScene-Player"];
    [aCoder encodeObject:_bgLayer forKey:@"MyScene-BgLayer"];
    [aCoder encodeObject:_bugLayer forKey:@"MyScene-BugLayer"];
    [aCoder encodeObject:_breakableLayer forKey:@"MyScene-BreakableLayer"];
    [aCoder encodeObject:_tileMap forKey:@"MyScene-TmxTileMap"];
    
    [aCoder encodeInt32:_gameState forKey:@"MyScene-GameState"];
    [aCoder encodeInt:_level forKey:@"MyScene-Level"];
    [aCoder encodeDouble:_levelTimeLimit forKey:@"MyScene-LevelTimeLimit"];
    [aCoder encodeObject:_timerLabel forKey:@"MyScene-TimerLabel"];
    //2
    [aCoder encodeDouble:_elapsedTime forKey:@"MyScene-ElapsedTime"];
    
    [_worldNode addChild:worldBounds];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _worldNode =
        [aDecoder decodeObjectForKey:@"MyScene-WorldNode"];
        _player = [aDecoder decodeObjectForKey:@"MyScene-Player"];
        _bgLayer = [aDecoder decodeObjectForKey:@"MyScene-BgLayer"];
        _bugLayer = [aDecoder decodeObjectForKey:@"MyScene-BugLayer"];
        _breakableLayer = [aDecoder decodeObjectForKey:@"MyScene-BreakableLayer"];
        _tileMap = [aDecoder decodeObjectForKey:@"MyScene-TmxTileMap"];
        
        _gameState = [aDecoder decodeInt32ForKey:@"MyScene-GameState"];
        _level = [aDecoder decodeIntForKey:@"MyScene-Level"];
        _levelTimeLimit = [aDecoder decodeDoubleForKey:@"MyScene-LevelTimeLimit"];
        _timerLabel = [aDecoder decodeObjectForKey:@"MyScene-TimerLabel"];
        
        _elapsedTime = [aDecoder decodeDoubleForKey:@"MyScene-ElapsedTime"];
        
        SKNode *bounds = [SKNode node];
        bounds.name = @"worldBounds";
        bounds.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, 0, _bgLayer.layerSize.width, _bgLayer.layerSize.height)];
        bounds.physicsBody.categoryBitMask = PCWallCategory;
        bounds.physicsBody.collisionBitMask = 0;
        bounds.physicsBody.friction = 0;
        [_worldNode addChild:bounds];
//
//        if (_tileMap) {
//            [_bgLayer enumerateChildNodesWithName:@"water"
//                                       usingBlock:
//             ^(SKNode *node, BOOL *stop){
//                 node.hidden = YES;
//             }];
//        }
//        
//        switch (_gameState) {
//            case PCGameStateInReloadMenu:
//            case PCGameStatePlaying:
//            {
//                _gameState = PCGameStateInReloadMenu;
//                [self showReloadMenu];
//                break;
//            }
//            default: break;
//        }
        
    }
    return self;
}

@end
