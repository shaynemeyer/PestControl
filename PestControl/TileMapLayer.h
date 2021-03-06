//
//  TileMapLayer.h
//  PestControl
//
//  Created by Shayne Meyer on 9/10/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface TileMapLayer : SKNode

@property (readonly, nonatomic) CGSize gridSize;
@property (readonly, nonatomic) CGSize layerSize;
@property (readonly, nonatomic) CGSize tileSize;

-(instancetype)initWithAtlasNamed:(NSString *)atlasName tileSize:(CGSize)tileSize grid:(NSArray *)grid;
-(BOOL)isValidTileCoord:(CGPoint)coord;
-(CGPoint)pointForCoord:(CGPoint)coord;
-(CGPoint)coordForPoint:(CGPoint)point;

-(SKNode *)tileAtCoord:(CGPoint)coord;
-(SKNode *)tileAtPoint:(CGPoint)point;
- (SKTexture *)textureNamed:(NSString *)name;

@end
