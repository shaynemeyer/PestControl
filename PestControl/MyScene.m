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
#import "SKNode+SKTExtras.h"
#import "SKAction+SKTExtras.h"
#import "SKTEffects.h"
#import "SKEmitterNode+SKTExtras.h"
#import "SKTAudio.h"

static SKAction *HitWallSound;
static SKAction *HitWaterSound;
static SKAction *HitTreeSound;
static SKAction *HitFireBugSound;
static SKAction *PlayerMoveSound;
static SKAction *TickTockSound;
static SKAction *WinSound;
static SKAction *LoseSound;
static SKAction *KillBugSounds[12];

typedef NS_ENUM(int32_t, PCGameState)
{
    PCGameStateStartingLevel,
    PCGameStatePlaying,
    PCGameStateInLevelMenu,
    PCGameStateInReloadMenu,
};

typedef NS_ENUM(NSInteger, Side)
{
    SideRight   = 0,
    SideLeft    = 2,
    SideTop     = 1,
    SideBottom  = 3,
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
    CFTimeInterval _lastComboTime;
    int _comboCounter;
    BOOL _tickTockPlaying;
}

+(void)initialize
{
    if ([self class] == [MyScene class]) {
        HitWallSound = [SKAction playSoundFileNamed:@"HitWall.mp3" waitForCompletion:NO];
        HitWaterSound = [SKAction playSoundFileNamed:@"HitWater.mp3" waitForCompletion:NO];
        HitTreeSound = [SKAction playSoundFileNamed:@"HitTree.mp3" waitForCompletion:NO];
        HitFireBugSound = [SKAction playSoundFileNamed:@"HitFireBug.mp3" waitForCompletion:NO];
        PlayerMoveSound = [SKAction playSoundFileNamed:@"PlayerMove.mp3" waitForCompletion:NO];
        TickTockSound = [SKAction playSoundFileNamed:@"TickTock.mp3" waitForCompletion:NO];
        WinSound = [SKAction playSoundFileNamed:@"Win.mp3" waitForCompletion:NO];
        LoseSound = [SKAction playSoundFileNamed:@"Lose.mp3" waitForCompletion:NO];
        
        for (int t = 0; t < 12; ++t) {
            KillBugSounds[t] = [SKAction playSoundFileNamed:[NSString stringWithFormat:@"KillBug-%d.mp3", t+1] waitForCompletion:NO];
        }
    }
}

-(id)initWithSize:(CGSize)size level:(int)level{
    if (self = [super initWithSize:size]) {
        NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"JuicyLevels" ofType:@"plist"]];
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
        self.backgroundColor = SKColorWithRGB(89, 133, 39);
        [[SKTAudio sharedInstance] playBackgroundMusic:@"Music.mp3"];
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
            [_player start];
            // Intentionally omitted break.
        }
        case PCGameStatePlaying:
        {
            UITouch *touch = [touches anyObject];
            [self tapEffectsForTouch:touch];
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
                
                newScene.userData = self.userData;
                [self.view presentScene:newScene transition:[SKTransition flipVerticalWithDuration:0.5]];
            } else {
                node = [self childNodeWithName:@"retryLabel"];
                if ([node containsPoint:loc]) {
                    MyScene *newScene = [[MyScene alloc] initWithSize:self.size level:_level];
                    
                    newScene.userData = self.userData;
                    [self.view presentScene:newScene transition:[SKTransition flipVerticalWithDuration:0.5]];
                }
            }
            break;
        }
        case PCGameStateInReloadMenu:
        {
            UITouch *touch = [touches anyObject];
            CGPoint loc = [touch locationInNode:self];
            SKNode *node = [self nodeAtPoint:loc];
            if ([node.name isEqualToString:@"restartLabel"]) {
                MyScene *newScene = [[MyScene alloc] initWithSize:self.size level:_level];
                newScene.userData = self.userData;
                [self.view presentScene:newScene transition:[SKTransition flipVerticalWithDuration:.5]];
            } else if ([node.name isEqualToString:@"continueLabel"]) {
                [node removeFromParent];
                node = [self childNodeWithName:@"restartLabel"];
                [node removeFromParent];
                [self childNodeWithName:@"msgLabel"].hidden = YES;
                
                _gameState = PCGameStatePlaying;
                self.paused = NO;
                
                _startTime = _currentTime - _elapsedTime;
            }
            break;
        }
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    _currentTime = currentTime;
    
    if ((_gameState == PCGameStateStartingLevel || _gameState == PCGameStateInReloadMenu) && !self.isPaused) {
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
    
    if (timeRemaining < 10 && timeRemaining > 0 && !_tickTockPlaying) {
        _tickTockPlaying = YES;
        [self runAction:TickTockSound withKey:@"tickTock"];
    }
}

