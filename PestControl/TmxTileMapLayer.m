//
//  TmxTileMapLayer.m
//  PestControl
//
//  Created by Shayne Meyer on 9/19/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "TmxTileMapLayer.h"
#import "MyScene.h"

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
        [self createNodesFromLayer:layer];
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

#pragma mark
#pragma mark - create methods

-(void)createNodesFromLayer:(TMXLayer *)layer
{
    JSTileMap *map = layer.map;
    // loop through all locations in the layer
    for (int w = 0; w < self.gridSize.width; ++w) {
        for (int h = 0; h < self.gridSize.height; ++h) {
            CGPoint coord = CGPointMake(w, h);
            // Find the Global Identifier (GID) with value of zero, no tile at that location, skip ahead to the next cell.
            NSInteger tileGid = [layer.layerInfo tileGidAtCoord:coord];
            if (!tileGid) {
                continue;
            }
            // look for tiles with the wall property.
            if ([map propertiesForGid:tileGid][@"wall"]) {
                // attach a physics body to the tile.
                SKSpriteNode *tile = [layer tileAtCoord:coord];
                
                tile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:tile.size];
                tile.physicsBody.categoryBitMask = PCWallCategory;
                tile.physicsBody.dynamic = NO;
                tile.physicsBody.friction = 0;
            }
        }
    }
}

-(SKNode *)tileAtPoint:(CGPoint)point
{
    SKNode *tile = [super tileAtPoint:point];
    return tile ? tile : [_layer tileAt:point];
}

@end
