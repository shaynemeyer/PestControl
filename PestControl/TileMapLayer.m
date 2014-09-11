//
//  TileMapLayer.m
//  PestControl
//
//  Created by Shayne Meyer on 9/10/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "TileMapLayer.h"

@implementation TileMapLayer
{
    SKTextureAtlas *_atlas;
}

-(instancetype)initWithAtlasNamed:(NSString *)atlasName tileSize:(CGSize)tileSize grid:(NSArray *)grid
{
    if (self = [super init]) {
        _atlas = [SKTextureAtlas atlasNamed:atlasName];
        _tileSize = tileSize;
        
        _gridSize = CGSizeMake([grid.firstObject length], grid.count);
        _layerSize = CGSizeMake(_tileSize.width * _gridSize.width, _tileSize.height * _gridSize.height);
        
        for (int row = 0; row < grid.count; row++) {
            NSString *line = grid[row];
            for (int col = 0; col < line.length; col++) {
                SKSpriteNode *tile = [self nodeForCode:[line characterAtIndex:col]];
                if (tile != nil) {
                    tile.position = [self positionForRow:row col:col];
                    [self addChild:tile];
                }
            }
        }
    }
    
    return self;
}

-(SKSpriteNode *)nodeForCode:(unichar)tileCode
{
    SKSpriteNode *tile;
    
    switch (tileCode) {
        case 'o':
            tile = [SKSpriteNode spriteNodeWithTexture:[_atlas textureNamed:@"grass1"]];
            break;
        case 'x':
            tile = [SKSpriteNode spriteNodeWithTexture:[_atlas textureNamed:@"wall"]];
            break;
        case '=':
            tile = [SKSpriteNode spriteNodeWithTexture:[_atlas textureNamed:@"stone"]];
            break;
        case 'w':
            tile = [SKSpriteNode spriteNodeWithTexture:[_atlas textureNamed:@"water1"]];
            break;
        default:
            NSLog(@"Unknown tile code: %d", tileCode);
            break;
    }
    tile.blendMode = SKBlendModeReplace;
    tile.texture.filteringMode = SKTextureFilteringNearest; // makes image rendering crisp for retina.
    return tile;
}

-(CGPoint)positionForRow:(NSInteger)row col:(NSInteger)col
{
    return CGPointMake(col * self.tileSize.width + self.tileSize.width / 2,
                       self.layerSize.height - (row * self.tileSize.height + self.tileSize.height / 2));
}

@end