-(void)endLevelWithSuccess:(BOOL)won
{
    [self removeActionForKey:@"tickTock"];
    
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
    
    if (won) {
        NSMutableDictionary *records = self.userData[@"bestTimes"];
        CGFloat bestTime = [records[@(_level)] floatValue];
        if( !bestTime || _elapsedTime < bestTime) {
            records[@(_level)] = @(_elapsedTime);
            label.text = [NSString stringWithFormat:@"New Record! %2.2f",_elapsedTime];
        }
    }
    
    [[SKTAudio sharedInstance] pauseBackgroundMusic];
    [self runAction:won ? WinSound : LoseSound];
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
        [self bugHitEffects:(SKSpriteNode *)other.node];
    } else if (other.categoryBitMask & PCBreakableCategory) {
        Breakable *breakable = (Breakable *)other.node;
        [breakable smashBreakable];
        [self runAction:HitTreeSound];
    }  else if (other.categoryBitMask & PCFireBugCategory) {
        [self fireBugHitEffects];
        FireBug *fireBug = (FireBug *)other.node;
        [fireBug kickBug];
    } else if (other.categoryBitMask & (PCBoundaryCategory | PCWallCategory | PCWaterCategory | PCCrackedWallCategory)) {
        [self wallHitEffects:other.node];
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

        if (_tileMap) {
            [_bgLayer enumerateChildNodesWithName:@"water"
                                       usingBlock:
             ^(SKNode *node, BOOL *stop){
                 node.hidden = YES;
             }];
        }
        
        switch (_gameState) {
            case PCGameStateInReloadMenu:
            case PCGameStatePlaying:
            {
                _gameState = PCGameStateInReloadMenu;
                [self showReloadMenu];
                break;
            }
            default: break;
        }
        
        [self removeActionForKey:@"tickTock"];
        
    }
    return self;
}

-(void)showReloadMenu
{
    SKLabelNode *label = (SKLabelNode *)[self childNodeWithName:@"msgLabel"];
    label.text = @"Found a Save File";
    label.hidden = NO;
    
    SKLabelNode *continueLabel = (SKLabelNode *)[self childNodeWithName:@"continueLabel"];
    if (!continueLabel) {
        continueLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        continueLabel.text = @"Continue?";
        continueLabel.name = @"continueLabel";
        continueLabel.fontSize = 28;
        continueLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
        continueLabel.position = CGPointMake(0-20, -40);
        [self addChild:continueLabel];
        
        SKLabelNode *restartLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        restartLabel.text = @"Restart Level?";
        restartLabel.name = @"restartLabel";
        restartLabel.fontSize = 28;
        restartLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        restartLabel.position = CGPointMake(0+20, -40);
        [self addChild:restartLabel];
    }
}

#pragma mark
#pragma mark - Special Effects methods

