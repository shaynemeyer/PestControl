//
//  TmxTileMapLayer.m
//  PestControl
//
//  Created by Shayne Meyer on 9/19/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "TmxTileMapLayer.h"

@implementation TmxTileMapLayer{
    TMXLayer *_layer;
    CGSize _tmxTileSize;
    CGSize _tmxGridSize;
    CGSize _tmxLayerSize;
}

-(instancetype)initWithTmxLayer:(TMXLayer *)layer
{
    if (self = [super init]) {
        _layer = layer;
        _tmxTileSize = layer.mapTileSize;
        _tmxGridSize = layer.layerInfo.layerGridSize;
        _tmxLayerSize = CGSizeMake(layer.layerWidth, layer.layerHeight);
    }
    
    return self;
}

#pragma mark
#pragma mark - Getters

-(CGSize)gridSize
{
    return _tmxGridSize;
}

-(CGSize)tileSize
{
    return _tmxTileSize;
}

-(CGSize)layerSize
{
    return _tmxLayerSize;
}

@end
