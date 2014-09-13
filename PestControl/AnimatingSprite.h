//
//  AnimateSprite.h
//  PestControl
//
//  Created by Shayne Meyer on 9/13/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_ENUM(int32_t, PCFacingDirection)
{
    PCFacingForward,
    PCFacingBack,
    PCFacingRight,
    PCFacingLeft
};
@interface AnimatingSprite : SKSpriteNode

@property (strong, nonatomic) SKAction *facingForwardAnim;
@property (strong, nonatomic) SKAction *facingBackAnim;
@property (strong, nonatomic) SKAction *facingSideAnim;
@property (assign, nonatomic) PCFacingDirection facingDirection;

+(SKAction *)createAnimWithPrefix:(NSString *)prefix suffix:(NSString *)suffix;

@end
