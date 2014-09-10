//
//  MyScene.m
//  PestControl
//
//  Created by Shayne Meyer on 9/10/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "MyScene.h"
#import "TileMapLayer.h"

@implementation MyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        [self addChild:[self createScenery]];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */

}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}


#pragma mark
#pragma mark - Create Scene Methods

-(TileMapLayer *)createScenery
{
    return [[TileMapLayer alloc] initWithAtlasNamed:@"scenery"
                                           tileSize:CGSizeMake(32, 32)
                                               grid:@[@"xxxxxxxxxxxxxxx",
                                                      @"xooooooooooooox",
                                                      @"xooooooooooooox",
                                                      @"xooooooooooooox",
                                                      @"xooooooooooooox",
                                                      @"xoooooooxooooox",
                                                      @"xoooooooxooooox",
                                                      @"xoooooooxxxxoox",
                                                      @"xoooooooxooooox",
                                                      @"xxxxxxxxxxxxxxx"]];
}

@end
