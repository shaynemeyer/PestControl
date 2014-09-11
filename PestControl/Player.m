//
//  Player.m
//  PestControl
//
//  Created by Shayne Meyer on 9/11/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "Player.h"

@implementation Player

-(instancetype)init
{
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"characters"];
    SKTexture *texture = [atlas textureNamed:@"player_ft1"];
    texture.filteringMode = SKTextureFilteringNearest;
    
    if (self = [super initWithTexture:texture]) {
        self.name = @"player";
        // more setup later.
    }
    
    return self;
}


@end
