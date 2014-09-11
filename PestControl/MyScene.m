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

@implementation MyScene
{
    SKNode *_worldNode;
    TileMapLayer *_bgLayer;
    Player *_player;
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
    [self centerViewOn:[touch locationInNode:_worldNode]];

}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

-(void)centerViewOn:(CGPoint)centerOn
{
    CGSize size = self.size;
    CGFloat x = Clamp(centerOn.x, size.width / 2, _bgLayer.layerSize.width - size.width / 2);
    CGFloat y = Clamp(centerOn.y, size.height / 2, _bgLayer.layerSize.height - size.height / 2);
    _worldNode.position = CGPointMake(-x, -y);
}


#pragma mark
#pragma mark - Create Scene Methods

-(TileMapLayer *)createScenery
{
    return [TileMapLayerLoader tileMapLayerFromFileNamed:@"level-1-bg.txt"];
}

-(void)createWorld
{
    _bgLayer = [self createScenery];
    _worldNode = [SKNode node];
    [_worldNode addChild:_bgLayer];
    [self addChild:_worldNode];
    
    self.anchorPoint = CGPointMake(0.5, 0.5);
    _worldNode.position = CGPointMake(-_bgLayer.layerSize.width / 2, -_bgLayer.layerSize.height / 2);
}

-(void)createCharacters
{
    _player = [Player node];
    _player.position = CGPointMake(300, 300);
    [_worldNode addChild:_player];
}

@end
