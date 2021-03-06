//
//  Breakable.m
//  PestControl
//
//  Created by Shayne Meyer on 9/13/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "Breakable.h"
#import "MyScene.h"
#import "SKNode+SKTExtras.h"
#import "SKAction+SKTExtras.h"
#import "SKEmitterNode+SKTExtras.h"

@implementation Breakable{
    SKTexture *_broken;
    SKTexture *_flyAwayTexture;
}

-(instancetype)initWithWhole:(SKTexture *)whole broken:(SKTexture *)broken flyaway:(SKTexture *)flyaway
{
    if (self = [super initWithTexture:whole]) {
        self.name = @"background";
        _broken = broken;
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.size.width*0.8, self.size.height*0.8)];
        self.physicsBody.dynamic = NO;
        self.physicsBody.categoryBitMask = PCBreakableCategory;
        _flyAwayTexture = flyaway;
    }
    return self;
}

-(void)smashBreakable
{
    self.physicsBody = nil;
    self.texture = _broken;
    self.size = _broken.size;
    // add new node that will fly off scene.
    SKSpriteNode *topNode = [SKSpriteNode spriteNodeWithTexture:_flyAwayTexture];
    [self addChild:topNode];
    
    // create a move up and move down action.
    SKAction *upAction = [SKAction moveByX:0.0f y:30.0f duration:0.2];
    upAction.timingMode = SKActionTimingEaseOut;
    
    SKAction *downAction = [SKAction moveByX:0.0f y:-300.0f duration:0.8];
    downAction.timingMode = SKActionTimingEaseIn;
    
    // run the actions: up, down, then remove node from scene.
    [topNode runAction:[SKAction sequence:@[upAction, downAction, [SKAction removeFromParent]]]];
    
    CGFloat direction = RandomSign(); // RandomSign() returns 1 or -1. This means that the node will fly right if 1 or left if -1.
    SKAction *horzAction = [SKAction moveByX:100.0f * direction y:0.0f duration:1.0];
    [topNode runAction:horzAction];
    
    SKAction *rotateAction = [SKAction rotateByAngle:-M_PI + RandomFloat() * M_PI * 2.0f duration:1.0];
    [topNode runAction:rotateAction];
    
    topNode.xScale = topNode.yScale = 1.5f;
    
    SKAction *scaleAction = [SKAction scaleTo:0.4f duration:1.0];
    scaleAction.timingMode = SKActionTimingEaseOut;
    [topNode runAction:scaleAction];
    
    [topNode runAction:[SKAction sequence:@[[SKAction waitForDuration:0.6],
                                            [SKAction fadeOutWithDuration:0.6],
                                            [SKAction fadeOutWithDuration:0.4]]]];
    
    // smash tree
    SKEmitterNode *emitter = [SKEmitterNode skt_emitterNamed:@"TreeSmash"];
    emitter.targetNode = self.parent;
    [emitter runAction:[SKAction skt_removeFromParentAfterDelay:1.0]];
    
    [self addChild:emitter];
}

#pragma mark
#pragma mark - NSCoding methods

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_broken forKey:@"Breakable-broken"];
    [aCoder encodeObject:_flyAwayTexture forKey:@"Breakable-flyaway"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _broken = [aDecoder decodeObjectForKey:@"Breakable-broken"];
        _flyAwayTexture = [aDecoder decodeObjectForKey:@"Breakable-flyaway"];
    }
    return self;
}

@end
