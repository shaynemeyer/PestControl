//
//  Breakable.h
//  PestControl
//
//  Created by Shayne Meyer on 9/13/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Breakable : SKSpriteNode

-(instancetype)initWithWhole:(SKTexture *)whole broken:(SKTexture *)broken;
-(void)smashBreakable;

@end