-(void)scaleWall:(SKNode *)node
{
//    node.xScale = node.yScale = 1.2f;
//    
//    SKAction *action = [SKAction scaleTo:1.0f duration:1.2];
//    action.timingMode = SKActionTimingEaseOut;
//    [node runAction:action withKey:@"scaling"];
    if ([node actionForKey:@"scaling"] == nil) {
        // Create a new scale but remember the old.
        CGPoint oldScale = CGPointMake(node.xScale, node.yScale);
        CGPoint newScale = CGPointMultiplyScalar(oldScale, 1.2f); 
        
        // create scale effect.
        SKTScaleEffect *scaleEffect = [SKTScaleEffect effectWithNode:node
                                                            duration:1.2
                                                          startScale:newScale
                                                            endScale:oldScale];
        // simulate shaking effect.
        scaleEffect.timingFunction = SKTCreateShakeFunction(4);
        
        // since you cannot apply scale effect directly on the object, wrap it in a SKAction.
        SKAction *action = [SKAction actionWithEffect:scaleEffect];
        
        // give the keyname scaling.
        [node runAction:action withKey:@"scaling"];
    }
}

-(void)wallHitEffects:(SKNode *)node
{
    Side side = [self sideForCollisionWithNode:node];
    [self squashPlayerForSide:side];
    
    // outside boundary - cannot scale so add special animations.
    if (node.physicsBody.categoryBitMask & PCBoundaryCategory) {
        [self screenShakeForSide:side power:20.0f];
    } else {
        // call helper method from SKNode+SKTExtras
        [node skt_bringToFront];
        // call scaleWall
        [self scaleWall:node];
        [self moveWall:node onSide:side];
        //[self crackWall:(SKSpriteNode *)node]; todo: bug here. must troubleshoot further.
        [self screenShakeForSide:side power:8.0f];
        [self showParticlesForWall:node onSide:side];
    }
    
    [self bugJelly];
    
    if (node.physicsBody.categoryBitMask & PCWaterCategory) {
        [self runAction:HitWaterSound];
    } else {
        [self runAction:HitWallSound];
    }
}

-(Side)sideForCollisionWithNode:(SKNode *)node
{
    // Did the player hit the screen bounds?
    if (node.physicsBody.categoryBitMask & PCBoundaryCategory) {
        if (_player.position.x < 20.0f) {
            return SideLeft;
        } else if (_player.position.y < 20.0f) {
            return SideBottom;
        } else if (_player.position.x > self.size.width - 20.0f) {
            return SideRight;
        } else {
            return SideTop;
        }
    } else {
        CGPoint diff = CGPointSubtract(node.position, _player.position);
        CGFloat angle = CGPointToAngle(diff);
        
        if (angle > -M_PI_4 && angle <= M_PI_4) {
            return SideRight;
        } else if (angle > M_PI_4 && angle <= 3.0f * M_PI_4) {
            return SideTop;
        } else if (angle <= -M_PI_4 && angle > -3.0f * M_PI_4) {
            return SideBottom;
        } else {
            return SideLeft;
        }
    }
}

-(void)moveWall:(SKNode *)node onSide:(Side)side
{
    if ([node actionForKey:@"moving"] == nil) {
        // lookup table to determine the offset based on side of player that collides with wall.
        static CGPoint offsets[] = {
            {   4.0f,   0.0f    },
            {   0.0f,   4.0f    },
            {   -4.0f,  0.0f    },
            {   0.0f,   -4.0f   },
        };
        
        // add offset to the walls current position.
        CGPoint oldPosition = node.position;
        CGPoint offset = offsets[side];
        CGPoint newPosition = CGPointAdd(node.position, offset);
        
        // create a move effect to shift the wall.
        SKTMoveEffect *moveEffect = [SKTMoveEffect effectWithNode:node
                                                         duration:0.6
                                                    startPosition:newPosition
                                                      endPosition:oldPosition];
        // set the timing function for the animation.
        moveEffect.timingFunction = SKTTimingFunctionBackEaseOut;
        
        // create and call action.
        SKAction *action = [SKAction actionWithEffect:moveEffect];
        [node runAction:action withKey:@"moving"];
    }
}

-(void)tapEffectsForTouch:(UITouch *)touch
{
    [self stretchPlayerWhenMoved];
    [self showTapAtLocation:[touch locationInNode:_worldNode]];
    [_player runAction:PlayerMoveSound];
}

