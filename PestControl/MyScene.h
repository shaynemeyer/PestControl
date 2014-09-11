//
//  MyScene.h
//  PestControl
//

//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef NS_OPTIONS(uint32_t, PCPhysicsCategory)
{
    PCBoundaryCategory = 1 << 0,
};

@interface MyScene : SKScene

@end
