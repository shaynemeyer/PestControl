//
//  AnimateSprite.m
//  PestControl
//
//  Created by Shayne Meyer on 9/13/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

#import "AnimatingSprite.h"

@implementation AnimatingSprite

+(SKAction *)createAnimWithPrefix:(NSString *)prefix suffix:(NSString *)suffix
{
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"characters"];
    NSArray *textures = @[[atlas textureNamed:[NSString stringWithFormat:@"%@_%@1", prefix, suffix]],
                          [atlas textureNamed:[NSString stringWithFormat:@"%@_%@2", prefix, suffix]]];
    
    [textures[0] setFilteringMode:SKTextureFilteringNearest];
    [textures[1] setFilteringMode:SKTextureFilteringNearest];
    
    return [SKAction repeatActionForever:[SKAction animateWithTextures:textures timePerFrame:0.20]];
}

-(void)setFacingDirection:(PCFacingDirection)facingDirection
{
    _facingDirection = facingDirection;
    // determine the direction to face.
    switch (facingDirection) {
        case PCFacingForward:
            [self runAction:self.facingForwardAnim];
            break;
        case PCFacingBack:
            [self runAction:self.facingBackAnim];
            break;
        case PCFacingLeft:
            [self runAction:self.facingSideAnim];
            break;
        case PCFacingRight:
            [self runAction:self.facingSideAnim];
            // Set the sprites scale to negative, it renders fliped on the y-axis.
            if (self.xScale > 0.0f) {
                self.xScale = -self.xScale;
            }
            break;
    }
    
    // When the sprite is not facing right flip it back to its native orientation.
    if (facingDirection != PCFacingRight && self.xScale < 0.0f) {
        self.xScale = -self.xScale;
    }
}

#pragma mark
#pragma mark - NSCoding methods

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    // ensure super classes encode their data.
    [super encodeWithCoder:aCoder];
    //
    [aCoder encodeObject:_facingForwardAnim forKey:@"AS-ForwardAnim"];
    [aCoder encodeObject:_facingBackAnim forKey:@"AS-BackAnim"];
    [aCoder encodeObject:_facingSideAnim forKey:@"AS-SideAnim"];
    [aCoder encodeInt32:_facingDirection forKey:@"AS-FacingDirection"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    // 1
    if (self = [super initWithCoder:aDecoder]) {
        // 2
        _facingForwardAnim = [aDecoder decodeObjectForKey:@"AS-ForwardAnim"];
        _facingBackAnim = [aDecoder decodeObjectForKey:@"AS-BackAnim"];
        _facingSideAnim = [aDecoder decodeObjectForKey:@"AS-SideAnim"];
        _facingDirection = [aDecoder decodeInt32ForKey:@"AS-FacingDirection"];
    }
    return self;
}

@end