-(void)stretchPlayerWhenMoved
{
    CGPoint oldScale = CGPointMake(_player.xScale,
                                   _player.yScale);
    CGPoint newScale = CGPointMultiplyScalar(oldScale, 1.4f);
    
    SKTScaleEffect *scaleEffect = [SKTScaleEffect effectWithNode:_player
                                                        duration:0.2
                                                      startScale:newScale
                                                        endScale:oldScale];
    scaleEffect.timingFunction = SKTTimingFunctionSmoothstep;
    
    [_player runAction:[SKAction actionWithEffect:scaleEffect]];
}

-(void)squashPlayerForSide:(Side)side
{
    if ([_player actionForKey:@"squash"] != nil) {
        return;
    }
    
    CGPoint oldScale = CGPointMake(_player.xScale,
                                   _player.yScale);
    CGPoint newScale = oldScale;
    
    const float ScaleFactor = 1.6f;
    
    if (side == SideTop || side == SideBottom) {
        newScale.x *= ScaleFactor;
        newScale.y /= ScaleFactor;
    } else {
        newScale.x /= ScaleFactor;
        newScale.y *= ScaleFactor;
    }
    
    SKTScaleEffect *scaleEffect = [SKTScaleEffect effectWithNode:_player
                                                        duration:0.2
                                                      startScale:newScale
                                                        endScale:oldScale];
    scaleEffect.timingFunction = SKTTimingFunctionQuarticEaseOut;
    
    [_player runAction:[SKAction actionWithEffect:scaleEffect] withKey:@"squash"];
}

-(void)bugJelly
{
    [_bugLayer enumerateChildNodesWithName:@"bug" usingBlock:^(SKNode *node, BOOL *stop) {
        
        SKTScaleEffect * scale = [SKTScaleEffect effectWithNode:node duration:1.0 startScale:CGPointMake(1.2, 1.2) endScale:CGPointMake(1.0, 1.0)];
        scale.timingFunction = SKTTimingFunctionElasticEaseOut;
        
        [node runAction:[SKAction actionWithEffect:scale] withKey:@"scale"];
    }];
}

// TODO: Bug in this code. fix later.
- (void)crackWall:(SKSpriteNode *)wall
{
    if ((wall.physicsBody.categoryBitMask & PCWallCategory) != 0) {
        
        NSArray *textures = @[[_bgLayer textureNamed:@"wall-cracked"],
                              [_bgLayer textureNamed:@"wall"]];
        
        SKAction *animate = [SKAction animateWithTextures:textures
                                             timePerFrame:2.0];
        [wall runAction:animate withKey:@"crackAnim"];
        
        wall.physicsBody.categoryBitMask = PCCrackedWallCategory;
        [wall runAction:[SKAction skt_afterDelay:2.0 runBlock:^{
            wall.physicsBody.categoryBitMask = PCWallCategory;
        }]];
    } else if (wall.physicsBody.categoryBitMask & PCCrackedWallCategory) {
        [wall removeActionForKey:@"crackAnim"];
        wall.texture = [_bgLayer textureNamed:@"wall-broken"];
        wall.physicsBody = nil;
    }

}

