//
//  MyScene.h
//  PestControl
//

//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_OPTIONS(uint32_t, PCPhysicsCategory)
{
    PCBoundaryCategory  = 1 << 0,
    PCPlayerCategory    = 1 << 1,
    PCBugCategory       = 1 << 2,
    PCWallCategory      = 1 << 3,
    PCWaterCategory     = 1 << 4,
    PCBreakableCategory = 1 << 5,
};

@interface MyScene : SKScene

-(BOOL)tileAtPoint:(CGPoint)point hasAnyProps:(uint32_t)props;
-(BOOL)tileAtCoord:(CGPoint)coord hasAnyProps:(uint32_t)props;

@end
