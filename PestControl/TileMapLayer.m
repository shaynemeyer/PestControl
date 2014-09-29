//
//  TileMapLayer.m
//  PestControl
//
//  Created by Shayne Meyer on 9/10/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "TileMapLayer.h"
#import "Bug.h"
#import "Player.h"
#import "MyScene.h"
#import "Breakable.h"
#import "FireBug.h"

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
            tile = [SKSpriteNode spriteNodeWithTexture:
                    [_atlas textureNamed:
                     RandomFloat() < 0.1 ? @"grass2" : @"grass1"]];
            tile.name = @"background";
            break;
        case 'x':
            tile = [SKSpriteNode spriteNodeWithTexture:[_atlas textureNamed:@"wall"]];
            tile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:tile.size];
            tile.physicsBody.categoryBitMask = PCWallCategory;
            tile.physicsBody.dynamic = NO;
            tile.physicsBody.friction = 0;
            break;
        case '=':
            tile = [SKSpriteNode spriteNodeWithTexture:[_atlas textureNamed:@"stone"]];
            tile.name = @"background";
            break;
        case 'w':
            tile = [SKSpriteNode spriteNodeWithTexture:
                    [_atlas textureNamed:
                     RandomFloat() < 0.1 ? @"water2" : @"water1"]];
            tile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:tile.size];
            tile.physicsBody.categoryBitMask = PCWaterCategory;
            tile.physicsBody.dynamic = NO;
            tile.physicsBody.friction = 0;
            break;
        case '.':
            return nil;
            break;
        case 'b':
            return [Bug node]; // Use SpriteKit default blend mode which support transparency.
            break;
        case 'p':
            return [Player node];
            break;
        case 't':
            return [[Breakable alloc] initWithWhole:[_atlas textureNamed:@"tree"]
                                             broken:[_atlas textureNamed:@"tree-stump"]
                                            flyaway:[_atlas textureNamed:@"tree-top"]];
        case 'f':
            return [FireBug node];
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

#pragma mark 
#pragma mark - Move methods

// checks tile coordinates against the layer's grid to ensure they are within the range possible.
-(BOOL)isValidTileCoord:(CGPoint)coord
{
    return (coord.x >= 0 &&
            coord.y >= 0 &&
            coord.x < self.gridSize.width &&
            coord.y < self.gridSize.height);
}

// returns the grid coordinates for the give (x,y) position in the layer.
-(CGPoint)coordForPoint:(CGPoint)point
{
    return CGPointMake((int)(point.x / self.tileSize.width),
                       (int)((point.y - self.tileSize.height) / -self.tileSize.height));
}

// returns the (x,y) position at the center of the given grid coordinates.
-(CGPoint)pointForCoord:(CGPoint)coord
{
    return [self positionForRow:coord.y col:coord.x];
}

#pragma mark
#pragma mark - TileAt Methods

-(SKNode *)tileAtCoord:(CGPoint)coord
{
    return [self tileAtPoint:[self pointForCoord:coord]];
}

-(SKNode *)tileAtPoint:(CGPoint)point
{
    SKNode *n = [self nodeAtPoint:point];
    while (n && n != self && n.parent != self) {
        n = n.parent;
    }
    return n.parent == self ? n : nil;
}


#pragma mark
#pragma mark - NSCoding methods

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_atlas forKey:@"TML-Atlas"];
    [aCoder encodeCGSize:_gridSize forKey:@"TML-GridSize"];
    [aCoder encodeCGSize:_tileSize forKey:@"TML-TileSize"];
    [aCoder encodeCGSize:_layerSize forKey:@"TML-LayerSize"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _atlas = [aDecoder decodeObjectForKey:@"TML-Atlas"];
        _gridSize = [aDecoder decodeCGSizeForKey:@"TML-GridSize"];
        _tileSize = [aDecoder decodeCGSizeForKey:@"TML-TileSize"];
        _layerSize = [aDecoder decodeCGSizeForKey:@"TML-LayerSize"];
    }
    return self;
}

- (SKTexture *)textureNamed:(NSString *)name
{
    return [_atlas textureNamed:name];
}

@end