- (void)bugHitEffects:(SKSpriteNode *)bug
{
    CFTimeInterval now = CACurrentMediaTime();
    if (now - _lastComboTime < 0.5f) {
        _comboCounter++;
    } else {
        _comboCounter = 0;
    }
    _lastComboTime = now;
    
    // Remove all actions so the bug stops moving.
    bug.physicsBody = nil;
    [bug removeAllActions];
    
    // Workaround for a bug in SpriteKit when running multiple actions.
    SKNode *newNode = [SKNode node];
    [_bugLayer addChild:newNode];
    newNode.position = bug.position;
    bug.position = CGPointZero;
    [bug removeFromParent];
    [newNode addChild:bug];
    
    // set const and runAction.
    const NSTimeInterval Duration = 1.3;
    [newNode runAction:
     [SKAction skt_removeFromParentAfterDelay:Duration]];
    
    // 4: Call custom bug effects.
    [self scaleBug:newNode duration:Duration];
    [self rotateBug:newNode duration:Duration];
    [self fadeBug:newNode duration:Duration];
    
    [self bounceBug:newNode duration:Duration];
    
    bug.color = SKColorWithRGB(128, 128, 128);
    bug.colorBlendFactor = 1.0f;
    
    SKNode *maskNode = [SKSpriteNode spriteNodeWithTexture:bug.texture];
    [self flashBug:newNode mask:maskNode];
    
    [_worldNode runAction:[SKAction skt_screenShakeWithNode:_worldNode amount:CGPointMake(0.0f, -12.0f) oscillations:3 duration:1.0]];
    
    [newNode runAction:KillBugSounds[MIN(11, _comboCounter)]];
    
    [self showParticlesForBug:newNode];
}

- (void)scaleBug:(SKNode *)node
        duration:(NSTimeInterval)duration
{
    const CGFloat ScaleFactor = 1.5f + _comboCounter * 0.25f;
    
    SKAction *scaleUp = [SKAction scaleTo:ScaleFactor
                                 duration:duration * 0.16667];
    scaleUp.timingMode = SKActionTimingEaseIn;
    
    SKAction *scaleDown = [SKAction scaleTo:0.0f
                                   duration:duration * 0.83335];
    scaleDown.timingMode = SKActionTimingEaseIn;
    
    [node runAction:[SKAction sequence:@[scaleUp, scaleDown]]];
}

- (void)rotateBug:(SKNode *)node
         duration:(NSTimeInterval)duration
{
    SKAction *rotateAction = [SKAction rotateByAngle:M_PI*6.0f
                                            duration:duration];
    [node runAction:rotateAction];
}

- (void)fadeBug:(SKNode *)node duration:(NSTimeInterval)duration
{
    SKAction *fadeAction =
    [SKAction fadeOutWithDuration:duration * 0.75];
    fadeAction.timingMode = SKActionTimingEaseIn;
    [node runAction:[SKAction skt_afterDelay:duration * 0.25
                                     perform:fadeAction]];
}

- (void)fireBugHitEffects
{
    SKAction *blink =
    [SKAction sequence:@[
                         [SKAction fadeOutWithDuration:0.0],
                         [SKAction waitForDuration:0.1],
                         [SKAction fadeInWithDuration:0.0],
                         [SKAction waitForDuration:0.1]]];
    
    [_player runAction:[SKAction repeatAction:blink count:4]];
    
    [_worldNode runAction:[SKAction skt_screenShakeWithNode:_worldNode amount:CGPointMake(1.05f, 1.05f) oscillations:6 duration:2.0]];
    
    [self colorGlitch];
    
    [self runAction:HitFireBugSound];
}

-(void)bounceBug:(SKNode *)node duration:(NSTimeInterval)duration
{
    CGPoint oldPosition = node.position;
    CGPoint upPosition = CGPointAdd(oldPosition, CGPointMake(0.0f, 80.0f));
    
    SKTMoveEffect *upEffect = [SKTMoveEffect effectWithNode:node duration:1.2 startPosition:oldPosition endPosition:upPosition];
    upEffect.timingFunction = ^(float t) {
        return powf(2.0f, -3.0f * t) * fabsf(sinf(t * M_PI * 3.0f));
    };
    
    SKAction *upAction = [SKAction actionWithEffect:upEffect];
    [node runAction:upAction];
}

-(void)flashBug:(SKNode *)node mask:(SKNode *)mask
{
    // 1
    SKCropNode *cropNode = [SKCropNode node];
    cropNode.maskNode = mask;
    
    // 2
    SKSpriteNode *whiteNode = [SKSpriteNode spriteNodeWithColor:SKColorWithRGB(255, 255, 255) size:CGSizeMake(50, 50)];
    
    [cropNode addChild:whiteNode];
    
    // 3
    [cropNode runAction:[SKAction sequence:@[[SKAction fadeInWithDuration:0.05],
                                             [SKAction fadeOutWithDuration:0.3]]]];
    
    [node addChild:cropNode];
}

