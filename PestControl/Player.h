//
//  Player.h
//  PestControl
//
//  Created by Shayne Meyer on 9/11/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "AnimatingSprite.h"

@interface Player : SKNode

-(void)moveToward:(CGPoint)targetPosition;
-(void)faceCurrentDirection;
-(void)start;

@end
