#import "platform.h"
#import "Sprite.h"
#import <backends/common/scene_graph.h>

@interface CNNRScene : NSObject

-(instancetype)initWithSize:(vec2)size;

-(bool)drawToTarget:(render_target *)rt
             device:(device *)dev
             camera:(camera *)cam
           viewport:(const viewport *)vp;

-(sprite_handle)newSpriteWithParams:(const sprite_params *)params;
-(void)destroySprite:(sprite_handle)sprite;

-(void)getSpriteUv:(sprite_handle)sprite
         topLeftUv:(vec2 *)topLeft
     bottomRightUv:(vec2 *)bottomRight;
-(float)getSpriteLayer:(sprite_handle)sprite;
-(texture *)getSpriteTexture:(sprite_handle)sprite;
-(matrix2d)getSpriteTransform:(sprite_handle)sprite;
-(color)getSpriteTint:(sprite_handle)sprite;

-(void)updateSprite:(sprite_handle)sprite
          topLeftUV:(vec2)topLeft
      bottomRightUV:(vec2)bottomRight;
-(void)updateSprite:(sprite_handle)sprite
              layer:(float)layer;
-(void)updateSprite:(sprite_handle)sprite
            texture:(texture *)texture;
-(void)updateSprite:(sprite_handle)sprite
          transform:(matrix2d)transform;
-(void)updateSprite:(sprite_handle)sprite
               tint:(color)tint;

@end
