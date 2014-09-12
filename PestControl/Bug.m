//
//  Bug.m
//  PestControl
//
//  Created by Shayne Meyer on 9/12/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "Bug.h"

@implementation Bug

-(instancetype)init
{
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"characters"];
    SKTexture *texture = [atlas textureNamed:@"bug_ft1"];
    texture.filteringMode = SKTextureFilteringNearest;
    
    if (self = [super initWithTexture:texture]) {
        self.name = @"bug";
    }
    
    return self;
}

@end
