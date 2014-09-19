//
//  TmxTileMapLayer.h
//  PestControl
//
//  Created by Shayne Meyer on 9/19/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "TileMapLayer.h"
#import "JSTileMap.h"

@interface TmxTileMapLayer : TileMapLayer

-(instancetype)initWithTmxLayer:(TMXLayer *)layer;

@end
