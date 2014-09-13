//
//  AnimateSprite.h
//  PestControl
//
//  Created by Shayne Meyer on 9/13/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface AnimatingSprite : SKSpriteNode

@property (strong, nonatomic) SKAction *facingForwardAnim;
@property (strong, nonatomic) SKAction *facingBackAnim;
@property (strong, nonatomic) SKAction *facingSideAnim;

+(SKAction *)createAnimWithPrefix:(NSString *)prefix suffix:(NSString *)suffix;

@end
