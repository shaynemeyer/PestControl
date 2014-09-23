//
//  TmxTileMapLayer.m
//  PestControl
//
//  Created by Shayne Meyer on 9/19/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "TmxTileMapLayer.h"
#import "MyScene.h"
#import "Breakable.h"
#import "Player.h"
#import "Bug.h"
#import "FireBug.h"

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

-(instancetype)initWithTmxObjectGroup:(TMXObjectGroup *)group
                             tileSize:(CGSize)tileSize
                             gridSize:(CGSize)gridSize
{
    if (self = [super init]) {
        _tmxTileSize = tileSize;
        _tmxGridSize = gridSize;
        _tmxLayerSize = CGSizeMake(tileSize.width * gridSize.width,
                                   tileSize.height * gridSize.height);
        [self createNodesFromGroup:group];
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
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"tmx-bg-tiles"];
    
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
            } else if ([map propertiesForGid:tileGid][@"tree"]) {
                SKNode *tile = [[Breakable alloc] initWithWhole:[atlas textureNamed:@"tree"]
                                                         broken:[atlas textureNamed:@"tree-stump"]
                                                        flyaway:[atlas textureNamed:@"tree-top"]];
                tile.position = [self pointForCoord:coord];
                [self addChild:tile];
                [layer removeTileAtCoord:coord];
            }
        }
    }
}

-(void)createNodesFromGroup:(TMXObjectGroup *)group
{
    NSDictionary *playerObj = [group objectNamed:@"player"];
    if (playerObj) {
        Player *player = [Player node];
        player.position = CGPointMake([playerObj[@"x"] floatValue], [playerObj[@"y"] floatValue]);
        [self addChild:player];
    }
    
    NSArray *bugs = [group objectsNamed:@"bug"];
    for (NSDictionary *bugPos in bugs) {
        Bug *bug = [Bug node];
        bug.position = CGPointMake([bugPos[@"x"] floatValue], [bugPos[@"y"] floatValue]);
        [self addChild:bug];
    }

    NSArray *fireBugs = [group objectsNamed:@"firebug"];
    for (NSDictionary *bugPos in fireBugs) {
        FireBug *fireBug = [FireBug node];
        fireBug.position = CGPointMake([bugPos[@"x"] floatValue],
                                       [bugPos[@"y"] floatValue]);
        [self addChild:fireBug];
    }
}

-(SKNode *)tileAtPoint:(CGPoint)point
{
    SKNode *tile = [super tileAtPoint:point];
    return tile ? tile : [_layer tileAt:point];
}

#pragma mark
#pragma mark - NSCoding methods

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_layer forKey:@"TmxTML-Layer"];
    [aCoder encodeCGSize:_tmxTileSize forKey:@"TmxTML-TileSize"];
    [aCoder encodeCGSize:_tmxGridSize forKey:@"TmxTML-GridSize"];
    [aCoder encodeCGSize:_tmxLayerSize forKey:@"TmxTML-LayerSize"];
    
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _layer = [aDecoder decodeObjectForKey:@"TmxTML-Layer"];
        _tmxTileSize = [aDecoder decodeCGSizeForKey:@"TmxTML-TileSize"];
        _tmxGridSize = [aDecoder decodeCGSizeForKey:@"TmxTML-GridSize"];
        _tmxLayerSize = [aDecoder decodeCGSizeForKey:@"TmxTML-LayerSize"];
    }
    
    return self;
}

@end