-(void)screenShakeForSide:(Side)side power:(CGFloat)power
{
    static CGPoint offsets[] = {
        {   1.0f,   0.0f    },
        {   0.0f,   1.0f    },
        {   -1.0f,  0.0f    },
        {   0.0f,   -1.0f   },
    };
    
    CGPoint amount = offsets[side];
    amount.x *= power;
    amount.y *= power;
    
    SKAction *action = [SKAction skt_screenShakeWithNode:_worldNode amount:amount oscillations:3 duration:1.0];
    
    [_worldNode runAction:action];
}

-(void)colorGlitch
{
    // 1
    [_bgLayer enumerateChildNodesWithName:@"background" usingBlock:^(SKNode *node, BOOL *stop) {
        node.hidden = YES;
    }];
    
    [self runAction:[SKAction sequence:@[
                                         // 2
                                         [SKAction skt_colorGlitchWithScene:self
                                                              originalColor:SKColorWithRGB(89, 133, 39)
                                                                   duration:0.1],
                                         // 3
                                         [SKAction runBlock:^{
                                            [_bgLayer enumerateChildNodesWithName:@"background"
                                                                       usingBlock:^(SKNode *node, BOOL *stop) {
                                                                           node.hidden = NO;
                                                                       }];
                                            }]]]];
}

-(void)showParticlesForWall:(SKNode *)node onSide:(Side)side
{
    CGPoint position = _player.position;
    if (side == SideRight) {
        position.x = node.position.x - _bgLayer.tileSize.width / 2.0f;
    } else if (side == SideLeft) {
        position.x = node.position.x + _bgLayer.tileSize.width / 2.0f;
    } else if (side == SideTop) {
        position.y = node.position.y - _bgLayer.tileSize.height / 2.0f;
    } else {
        position.y = node.position.y + _bgLayer.tileSize.height / 2.0f;
    }
    
    SKEmitterNode *emitter = [SKEmitterNode skt_emitterNamed:@"PlayerHitWall"];
    emitter.position = position;
    
    [emitter runAction:[SKAction skt_removeFromParentAfterDelay:1.0]];
    [_bgLayer addChild:emitter];
    
    if (node.physicsBody.categoryBitMask & PCWaterCategory) {
        emitter.particleTexture = [SKTexture textureWithImageNamed:@"WaterDrop"];
    }
}

-(void)showTapAtLocation:(CGPoint)point
{
    // 1
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-3.0f, -3.0f, 6.0f, 6.0f)];
    
    // 2
    SKShapeNode *shapeNode = [SKShapeNode node];
    shapeNode.path = path.CGPath;
    shapeNode.position = point;
    shapeNode.strokeColor = SKColorWithRGB(255, 255, 196);
    shapeNode.lineWidth = 1;
    shapeNode.antialiased = NO;
    [_worldNode addChild:shapeNode];
    
    // 3
    const NSTimeInterval Duration = 0.6;
    SKAction *scaleAction = [SKAction scaleTo:6.0f duration:Duration];
    scaleAction.timingMode = SKActionTimingEaseOut;
    [shapeNode runAction:[SKAction sequence:@[scaleAction,
                                              [SKAction removeFromParent]]]];
    // 4
    SKAction *fadeAction = [SKAction fadeOutWithDuration:Duration];
    fadeAction.timingMode = SKActionTimingEaseOut;
    [shapeNode runAction:fadeAction];
}

- (void)showParticlesForBug:(SKNode *)bug
{
    SKEmitterNode *emitter = [SKEmitterNode skt_emitterNamed:@"BugSplatter"];
    emitter.position = bug.position;
    
    [emitter runAction:[SKAction skt_removeFromParentAfterDelay:0.4]];
    
    [_bgLayer addChild:emitter];
}

@end
